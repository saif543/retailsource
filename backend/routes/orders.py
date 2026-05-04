import random
import datetime
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

orders_bp = Blueprint('orders', __name__)


def _serialize_order(o):
    """Convert Decimal/datetime fields in an order dict to JSON-safe types."""
    for ts in ('created_at', 'accepted_at', 'delivered_at'):
        if o.get(ts):
            o[ts] = o[ts].isoformat()
    for k in ('quantity', 'price_per_unit', 'total_price',
              'delivery_lat', 'delivery_lng'):
        if o.get(k) is not None:
            o[k] = float(o[k])
    return o


@orders_bp.route('/place', methods=['POST'])
@jwt_required()
def place_order():
    """Shop owner places an order against a stock item.
    Uses transaction with FOR UPDATE lock to prevent race conditions."""
    user_id = get_jwt_identity()
    data = request.get_json()

    demand_id = data.get('demand_id')
    stock_id = data.get('stock_id')
    quantity = data.get('quantity')
    delivery_address = data.get('delivery_address')
    delivery_lat = data.get('delivery_lat')
    delivery_lng = data.get('delivery_lng')

    if not all([demand_id, stock_id, quantity, delivery_address]):
        return jsonify({'error': 'demand_id, stock_id, quantity, delivery_address required'}), 400

    try:
        quantity = float(quantity)
        if quantity <= 0:
            return jsonify({'error': 'Quantity must be > 0'}), 400
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid quantity'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Verify demand belongs to user
        cursor.execute(
            'SELECT shop_owner_id, status FROM demands WHERE demand_id = %s',
            (demand_id,)
        )
        d = cursor.fetchone()
        if not d:
            return jsonify({'error': 'Demand not found'}), 404
        if str(d['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your demand'}), 403

        # Lock stock row
        cursor.execute(
            '''SELECT stock_id, stockholder_id, quantity_available, unit, price_per_unit
               FROM stock WHERE stock_id = %s FOR UPDATE''',
            (stock_id,)
        )
        s = cursor.fetchone()
        if not s:
            db.rollback()
            return jsonify({'error': 'Stock not found'}), 404
        if float(s['quantity_available']) < quantity:
            db.rollback()
            return jsonify({'error': 'Not enough stock available'}), 400

        new_qty = float(s['quantity_available']) - quantity
        new_status = 'sold_out' if new_qty == 0 else 'available'
        total_price = quantity * float(s['price_per_unit'])

        cursor.execute(
            '''UPDATE stock SET quantity_available = %s, status = %s
               WHERE stock_id = %s''',
            (new_qty, new_status, stock_id)
        )

        cursor.execute(
            '''INSERT INTO orders
               (demand_id, stock_id, shop_owner_id, stockholder_id,
                quantity, unit, price_per_unit, total_price,
                delivery_address, delivery_lat, delivery_lng, status)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'pending')''',
            (demand_id, stock_id, user_id, s['stockholder_id'],
             quantity, s['unit'], s['price_per_unit'], total_price,
             delivery_address, delivery_lat, delivery_lng)
        )
        order_id = cursor.lastrowid

        # Mark demand as matched
        cursor.execute(
            "UPDATE demands SET status = 'matched' WHERE demand_id = %s",
            (demand_id,)
        )

        # Notify stockholder of new order
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'new_order', %s, %s)''',
            (s['stockholder_id'],
             f'New order #{order_id} placed for your stock. Review and accept.',
             order_id))

        db.commit()
        return jsonify({
            'message': 'Order placed successfully',
            'order_id': order_id,
            'total_price': total_price,
        }), 201
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@orders_bp.route('/my', methods=['GET'])
@jwt_required()
def my_orders():
    """List the shop owner's orders."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT o.order_id, o.quantity, o.unit, o.price_per_unit, o.total_price,
                   o.status, o.created_at, o.delivery_address,
                   p.name AS product_name, v.variant_name,
                   sp.company_name AS stockholder_name,
                   EXISTS (
                     SELECT 1 FROM ratings r
                     WHERE r.order_id = o.order_id AND r.given_by = o.shop_owner_id
                   ) AS has_rating
            FROM orders o
            JOIN demands d ON o.demand_id = d.demand_id
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN stockholder_profile sp ON o.stockholder_id = sp.user_id
            WHERE o.shop_owner_id = %s
            ORDER BY o.created_at DESC
        ''', (user_id,))
        orders = cursor.fetchall()
        for o in orders:
            _serialize_order(o)
            o['has_rating'] = bool(o.get('has_rating'))
        return jsonify({'orders': orders}), 200
    finally:
        cursor.close()
        db.close()


# ── Shop owner: single order status ──────────────────────────────────────────

@orders_bp.route('/<int:order_id>/status', methods=['GET'])
@jwt_required()
def order_status(order_id):
    """Get full status of one order (accessible by both roles).
    Shop owner sees OTP when out_for_delivery.
    Stockholder: delivery address/phone hidden while pending."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT o.order_id, o.quantity, o.unit, o.price_per_unit, o.total_price,
                   o.status, o.delivery_address, o.delivery_lat, o.delivery_lng,
                   o.created_at, o.accepted_at, o.delivered_at,
                   o.shop_owner_id, o.stockholder_id, o.demand_id,
                   p.name AS product_name, v.variant_name,
                   sp.company_name AS stockholder_name,
                   u.name AS shop_owner_name, u.phone AS shop_owner_phone,
                   sop.shop_name, sop.area AS shop_area
            FROM orders o
            JOIN demands d ON o.demand_id = d.demand_id
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN stockholder_profile sp ON o.stockholder_id = sp.user_id
            JOIN users u ON o.shop_owner_id = u.user_id
            JOIN shop_owner_profile sop ON o.shop_owner_id = sop.user_id
            WHERE o.order_id = %s
        ''', (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['shop_owner_id']) != str(user_id) and str(o['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403

        is_stockholder = str(o['stockholder_id']) == str(user_id)

        # Location privacy: hide buyer info for stockholder while pending
        if is_stockholder and o['status'] == 'pending':
            o['delivery_address'] = None
            o['delivery_lat'] = None
            o['delivery_lng'] = None
            o['shop_owner_phone'] = None
            o['location_note'] = 'Location revealed after acceptance'

        _serialize_order(o)

        # Include OTP for shop owner when order is out for delivery
        if o['status'] == 'out_for_delivery' and not is_stockholder:
            cursor.execute(
                'SELECT code FROM otp_codes WHERE order_id=%s AND is_verified=FALSE ORDER BY created_at DESC LIMIT 1',
                (order_id,))
            otp_row = cursor.fetchone()
            o['otp'] = otp_row['code'] if otp_row else None

        return jsonify({'order': o}), 200
    finally:
        cursor.close()
        db.close()


# ── Shop owner: confirm delivery with OTP ────────────────────────────────────

@orders_bp.route('/<int:order_id>/confirm-otp', methods=['POST'])
@jwt_required()
def confirm_otp(order_id):
    """Shop owner-side: not used in standard flow (stockholder verifies).
    Kept as alias that delegates to verify-otp logic."""
    return verify_otp(order_id)


# ── Stockholder: incoming orders (location privacy enforced) ─────────────────

@orders_bp.route('/incoming', methods=['GET'])
@jwt_required()
def incoming_orders():
    """Incoming orders for the logged-in stockholder.
    Delivery address is hidden while status = pending."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT o.order_id, o.quantity, o.unit, o.price_per_unit, o.total_price,
                   o.status, o.delivery_address, o.delivery_lat, o.delivery_lng,
                   o.created_at, o.accepted_at,
                   p.name AS product_name, v.variant_name,
                   u.name AS shop_owner_name, u.phone AS shop_owner_phone,
                   sop.shop_name, sop.area AS shop_area
            FROM orders o
            JOIN demands d ON o.demand_id = d.demand_id
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN users u ON o.shop_owner_id = u.user_id
            JOIN shop_owner_profile sop ON o.shop_owner_id = sop.user_id
            WHERE o.stockholder_id = %s
            ORDER BY o.created_at DESC
        ''', (user_id,))
        orders = cursor.fetchall()
        for o in orders:
            # Location privacy rule — hide buyer info while pending
            if o['status'] == 'pending':
                o['delivery_address'] = None
                o['delivery_lat'] = None
                o['delivery_lng'] = None
                o['shop_owner_phone'] = None
                o['location_note'] = 'Location revealed after acceptance'
            _serialize_order(o)
        return jsonify({'orders': orders}), 200
    finally:
        cursor.close()
        db.close()


# ── Stockholder: accept order ─────────────────────────────────────────────────

@orders_bp.route('/<int:order_id>/accept', methods=['POST'])
@jwt_required()
def accept_order(order_id):
    """Stockholder accepts a pending order."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id, status, shop_owner_id FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'pending':
            return jsonify({'error': f'Cannot accept order with status: {o["status"]}'}), 400

        cursor.execute(
            "UPDATE orders SET status='accepted', accepted_at=NOW() WHERE order_id=%s",
            (order_id,))

        # Notify shop owner
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'order_accepted', %s, %s)''',
            (o['shop_owner_id'], f'Your order #{order_id} has been accepted! Delivery in progress.', order_id))

        db.commit()
        return jsonify({'message': 'Order accepted', 'order_id': order_id}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


# ── Stockholder: decline order ────────────────────────────────────────────────

@orders_bp.route('/<int:order_id>/decline', methods=['POST'])
@jwt_required()
def decline_order(order_id):
    """Stockholder declines a pending order. Restores stock quantity."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id, status, shop_owner_id, stock_id, quantity FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'pending':
            return jsonify({'error': f'Cannot decline order with status: {o["status"]}'}), 400

        cursor.execute(
            "UPDATE orders SET status='declined' WHERE order_id=%s", (order_id,))

        # Restore stock quantity
        cursor.execute(
            '''UPDATE stock
               SET quantity_available = quantity_available + %s,
                   status = 'available'
               WHERE stock_id = %s''',
            (float(o['quantity']), o['stock_id']))

        # Notify shop owner
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'order_declined', %s, %s)''',
            (o['shop_owner_id'], f'Order #{order_id} was declined. You can find another supplier.', order_id))

        db.commit()
        return jsonify({'message': 'Order declined', 'order_id': order_id}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


# ── Stockholder: mark as out for delivery + generate OTP ─────────────────────

@orders_bp.route('/<int:order_id>/mark-delivered', methods=['POST'])
@jwt_required()
def mark_delivered(order_id):
    """Stockholder marks order as out_for_delivery.
    OTP is generated separately by the shop owner via /generate-otp."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id, status, shop_owner_id FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'accepted':
            return jsonify({'error': f'Order must be accepted before dispatching (current: {o["status"]})'}), 400

        cursor.execute(
            "UPDATE orders SET status='out_for_delivery' WHERE order_id=%s",
            (order_id,))

        # Notify shop owner that delivery is on the way
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'otp_sent', %s, %s)''',
            (o['shop_owner_id'],
             f'Your order #{order_id} is out for delivery! Open the order to generate your OTP.',
             order_id))

        db.commit()
        return jsonify({'message': 'Order marked as out for delivery'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@orders_bp.route('/<int:order_id>/generate-otp', methods=['POST'])
@jwt_required()
def generate_otp(order_id):
    """Shop owner generates a 6-digit OTP to hand to the delivery person.
    Invalidates any previous unverified OTP for this order."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT shop_owner_id, status FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'out_for_delivery':
            return jsonify({'error': 'Order must be out for delivery to generate OTP'}), 400

        # Invalidate any existing unused OTPs
        cursor.execute(
            'UPDATE otp_codes SET is_verified=TRUE WHERE order_id=%s AND is_verified=FALSE',
            (order_id,))

        otp_code = str(random.randint(100000, 999999))
        expires_at = datetime.datetime.now() + datetime.timedelta(minutes=10)
        cursor.execute(
            'INSERT INTO otp_codes (order_id, code, expires_at) VALUES (%s, %s, %s)',
            (order_id, otp_code, expires_at))

        db.commit()
        return jsonify({'otp': otp_code, 'expires_in_minutes': 10}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


# ── Stockholder: verify OTP to confirm delivery ───────────────────────────────

@orders_bp.route('/<int:order_id>/verify-otp', methods=['POST'])
@jwt_required()
def verify_otp(order_id):
    """Delivery man enters the OTP given by shop owner.
    Verifies against otp_codes table (6 digits, 10 min expiry)."""
    user_id = get_jwt_identity()
    data = request.get_json()
    code = data.get('otp') or data.get('code')

    if not code or len(str(code)) != 6:
        return jsonify({'error': 'Enter the 6-digit OTP'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id, status, shop_owner_id, demand_id FROM orders WHERE order_id=%s',
            (order_id,))
        o = cursor.fetchone()
        if not o:
            return jsonify({'error': 'Order not found'}), 404
        if str(o['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your order'}), 403
        if o['status'] != 'out_for_delivery':
            return jsonify({'error': 'Order is not out for delivery'}), 400

        cursor.execute(
            '''SELECT otp_id FROM otp_codes
               WHERE order_id=%s AND code=%s
                 AND is_verified=FALSE AND expires_at > NOW()''',
            (order_id, str(code)))
        otp_row = cursor.fetchone()
        if not otp_row:
            return jsonify({'error': 'Invalid or expired OTP'}), 400

        cursor.execute(
            'UPDATE otp_codes SET is_verified=TRUE WHERE otp_id=%s',
            (otp_row['otp_id'],))
        cursor.execute(
            "UPDATE orders SET status='delivered', delivered_at=NOW() WHERE order_id=%s",
            (order_id,))

        # Mark demand as fulfilled
        cursor.execute(
            "UPDATE demands SET status='fulfilled' WHERE demand_id=%s",
            (o['demand_id'],))

        # Notify shop owner
        cursor.execute(
            '''INSERT INTO notifications (user_id, type, message, related_order_id)
               VALUES (%s, 'delivery_confirmed', %s, %s)''',
            (o['shop_owner_id'],
             f'Order #{order_id} delivered! Please rate your supplier.',
             order_id))

        db.commit()
        return jsonify({'message': 'Delivery confirmed', 'order_id': order_id}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
