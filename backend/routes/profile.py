from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

profile_bp = Blueprint('profile', __name__)


@profile_bp.route('', methods=['GET'])
@jwt_required()
def get_profile():
    """Get the full profile of the logged-in user (any role)."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT user_id, name, email, phone, role, created_at FROM users WHERE user_id=%s',
            (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'error': 'User not found'}), 404
        if user.get('created_at'):
            user['created_at'] = user['created_at'].isoformat()

        if user['role'] == 'shop_owner':
            cursor.execute(
                '''SELECT shop_name, shop_category, shop_address, area, district,
                          lat, lng, is_verified, rating_avg
                   FROM shop_owner_profile WHERE user_id=%s''', (user_id,))
            p = cursor.fetchone()
            if p:
                for k in ('lat', 'lng', 'rating_avg'):
                    if p.get(k) is not None:
                        p[k] = float(p[k])
                user['profile'] = p

        elif user['role'] == 'stockholder':
            cursor.execute(
                '''SELECT company_name, warehouse_address, area, district,
                          lat, lng, is_verified, rating_avg, specialization
                   FROM stockholder_profile WHERE user_id=%s''', (user_id,))
            p = cursor.fetchone()
            if p:
                for k in ('lat', 'lng', 'rating_avg'):
                    if p.get(k) is not None:
                        p[k] = float(p[k])
                user['profile'] = p

        return jsonify({'user': user}), 200
    finally:
        cursor.close()
        db.close()


@profile_bp.route('/update', methods=['PUT'])
@jwt_required()
def update_profile():
    """Update editable profile fields. Works for both roles."""
    user_id = get_jwt_identity()
    data = request.get_json()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('SELECT role FROM users WHERE user_id=%s', (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        # Update users table
        if 'name' in data:
            cursor.execute('UPDATE users SET name=%s WHERE user_id=%s',
                           (data['name'], user_id))

        if user['role'] == 'shop_owner':
            fields, vals = [], []
            for col in ('shop_name', 'shop_category', 'shop_address', 'area', 'district'):
                if col in data:
                    fields.append(f'{col}=%s')
                    vals.append(data[col])
            if fields:
                vals.append(user_id)
                cursor.execute(
                    f'UPDATE shop_owner_profile SET {", ".join(fields)} WHERE user_id=%s',
                    vals)

        elif user['role'] == 'stockholder':
            fields, vals = [], []
            for col in ('company_name', 'warehouse_address', 'area', 'district', 'specialization'):
                if col in data:
                    fields.append(f'{col}=%s')
                    vals.append(data[col])
            if fields:
                vals.append(user_id)
                cursor.execute(
                    f'UPDATE stockholder_profile SET {", ".join(fields)} WHERE user_id=%s',
                    vals)

        db.commit()
        return jsonify({'message': 'Profile updated'}), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@profile_bp.route('/location', methods=['PUT'])
@jwt_required()
def update_location():
    """Save the user's address + lat/lng to their profile.
    Works for both shop_owner and stockholder."""
    user_id = get_jwt_identity()
    data = request.get_json()

    address = data.get('address')
    lat = data.get('lat')
    lng = data.get('lng')
    area = data.get('area') or None
    district = data.get('district') or None

    if not address or lat is None or lng is None:
        return jsonify({'error': 'address, lat and lng are required'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('SELECT role FROM users WHERE user_id = %s', (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user['role'] == 'shop_owner':
            cursor.execute(
                '''UPDATE shop_owner_profile
                   SET shop_address=%s, lat=%s, lng=%s, area=%s, district=%s
                   WHERE user_id=%s''',
                (address, lat, lng, area, district, user_id)
            )
        elif user['role'] == 'stockholder':
            cursor.execute(
                '''UPDATE stockholder_profile
                   SET warehouse_address=%s, lat=%s, lng=%s, area=%s, district=%s
                   WHERE user_id=%s''',
                (address, lat, lng, area, district, user_id)
            )
        else:
            return jsonify({'error': 'Admin has no location'}), 400

        db.commit()
        return jsonify({
            'message': 'Location saved',
            'address': address,
            'lat': lat,
            'lng': lng,
            'area': area,
            'district': district,
        }), 200
    except Exception as e:
        db.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
