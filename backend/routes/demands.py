from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

demands_bp = Blueprint('demands', __name__)


@demands_bp.route('/create', methods=['POST'])
@jwt_required()
def create_demand():
    """Shop owner creates a new demand."""
    user_id = get_jwt_identity()
    data = request.get_json()

    product_id = data.get('product_id')
    variant_id = data.get('variant_id')
    quantity = data.get('quantity')
    unit = data.get('unit')
    location_area = data.get('location_area') or None
    lat = data.get('lat')
    lng = data.get('lng')
    notes = data.get('additional_notes') or None

    if not all([product_id, variant_id, quantity, unit]):
        return jsonify({'error': 'product_id, variant_id, quantity and unit are required'}), 400

    if unit not in ('kg', 'litre', 'piece', 'pack'):
        return jsonify({'error': 'Invalid unit'}), 400

    try:
        quantity = float(quantity)
        if quantity <= 0:
            return jsonify({'error': 'Quantity must be greater than 0'}), 400
    except (TypeError, ValueError):
        return jsonify({'error': 'Invalid quantity'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Verify role
        cursor.execute('SELECT role FROM users WHERE user_id = %s', (user_id,))
        user = cursor.fetchone()
        if not user or user['role'] != 'shop_owner':
            return jsonify({'error': 'Only shop owners can post demands'}), 403

        cursor.execute(
            '''INSERT INTO demands
               (shop_owner_id, product_id, variant_id, quantity, unit,
                location_area, lat, lng, additional_notes)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)''',
            (user_id, product_id, variant_id, quantity, unit,
             location_area, lat, lng, notes)
        )
        db.commit()
        return jsonify({
            'message': 'Demand posted successfully',
            'demand_id': cursor.lastrowid,
        }), 201
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@demands_bp.route('/my', methods=['GET'])
@jwt_required()
def my_demands():
    """List the current shop owner's demands with product/variant names."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT d.demand_id, d.quantity, d.unit, d.location_area,
                   d.lat, d.lng, d.additional_notes, d.status, d.created_at,
                   p.name AS product_name, p.product_id,
                   v.variant_name, v.variant_id,
                   pc.name AS category_name
            FROM demands d
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN product_categories pc ON p.category_id = pc.category_id
            WHERE d.shop_owner_id = %s
            ORDER BY d.created_at DESC
        ''', (user_id,))

        demands = cursor.fetchall()
        for d in demands:
            if d.get('created_at'):
                d['created_at'] = d['created_at'].isoformat()
            for k in ('quantity', 'lat', 'lng'):
                if d.get(k) is not None:
                    d[k] = float(d[k])

        return jsonify({'demands': demands}), 200
    finally:
        cursor.close()
        db.close()


@demands_bp.route('/<int:demand_id>', methods=['GET'])
@jwt_required()
def get_demand(demand_id):
    """Get one demand with full details (owner-only)."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('''
            SELECT d.demand_id, d.shop_owner_id, d.quantity, d.unit, d.location_area,
                   d.lat, d.lng, d.additional_notes, d.status, d.created_at,
                   p.name AS product_name, p.product_id,
                   v.variant_name, v.variant_id,
                   pc.name AS category_name
            FROM demands d
            JOIN products p ON d.product_id = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN product_categories pc ON p.category_id = pc.category_id
            WHERE d.demand_id = %s
        ''', (demand_id,))
        d = cursor.fetchone()
        if not d:
            return jsonify({'error': 'Demand not found'}), 404
        if str(d['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your demand'}), 403

        if d.get('created_at'):
            d['created_at'] = d['created_at'].isoformat()
        for k in ('quantity', 'lat', 'lng'):
            if d.get(k) is not None:
                d[k] = float(d[k])

        return jsonify({'demand': d}), 200
    finally:
        cursor.close()
        db.close()


@demands_bp.route('/<int:demand_id>/matches', methods=['GET'])
@jwt_required()
def find_matches(demand_id):
    """Find nearby stockholders with matching stock within 10km using haversine."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            '''SELECT shop_owner_id, product_id, variant_id, quantity, lat, lng
               FROM demands WHERE demand_id = %s''',
            (demand_id,)
        )
        d = cursor.fetchone()
        if not d:
            return jsonify({'error': 'Demand not found'}), 404
        if str(d['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your demand'}), 403
        if d['lat'] is None or d['lng'] is None:
            return jsonify({'error': 'Demand has no location'}), 400

        cursor.execute('''
            SELECT s.stock_id, s.quantity_available, s.unit, s.price_per_unit,
                   s.warehouse_area, s.lat, s.lng, s.additional_notes,
                   u.user_id AS stockholder_id, u.name AS stockholder_name,
                   sp.company_name, sp.rating_avg,
                   (6371 * ACOS(
                       COS(RADIANS(%s)) * COS(RADIANS(s.lat)) *
                       COS(RADIANS(s.lng) - RADIANS(%s)) +
                       SIN(RADIANS(%s)) * SIN(RADIANS(s.lat))
                   )) AS distance_km
            FROM stock s
            JOIN users u ON s.stockholder_id = u.user_id
            JOIN stockholder_profile sp ON s.stockholder_id = sp.user_id
            WHERE s.product_id = %s
              AND s.variant_id = %s
              AND s.status = 'available'
              AND s.quantity_available >= %s
            HAVING distance_km <= 10
            ORDER BY distance_km ASC, s.price_per_unit ASC
        ''', (float(d['lat']), float(d['lng']), float(d['lat']),
              d['product_id'], d['variant_id'], float(d['quantity'])))

        matches = cursor.fetchall()
        for m in matches:
            for k in ('quantity_available', 'price_per_unit', 'lat', 'lng',
                      'rating_avg', 'distance_km'):
                if m.get(k) is not None:
                    m[k] = float(m[k])
        return jsonify({'matches': matches}), 200
    finally:
        cursor.close()
        db.close()


@demands_bp.route('/<int:demand_id>', methods=['DELETE'])
@jwt_required()
def cancel_demand(demand_id):
    """Cancel (delete) a demand. Only owner, only if status=open."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT shop_owner_id, status FROM demands WHERE demand_id = %s',
            (demand_id,)
        )
        d = cursor.fetchone()
        if not d:
            return jsonify({'error': 'Demand not found'}), 404
        if str(d['shop_owner_id']) != str(user_id):
            return jsonify({'error': 'Not your demand'}), 403
        if d['status'] != 'open':
            return jsonify({'error': 'Only open demands can be cancelled'}), 400

        cursor.execute('DELETE FROM demands WHERE demand_id = %s', (demand_id,))
        db.commit()
        return jsonify({'message': 'Demand cancelled'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
