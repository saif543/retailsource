from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

profile_bp = Blueprint('profile', __name__)


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
