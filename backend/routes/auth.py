from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
import bcrypt
from db import get_db

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    """Register a new user (shop_owner or stockholder)."""
    data = request.get_json()

    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    password = data.get('password')
    role = data.get('role')

    if not all([name, email, phone, password, role]):
        return jsonify({'error': 'All fields are required'}), 400

    if role not in ('shop_owner', 'stockholder', 'admin'):
        return jsonify({'error': 'Invalid role'}), 400

    password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    db = get_db()
    cursor = db.cursor()

    try:
        cursor.execute(
            'INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s, %s, %s, %s, %s)',
            (name, email, phone, password_hash, role)
        )
        user_id = cursor.lastrowid

        # Create profile based on role
        if role == 'shop_owner':
            shop_name = data.get('shop_name', '')
            area = data.get('area', '')
            cursor.execute(
                'INSERT INTO shop_owner_profile (user_id, shop_name, area) VALUES (%s, %s, %s)',
                (user_id, shop_name, area)
            )
        elif role == 'stockholder':
            company_name = data.get('company_name', '')
            area = data.get('area', '')
            cursor.execute(
                'INSERT INTO stockholder_profile (user_id, company_name, area) VALUES (%s, %s, %s)',
                (user_id, company_name, area)
            )

        db.commit()

        token = create_access_token(identity=str(user_id))

        return jsonify({
            'message': 'Registration successful',
            'token': token,
            'user': {
                'user_id': user_id,
                'name': name,
                'email': email,
                'phone': phone,
                'role': role,
            }
        }), 201

    except Exception as e:
        db.rollback()
        if 'Duplicate entry' in str(e):
            return jsonify({'error': 'Email or phone already exists'}), 409
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@auth_bp.route('/login', methods=['POST'])
def login():
    """Login with email and password."""
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not all([email, password]):
        return jsonify({'error': 'Email and password are required'}), 400

    db = get_db()
    cursor = db.cursor(dictionary=True)

    try:
        cursor.execute('SELECT * FROM users WHERE email = %s', (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({'error': 'Invalid email or password'}), 401

        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            return jsonify({'error': 'Invalid email or password'}), 401

        token = create_access_token(identity=str(user['user_id']))

        return jsonify({
            'message': 'Login successful',
            'token': token,
            'user': {
                'user_id': user['user_id'],
                'name': user['name'],
                'email': user['email'],
                'phone': user['phone'],
                'role': user['role'],
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
    """Get current logged-in user info."""
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

        return jsonify({'user': user}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
