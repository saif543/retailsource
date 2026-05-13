from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

notifications_bp = Blueprint('notifications', __name__)


@notifications_bp.route('', methods=['GET'])
@jwt_required()
def get_notifications():
    """Return all notifications for the logged-in user, newest first."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT notif_id, type, message, is_read, related_order_id, created_at
            FROM notifications
            WHERE user_id = %s
            ORDER BY created_at DESC
            LIMIT 100
        ''', (user_id,))
        notifs = cursor.fetchall()
        for n in notifs:
            if n.get('created_at'):
                n['created_at'] = n['created_at'].isoformat()

        unread = sum(1 for n in notifs if not n['is_read'])
        return jsonify({'notifications': notifs, 'unread_count': unread}), 200
    finally:
        cursor.close()
        db.close()


@notifications_bp.route('/mark-read', methods=['PUT'])
@jwt_required()
def mark_read():
    """Mark notifications as read.
    Body: { "notif_ids": [1,2,3] }  or omit to mark ALL as read."""
    user_id = get_jwt_identity()
    data = request.get_json() or {}
    notif_ids = data.get('notif_ids')

    db = get_db()
    cursor = db.cursor()
    try:
        if notif_ids:
            fmt = ','.join(['%s'] * len(notif_ids))
            cursor.execute(
                f'UPDATE notifications SET is_read=TRUE WHERE user_id=%s AND notif_id IN ({fmt})',
                [user_id] + list(notif_ids))
        else:
            cursor.execute(
                'UPDATE notifications SET is_read=TRUE WHERE user_id=%s', (user_id,))
        db.commit()
        return jsonify({'message': 'Notifications marked as read'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
