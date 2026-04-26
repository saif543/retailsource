from flask import Blueprint, jsonify
from db import get_db

products_bp = Blueprint('products', __name__)


@products_bp.route('/categories', methods=['GET'])
def get_categories():
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('SELECT category_id, name FROM product_categories ORDER BY category_id')
        return jsonify({'categories': cursor.fetchall()}), 200
    finally:
        cursor.close()
        db.close()


@products_bp.route('/by-category/<int:category_id>', methods=['GET'])
def get_products_by_category(category_id):
    """Returns products in a category, each with its variants nested."""
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute(
            'SELECT product_id, name FROM products WHERE category_id = %s ORDER BY name',
            (category_id,)
        )
        products = cursor.fetchall()

        for p in products:
            cursor.execute(
                'SELECT variant_id, variant_name FROM product_variants WHERE product_id = %s ORDER BY variant_id',
                (p['product_id'],)
            )
            p['variants'] = cursor.fetchall()

        return jsonify({'products': products}), 200
    finally:
        cursor.close()
        db.close()
