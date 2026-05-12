from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

admin_bp = Blueprint('admin', __name__)


def _require_admin(cursor, user_id):
    cursor.execute('SELECT role FROM users WHERE user_id=%s', (user_id,))
    u = cursor.fetchone()
    if not u or u['role'] != 'admin':
        return False
    return True


@admin_bp.route('/users', methods=['GET'])
@jwt_required()
def list_users():
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        if not _require_admin(cursor, user_id):
            return jsonify({'error': 'Admin access required'}), 403

        cursor.execute('''
            SELECT u.user_id, u.name, u.email, u.phone, u.role, u.created_at,
                   COALESCE(sop.shop_name, sp.company_name, '') AS profile_name,
                   COALESCE(sop.is_verified, sp.is_verified, FALSE) AS is_verified
            FROM users u
            LEFT JOIN shop_owner_profile  sop ON u.user_id = sop.user_id AND u.role = 'shop_owner'
            LEFT JOIN stockholder_profile sp  ON u.user_id = sp.user_id  AND u.role = 'stockholder'
            ORDER BY u.created_at DESC
        ''')
        rows = cursor.fetchall()
        for r in rows:
            if r.get('created_at'):
                r['created_at'] = r['created_at'].isoformat()
            r['is_verified'] = bool(r['is_verified'])
            r['profile'] = {'shop_name': r['profile_name'], 'company_name': r['profile_name']}

        return jsonify({'users': rows}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@admin_bp.route('/users/<int:target_id>/toggle-verify', methods=['PUT'])
@jwt_required()
def toggle_verify(target_id):
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        if not _require_admin(cursor, user_id):
            return jsonify({'error': 'Admin access required'}), 403

        cursor.execute('SELECT role FROM users WHERE user_id=%s', (target_id,))
        u = cursor.fetchone()
        if not u:
            return jsonify({'error': 'User not found'}), 404

        if u['role'] == 'shop_owner':
            cursor.execute(
                'UPDATE shop_owner_profile SET is_verified = NOT is_verified WHERE user_id=%s',
                (target_id,))
        elif u['role'] == 'stockholder':
            cursor.execute(
                'UPDATE stockholder_profile SET is_verified = NOT is_verified WHERE user_id=%s',
                (target_id,))
        else:
            return jsonify({'error': 'Cannot change admin verification'}), 400

        db.commit()
        return jsonify({'message': 'Verification toggled'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@admin_bp.route('/orders', methods=['GET'])
@jwt_required()
def all_orders():
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        if not _require_admin(cursor, user_id):
            return jsonify({'error': 'Admin access required'}), 403

        cursor.execute('''
            SELECT o.order_id, o.quantity, o.unit, o.price_per_unit, o.total_price,
                   o.status, o.created_at, o.delivered_at,
                   p.name AS product_name, v.variant_name,
                   sp.company_name AS stockholder_name,
                   sop.shop_name
            FROM orders o
            JOIN demands d          ON o.demand_id    = d.demand_id
            JOIN products p         ON d.product_id   = p.product_id
            JOIN product_variants v ON d.variant_id   = v.variant_id
            JOIN stockholder_profile sp  ON o.stockholder_id = sp.user_id
            JOIN shop_owner_profile  sop ON o.shop_owner_id  = sop.user_id
            ORDER BY o.created_at DESC
            LIMIT 200
        ''')
        rows = cursor.fetchall()
        for r in rows:
            for k in ('total_price', 'price_per_unit', 'quantity'):
                if r.get(k) is not None:
                    r[k] = float(r[k])
            for ts in ('created_at', 'delivered_at'):
                if r.get(ts):
                    r[ts] = r[ts].isoformat()
        return jsonify({'orders': rows}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
