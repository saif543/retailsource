from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

stocks_bp = Blueprint('stocks', __name__)


# ── Stockholder: dashboard stats ──────────────────────────────────────────────

@stocks_bp.route('/dashboard', methods=['GET'])
@jwt_required()
def stock_dashboard():
    """Stats for stockholder dashboard home screen."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT COUNT(*) AS c FROM stock WHERE stockholder_id=%s AND status='available'",
            (user_id,))
        active_stock = cursor.fetchone()['c']

        cursor.execute(
            "SELECT COUNT(*) AS c FROM orders WHERE stockholder_id=%s AND status='pending'",
            (user_id,))
        new_orders = cursor.fetchone()['c']

        cursor.execute(
            "SELECT COUNT(*) AS c FROM orders WHERE stockholder_id=%s AND status='delivered'",
            (user_id,))
        total_delivered = cursor.fetchone()['c']

        cursor.execute(
            "SELECT COUNT(*) AS c FROM orders WHERE stockholder_id=%s "
            "AND status IN ('accepted','out_for_delivery')",
            (user_id,))
        active_orders = cursor.fetchone()['c']

        return jsonify({
            'active_stock': active_stock,
            'new_orders': new_orders,
            'total_delivered': total_delivered,
            'active_orders': active_orders,
        }), 200
    finally:
        cursor.close()
        db.close()


# ── Stockholder: CRUD own stock ───────────────────────────────────────────────

@stocks_bp.route('/create', methods=['POST'])
@jwt_required()
def create_stock():
    """Stockholder posts a new stock item."""
    user_id = get_jwt_identity()
    data = request.get_json()

    product_id = data.get('product_id')
    variant_id = data.get('variant_id')
    quantity = data.get('quantity_available')
    unit = data.get('unit')
    price = data.get('price_per_unit')
    warehouse_area = data.get('warehouse_area') or None
    lat = data.get('lat')
    lng = data.get('lng')
    notes = data.get('additional_notes') or None

    if not all([product_id, variant_id, quantity, unit, price]):
        return jsonify({'error': 'product_id, variant_id, quantity_available, unit, price_per_unit required'}), 400
    if unit not in ('kg', 'litre', 'piece', 'pack'):
        return jsonify({'error': 'Invalid unit'}), 400

    try:
        quantity = float(quantity)
        price = float(price)
        if quantity <= 0 or price <= 0:
            return jsonify({'error': 'Quantity and price must be > 0'}), 400
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid quantity or price'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('SELECT role FROM users WHERE user_id = %s', (user_id,))
        u = cursor.fetchone()
        if not u or u['role'] != 'stockholder':
            return jsonify({'error': 'Only stockholders can post stock'}), 403

        # Use warehouse lat/lng from profile if not provided
        if lat is None or lng is None:
            cursor.execute('SELECT lat, lng FROM stockholder_profile WHERE user_id=%s', (user_id,))
            p = cursor.fetchone()
            if p:
                lat = p['lat']
                lng = p['lng']

        cursor.execute(
            '''INSERT INTO stock
               (stockholder_id, product_id, variant_id, quantity_available, unit,
                price_per_unit, warehouse_area, lat, lng, additional_notes)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)''',
            (user_id, product_id, variant_id, quantity, unit,
             price, warehouse_area, lat, lng, notes)
        )
        db.commit()
        return jsonify({'message': 'Stock posted', 'stock_id': cursor.lastrowid}), 201
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@stocks_bp.route('/my', methods=['GET'])
@jwt_required()
def my_stock():
    """List all stock items posted by the logged-in stockholder."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT s.stock_id, s.quantity_available, s.unit, s.price_per_unit,
                   s.warehouse_area, s.lat, s.lng, s.status,
                   s.additional_notes, s.created_at, s.updated_at,
                   p.name AS product_name, p.product_id,
                   v.variant_name, v.variant_id,
                   pc.name AS category_name
            FROM stock s
            JOIN products p ON s.product_id = p.product_id
            JOIN product_variants v ON s.variant_id = v.variant_id
            JOIN product_categories pc ON p.category_id = pc.category_id
            WHERE s.stockholder_id = %s
            ORDER BY s.created_at DESC
        ''', (user_id,))
        rows = cursor.fetchall()
        for r in rows:
            for ts in ('created_at', 'updated_at'):
                if r.get(ts):
                    r[ts] = r[ts].isoformat()
            for k in ('quantity_available', 'price_per_unit', 'lat', 'lng'):
                if r.get(k) is not None:
                    r[k] = float(r[k])
        return jsonify({'stocks': rows}), 200
    finally:
        cursor.close()
        db.close()


@stocks_bp.route('/<int:stock_id>/update', methods=['PUT'])
@jwt_required()
def update_stock(stock_id):
    """Update quantity, price, address, notes or status of a stock item."""
    user_id = get_jwt_identity()
    data = request.get_json()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id FROM stock WHERE stock_id = %s', (stock_id,))
        s = cursor.fetchone()
        if not s:
            return jsonify({'error': 'Stock not found'}), 404
        if str(s['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your stock'}), 403

        fields, vals = [], []
        if 'quantity_available' in data:
            fields.append('quantity_available=%s')
            vals.append(float(data['quantity_available']))
        if 'price_per_unit' in data:
            fields.append('price_per_unit=%s')
            vals.append(float(data['price_per_unit']))
        if 'warehouse_area' in data:
            fields.append('warehouse_area=%s')
            vals.append(data['warehouse_area'])
        if 'additional_notes' in data:
            fields.append('additional_notes=%s')
            vals.append(data['additional_notes'])
        if 'status' in data:
            if data['status'] not in ('available', 'sold_out'):
                return jsonify({'error': 'Invalid status'}), 400
            fields.append('status=%s')
            vals.append(data['status'])
        if 'lat' in data:
            fields.append('lat=%s')
            vals.append(data['lat'])
        if 'lng' in data:
            fields.append('lng=%s')
            vals.append(data['lng'])

        if not fields:
            return jsonify({'error': 'Nothing to update'}), 400

        vals.append(stock_id)
        cursor.execute(
            f'UPDATE stock SET {", ".join(fields)}, updated_at=NOW() WHERE stock_id=%s',
            vals)
        db.commit()
        return jsonify({'message': 'Stock updated'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@stocks_bp.route('/<int:stock_id>/delete', methods=['DELETE'])
@jwt_required()
def delete_stock(stock_id):
    """Delete a stock item (only if no pending/active orders reference it)."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT stockholder_id FROM stock WHERE stock_id = %s', (stock_id,))
        s = cursor.fetchone()
        if not s:
            return jsonify({'error': 'Stock not found'}), 404
        if str(s['stockholder_id']) != str(user_id):
            return jsonify({'error': 'Not your stock'}), 403

        cursor.execute(
            "SELECT COUNT(*) AS c FROM orders WHERE stock_id=%s "
            "AND status IN ('pending','accepted','out_for_delivery')",
            (stock_id,))
        if cursor.fetchone()['c'] > 0:
            return jsonify({'error': 'Cannot delete stock with active orders'}), 400

        cursor.execute('DELETE FROM stock WHERE stock_id=%s', (stock_id,))
        db.commit()
        return jsonify({'message': 'Stock deleted'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


# ── Stockholder: nearby open demands ─────────────────────────────────────────

@stocks_bp.route('/nearby-demands', methods=['GET'])
@jwt_required()
def nearby_demands():
    """Open demands within 10 km of the stockholder's warehouse."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT lat, lng FROM stockholder_profile WHERE user_id=%s', (user_id,))
        loc = cursor.fetchone()
        if not loc or loc['lat'] is None:
            return jsonify({'error': 'Set your warehouse location first'}), 400

        s_lat = float(loc['lat'])
        s_lng = float(loc['lng'])

        cursor.execute('''
            SELECT d.demand_id, d.quantity, d.unit, d.location_area,
                   d.lat, d.lng, d.additional_notes, d.created_at,
                   p.name AS product_name, p.product_id,
                   v.variant_name, v.variant_id,
                   pc.name AS category_name,
                   u.name AS shop_owner_name,
                   sop.shop_name,
                   (6371 * ACOS(
                       COS(RADIANS(%s)) * COS(RADIANS(d.lat)) *
                       COS(RADIANS(d.lng) - RADIANS(%s)) +
                       SIN(RADIANS(%s)) * SIN(RADIANS(d.lat))
                   )) AS distance_km
            FROM demands d
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN product_categories pc ON p.category_id = pc.category_id
            JOIN users u ON d.shop_owner_id = u.user_id
            JOIN shop_owner_profile sop ON d.shop_owner_id = sop.user_id
            WHERE d.status = 'open'
              AND d.lat IS NOT NULL
            HAVING distance_km <= 10
            ORDER BY distance_km ASC
            LIMIT 50
        ''', (s_lat, s_lng, s_lat))

        rows = cursor.fetchall()
        for r in rows:
            if r.get('created_at'):
                r['created_at'] = r['created_at'].isoformat()
            for k in ('quantity', 'lat', 'lng', 'distance_km'):
                if r.get(k) is not None:
                    r[k] = float(r[k])
        return jsonify({'demands': rows}), 200
    finally:
        cursor.close()
        db.close()


@stocks_bp.route('/search', methods=['GET'])
@jwt_required()
def search_stocks():
    """Search available stocks. Optional: q (product/variant name),
    category_id, lat+lng (for distance + 10km filter)."""
    user_id = get_jwt_identity()
    q = (request.args.get('q') or '').strip()
    category_id = request.args.get('category_id', type=int)
    lat = request.args.get('lat', type=float)
    lng = request.args.get('lng', type=float)

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Auto-fill lat/lng from shop owner profile if not provided
        if lat is None or lng is None:
            cursor.execute(
                'SELECT lat, lng FROM shop_owner_profile WHERE user_id = %s',
                (user_id,),
            )
            r = cursor.fetchone()
            if r and r['lat'] is not None and r['lng'] is not None:
                lat = float(r['lat'])
                lng = float(r['lng'])

        params = []
        select_dist = ''
        having = ''
        order = 'ORDER BY s.created_at DESC'
        if lat is not None and lng is not None:
            select_dist = ''',
                   (6371 * ACOS(
                       COS(RADIANS(%s)) * COS(RADIANS(s.lat)) *
                       COS(RADIANS(s.lng) - RADIANS(%s)) +
                       SIN(RADIANS(%s)) * SIN(RADIANS(s.lat))
                   )) AS distance_km'''
            params += [lat, lng, lat]
            having = 'HAVING distance_km <= 10'
            order = 'ORDER BY distance_km ASC, s.price_per_unit ASC'

        where = ["s.status = 'available'", 's.quantity_available > 0']
        if q:
            where.append('(p.name LIKE %s OR v.variant_name LIKE %s OR sp.company_name LIKE %s)')
            like = f'%{q}%'
            params += [like, like, like]
        if category_id:
            where.append('p.category_id = %s')
            params.append(category_id)

        sql = f'''
            SELECT s.stock_id, s.product_id, s.variant_id, s.quantity_available,
                   s.unit, s.price_per_unit, s.warehouse_area, s.lat, s.lng,
                   s.additional_notes, s.created_at,
                   p.name AS product_name, pc.name AS category_name,
                   v.variant_name,
                   u.user_id AS stockholder_id, u.name AS stockholder_name,
                   sp.company_name, sp.rating_avg
                   {select_dist}
            FROM stock s
            JOIN products p ON s.product_id = p.product_id
            JOIN product_variants v ON s.variant_id = v.variant_id
            JOIN product_categories pc ON p.category_id = pc.category_id
            JOIN users u ON s.stockholder_id = u.user_id
            JOIN stockholder_profile sp ON s.stockholder_id = sp.user_id
            WHERE {' AND '.join(where)}
            {having}
            {order}
            LIMIT 60
        '''
        cursor.execute(sql, params)
        rows = cursor.fetchall()
        for r in rows:
            if r.get('created_at'):
                r['created_at'] = r['created_at'].isoformat()
            for k in ('quantity_available', 'price_per_unit', 'lat', 'lng',
                      'rating_avg', 'distance_km'):
                if r.get(k) is not None:
                    r[k] = float(r[k])
        return jsonify({'stocks': rows}), 200
    finally:
        cursor.close()
        db.close()
