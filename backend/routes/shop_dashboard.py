from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

shop_dashboard_bp = Blueprint('shop_dashboard', __name__)


@shop_dashboard_bp.route('/stats', methods=['GET'])
@jwt_required()
def shop_stats():
    """Stats for shop owner dashboard."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            "SELECT COUNT(*) AS c FROM demands WHERE shop_owner_id=%s AND status='open'",
            (user_id,))
        open_demands = cursor.fetchone()['c']

        cursor.execute(
            "SELECT COUNT(*) AS c FROM demands WHERE shop_owner_id=%s AND status='matched'",
            (user_id,))
        matched_demands = cursor.fetchone()['c']

        # Active orders = pending or accepted or out_for_delivery
        cursor.execute(
            "SELECT COUNT(*) AS c FROM orders WHERE shop_owner_id=%s "
            "AND status IN ('pending','accepted','out_for_delivery')",
            (user_id,))
        active_orders = cursor.fetchone()['c']

        return jsonify({
            'open_demands': open_demands,
            'matched_demands': matched_demands,
            'active_orders': active_orders,
        }), 200
    finally:
        cursor.close()
        db.close()
