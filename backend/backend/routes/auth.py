from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
import bcrypt
from db import get_db

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register/shop-owner', methods=['POST'])
def register_shop_owner():
    """Register a new shop owner."""
    data = request.get_json()

    # Required fields
    name = data.get('name')
    phone = data.get('phone')
    password = data.get('password')
    confirm_password = data.get('confirm_password')
    shop_name = data.get('shop_name')
    shop_category = data.get('shop_category')
    shop_address = data.get('shop_address')
    district = data.get('district')
    area = data.get('area')

    # Optional fields
    email = data.get('email') or None
    lat = data.get('lat')
    lng = data.get('lng')

    # Validation
    if not all([name, phone, password, confirm_password, shop_name, shop_category, shop_address, district, area]):
        return jsonify({'error': 'All required fields must be filled'}), 400

    if password != confirm_password:
        return jsonify({'error': 'Passwords do not match'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    if shop_category not in ('Grocery', 'Pharmacy', 'Stationary', 'Hardware'):
        return jsonify({'error': 'Invalid shop category'}), 400

    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    db = get_db()
    cursor = db.cursor()

    try:
        # Insert into users table
        cursor.execute(
            'INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s, %s, %s, %s, %s)',
            (name, email, phone, password_hash, 'shop_owner')
        )
        user_id = cursor.lastrowid

        # Insert into shop_owner_profile
        cursor.execute(
            '''INSERT INTO shop_owner_profile
            (user_id, shop_name, shop_category, shop_address, district, area, lat, lng)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)''',
            (user_id, shop_name, shop_category, shop_address, district, area, lat, lng)
        )

        db.commit()

        token = create_access_token(identity=str(user_id))

        return jsonify({
            'message': 'Shop owner registration successful',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': name,
                'email': email,
                'phone': phone,
                'role': 'shop_owner',
                'shop_name': shop_name,
            }
        }), 201

    except Exception as e:
        db.rollback()
        if 'Duplicate entry' in str(e):
            if 'phone' in str(e):
                return jsonify({'error': 'Phone number already registered'}), 409
            if 'email' in str(e):
                return jsonify({'error': 'Email already registered'}), 409
            return jsonify({'error': 'Account already exists'}), 409
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@auth_bp.route('/register/stockholder', methods=['POST'])
def register_stockholder():
    """Register a new stockholder/supplier."""
    data = request.get_json()

    # Required fields
    name = data.get('name')
    phone = data.get('phone')
    password = data.get('password')
    confirm_password = data.get('confirm_password')
    company_name = data.get('company_name')
    categories = data.get('categories', [])  # list of category names like ['Grocery', 'Pharmacy']
    warehouse_address = data.get('warehouse_address')
    district = data.get('district')
    area = data.get('area')

    # Optional fields
    email = data.get('email') or None
    lat = data.get('lat')
    lng = data.get('lng')

    # Validation
    if not all([name, phone, password, confirm_password, company_name, warehouse_address, district, area]):
        return jsonify({'error': 'All required fields must be filled'}), 400

    if not categories or len(categories) == 0:
        return jsonify({'error': 'Select at least one product category'}), 400

    if password != confirm_password:
        return jsonify({'error': 'Passwords do not match'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400

    valid_categories = ('Grocery', 'Pharmacy', 'Stationary', 'Hardware')
    for cat in categories:
        if cat not in valid_categories:
            return jsonify({'error': f'Invalid category: {cat}'}), 400

    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        # Insert into users table
        cursor.execute(
            'INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s, %s, %s, %s, %s)',
            (name, email, phone, password_hash, 'stockholder')
        )
        user_id = cursor.lastrowid

        # Insert into stockholder_profile
        cursor.execute(
            '''INSERT INTO stockholder_profile
            (user_id, company_name, warehouse_address, district, area, lat, lng)
            VALUES (%s, %s, %s, %s, %s, %s, %s)''',
            (user_id, company_name, warehouse_address, district, area, lat, lng)
        )

        # Insert selected categories into stockholder_categories
        for cat_name in categories:
            cursor.execute('SELECT category_id FROM product_categories WHERE name = %s', (cat_name,))
            cat_row = cursor.fetchone()
            if cat_row:
                cursor.execute(
                    'INSERT INTO stockholder_categories (stockholder_id, category_id) VALUES (%s, %s)',
                    (user_id, cat_row['category_id'])
                )

        db.commit()

        token = create_access_token(identity=str(user_id))

        return jsonify({
            'message': 'Stockholder registration successful',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': name,
                'email': email,
                'phone': phone,
                'role': 'stockholder',
                'company_name': company_name,
            }
        }), 201

    except Exception as e:
        db.rollback()
        if 'Duplicate entry' in str(e):
            if 'phone' in str(e):
                return jsonify({'error': 'Phone number already registered'}), 409
            if 'email' in str(e):
                return jsonify({'error': 'Email already registered'}), 409
            return jsonify({'error': 'Account already exists'}), 409
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login with email or phone + password."""
    data = request.get_json()

    email_or_phone = data.get('email_or_phone')
    password = data.get('password')

    if not all([email_or_phone, password]):
        return jsonify({'error': 'Email/phone and password are required'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        # Check if input is email or phone
        cursor.execute(
            'SELECT * FROM users WHERE email = %s OR phone = %s',
            (email_or_phone, email_or_phone)
        )
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'Invalid email/phone or password'}), 401

        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            return jsonify({'error': 'Invalid email/phone or password'}), 401

        token = create_access_token(identity=str(user['user_id']))

        # Get profile info based on role
        profile = {}
        if user['role'] == 'shop_owner':
            cursor.execute('SELECT shop_name FROM shop_owner_profile WHERE user_id = %s', (user['user_id'],))
            row = cursor.fetchone()
            if row:
                profile['shop_name'] = row['shop_name']
        elif user['role'] == 'stockholder':
            cursor.execute('SELECT company_name FROM stockholder_profile WHERE user_id = %s', (user['user_id'],))
            row = cursor.fetchone()
            if row:
                profile['company_name'] = row['company_name']

        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': {
                'user_id': user['user_id'],
                'name': user['name'],
                'email': user['email'],
                'phone': user['phone'],
                'role': user['role'],
                **profile,
            }
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Get current logged-in user info with profile."""
    user_id = get_jwt_identity()

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute('SELECT user_id, name, email, phone, role, created_at FROM users WHERE user_id = %s', (user_id,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'User not found'}), 404

        if user['created_at']:
            user['created_at'] = user['created_at'].isoformat()

        # Get profile based on role
        if user['role'] == 'shop_owner':
            cursor.execute(
                'SELECT shop_name, shop_category, shop_address, area, district, lat, lng, is_verified, rating_avg FROM shop_owner_profile WHERE user_id = %s',
                (user_id,)
            )
            profile = cursor.fetchone()
            if profile:
                if profile['lat']:
                    profile['lat'] = float(profile['lat'])
                if profile['lng']:
                    profile['lng'] = float(profile['lng'])
                if profile['rating_avg']:
                    profile['rating_avg'] = float(profile['rating_avg'])
                user['profile'] = profile

        elif user['role'] == 'stockholder':
            cursor.execute(
                'SELECT company_name, warehouse_address, area, district, lat, lng, is_verified, rating_avg FROM stockholder_profile WHERE user_id = %s',
                (user_id,)
            )
            profile = cursor.fetchone()
            if profile:
                if profile['lat']:
                    profile['lat'] = float(profile['lat'])
                if profile['lng']:
                    profile['lng'] = float(profile['lng'])
                if profile['rating_avg']:
                    profile['rating_avg'] = float(profile['rating_avg'])
                user['profile'] = profile

            # Get stockholder's categories
            cursor.execute(
                '''SELECT pc.name FROM stockholder_categories sc
                JOIN product_categories pc ON sc.category_id = pc.category_id
                WHERE sc.stockholder_id = %s''',
                (user_id,)
            )
            cats = cursor.fetchall()
            user['categories'] = [c['name'] for c in cats]

        return jsonify({'user': user}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
