from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

ratings_bp = Blueprint('ratings', __name__)


@ratings_bp.route('/submit', methods=['POST'])
@jwt_required()
def submit_rating():
    """Shop owner submits a 1-5 star rating for a delivered order.
    Also updates the stockholder's running average."""
    user_id = get_jwt_identity()
    data = request.get_json()

    order_id = data.get('order_id')
    score = data.get('score')
    review = data.get('review') or None

    if not order_id or score is None:
        return jsonify({'error': 'order_id and score are required'}), 400
    try:
        score = int(score)
        if not 1 <= score <= 5:
            raise ValueError
    except (TypeError, ValueError):
        return jsonify({'error': 'Score must be an integer between 1 and 5'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Verify the order belongs to this shop owner and is delivered
        cursor.execute(
            'SELECT shop_owner_id, stockholder_id, status FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'delivered':
            return jsonify({'error': 'Can only rate delivered orders'}), 400

        # Prevent duplicate rating
        cursor.execute(
            'SELECT rating_id FROM ratings WHERE order_id=%s AND given_by=%s',
            (order_id, user_id))
        if cursor.fetchone():
            return jsonify({'error': 'You already rated this order'}), 409

        stockholder_id = o['stockholder_id']
        cursor.execute(
            '''INSERT INTO ratings (order_id, given_by, given_to, score, review)
               VALUES (%s, %s, %s, %s, %s)''',
            (order_id, user_id, stockholder_id, score, review))

        # Recalculate stockholder's average rating
        cursor.execute(
            'SELECT AVG(score) AS avg FROM ratings WHERE given_to=%s',
            (stockholder_id,))
        new_avg = cursor.fetchone()['avg']
        cursor.execute(
            'UPDATE stockholder_profile SET rating_avg=%s WHERE user_id=%s',
            (round(float(new_avg), 2), stockholder_id))

        # Notify the stockholder
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'rating_received', %s, %s)''',
            (stockholder_id,
             f'You received a {score}-star rating for order #{order_id}.',
             order_id))

        db.commit()
        return jsonify({
            'message': 'Rating submitted',
            'new_avg': round(float(new_avg), 2),
        }), 201
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@ratings_bp.route('/unrated', methods=['GET'])
@jwt_required()
def unrated_orders():
    """Returns delivered orders for the shop owner that have no rating yet."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            '''SELECT o.order_id, o.quantity, o.unit, o.price_per_unit, o.total_price,
                      o.delivered_at, p.name AS product_name, v.variant_name,
                      sp.company_name AS stockholder_name
               FROM orders o
               JOIN demands d ON o.demand_id = d.demand_id
               JOIN products p ON d.product_id = p.product_id
               JOIN product_variants v ON d.variant_id = v.variant_id
               JOIN stockholder_profile sp ON o.stockholder_id = sp.user_id
               WHERE o.shop_owner_id = %s
                 AND o.status = 'delivered'
                 AND NOT EXISTS (
                   SELECT 1 FROM ratings r
                   WHERE r.order_id = o.order_id AND r.given_by = o.shop_owner_id
                 )
               ORDER BY o.delivered_at DESC''',
            (user_id,))
        rows = cursor.fetchall()
        for row in rows:
            for k in ('total_price', 'price_per_unit', 'quantity'):
                if row.get(k) is not None:
                    row[k] = float(row[k])
            if row.get('delivered_at'):
                row['delivered_at'] = row['delivered_at'].isoformat()
        return jsonify({'orders': rows}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@ratings_bp.route('/my', methods=['GET'])
@jwt_required()
def my_ratings():
    """Returns ratings received by the logged-in stockholder."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            '''SELECT r.rating_id, r.score, r.review, r.created_at,
                      u.name AS given_by_name,
                      COALESCE(sp.shop_name, '') AS shop_name
               FROM ratings r
               JOIN users u ON r.given_by = u.user_id
               LEFT JOIN shop_owner_profile sp ON r.given_by = sp.user_id
               WHERE r.given_to = %s
               ORDER BY r.created_at DESC''',
            (user_id,))
        rows = cursor.fetchall()
        for row in rows:
            if row.get('created_at'):
                row['created_at'] = row['created_at'].isoformat()
        return jsonify({'ratings': rows}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
