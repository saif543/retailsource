from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import get_db

earnings_bp = Blueprint('earnings', __name__)

PLATFORM_FEE_RATE = 0.02  # 2% commission on every delivered order


@earnings_bp.route('/stockholder', methods=['GET'])
@jwt_required()
def stockholder_earnings():
    """Earnings breakdown for the logged-in stockholder."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        # Overall totals
        cursor.execute('''
            SELECT
                COALESCE(SUM(total_price), 0) AS gross_total,
                COUNT(*) AS total_orders,
                COALESCE(SUM(
                    CASE WHEN MONTH(delivered_at) = MONTH(NOW())
                          AND YEAR(delivered_at)  = YEAR(NOW())
                    THEN total_price ELSE 0 END), 0) AS this_month_gross,
                COALESCE(SUM(
                    CASE WHEN MONTH(delivered_at) = MONTH(NOW() - INTERVAL 1 MONTH)
                          AND YEAR(delivered_at)  = YEAR(NOW() - INTERVAL 1 MONTH)
                    THEN total_price ELSE 0 END), 0) AS last_month_gross
            FROM orders
            WHERE stockholder_id = %s AND status = 'delivered'
        ''', (user_id,))
        row = cursor.fetchone()

        gross        = float(row['gross_total']     or 0)
        this_gross   = float(row['this_month_gross'] or 0)
        last_gross   = float(row['last_month_gross'] or 0)
        fee          = PLATFORM_FEE_RATE

        # Monthly breakdown – last 6 months
        cursor.execute('''
            SELECT
                DATE_FORMAT(delivered_at, '%%Y-%%m')  AS month,
                DATE_FORMAT(delivered_at, '%%b %%Y')  AS label,
                DATE_FORMAT(delivered_at, '%%b')      AS short_label,
                COALESCE(SUM(total_price), 0)          AS gross
            FROM orders
            WHERE stockholder_id = %s
              AND status = 'delivered'
              AND delivered_at >= NOW() - INTERVAL 6 MONTH
            GROUP BY month, label, short_label
            ORDER BY month ASC
        ''', (user_id,))
        monthly = cursor.fetchall()
        for m in monthly:
            m['gross'] = float(m['gross'])
            m['net']   = round(m['gross'] * (1 - fee), 2)

        # Recent transactions (last 15)
        cursor.execute('''
            SELECT o.order_id, o.total_price, o.quantity, o.unit, o.delivered_at,
                   p.name AS product_name, v.variant_name,
                   sop.shop_name, u.name AS buyer_name
            FROM orders o
            JOIN demands d        ON o.demand_id    = d.demand_id
            JOIN products p       ON d.product_id   = p.product_id
            JOIN product_variants v ON d.variant_id = v.variant_id
            JOIN shop_owner_profile sop ON o.shop_owner_id = sop.user_id
            JOIN users u          ON o.shop_owner_id = u.user_id
            WHERE o.stockholder_id = %s AND o.status = 'delivered'
            ORDER BY o.delivered_at DESC
            LIMIT 15
        ''', (user_id,))
        txns = cursor.fetchall()
        for t in txns:
            t['total_price']   = float(t['total_price'])
            t['quantity']      = float(t['quantity'])
            t['platform_fee']  = round(t['total_price'] * fee, 2)
            t['net_amount']    = round(t['total_price'] * (1 - fee), 2)
            if t.get('delivered_at'):
                t['delivered_at'] = t['delivered_at'].isoformat()

        return jsonify({
            'gross_total':        round(gross, 2),
            'net_total':          round(gross * (1 - fee), 2),
            'platform_fee_total': round(gross * fee, 2),
            'total_orders':       int(row['total_orders']),
            'this_month_gross':   round(this_gross, 2),
            'this_month_net':     round(this_gross * (1 - fee), 2),
            'last_month_gross':   round(last_gross, 2),
            'last_month_net':     round(last_gross * (1 - fee), 2),
            'fee_rate_percent':   fee * 100,
            'monthly':            monthly,
            'transactions':       txns,
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()


@earnings_bp.route('/platform', methods=['GET'])
@jwt_required()
def platform_earnings():
    """Platform-wide earnings overview. Admin only."""
    user_id = get_jwt_identity()
    db = get_db()
    cursor = db.cursor(dictionary=True)
    try:
        cursor.execute('SELECT role FROM users WHERE user_id = %s', (user_id,))
        u = cursor.fetchone()
        if not u or u['role'] != 'admin':
            return jsonify({'error': 'Admin access required'}), 403

        fee = PLATFORM_FEE_RATE

        # Overall stats
        cursor.execute('''
            SELECT
                COALESCE(SUM(total_price), 0)           AS gmv,
                COUNT(*)                                  AS total_orders,
                COUNT(DISTINCT shop_owner_id)             AS total_buyers,
                COUNT(DISTINCT stockholder_id)            AS total_sellers,
                COALESCE(SUM(
                    CASE WHEN MONTH(delivered_at) = MONTH(NOW())
                          AND YEAR(delivered_at)  = YEAR(NOW())
                    THEN total_price ELSE 0 END), 0)     AS this_month_gmv,
                COALESCE(SUM(
                    CASE WHEN MONTH(delivered_at) = MONTH(NOW() - INTERVAL 1 MONTH)
                          AND YEAR(delivered_at)  = YEAR(NOW() - INTERVAL 1 MONTH)
                    THEN total_price ELSE 0 END), 0)     AS last_month_gmv
            FROM orders
            WHERE status = 'delivered'
        ''')
        row = cursor.fetchone()
        gmv          = float(row['gmv']            or 0)
        this_gmv     = float(row['this_month_gmv'] or 0)
        last_gmv     = float(row['last_month_gmv'] or 0)

        # Monthly breakdown – last 6 months
        cursor.execute('''
            SELECT
                DATE_FORMAT(delivered_at, '%%Y-%%m') AS month,
                DATE_FORMAT(delivered_at, '%%b')     AS label,
                COALESCE(SUM(total_price), 0)         AS gmv,
                COUNT(*)                               AS orders
            FROM orders
            WHERE status = 'delivered'
              AND delivered_at >= NOW() - INTERVAL 6 MONTH
            GROUP BY month, label
            ORDER BY month ASC
        ''')
        monthly = cursor.fetchall()
        for m in monthly:
            m['gmv']          = float(m['gmv'])
            m['platform_fee'] = round(m['gmv'] * fee, 2)

        # Top 5 stockholders by revenue
        cursor.execute('''
            SELECT sp.company_name,
                   SUM(o.total_price) AS revenue,
                   COUNT(*)           AS orders
            FROM orders o
            JOIN stockholder_profile sp ON o.stockholder_id = sp.user_id
            WHERE o.status = 'delivered'
            GROUP BY o.stockholder_id, sp.company_name
            ORDER BY revenue DESC
            LIMIT 5
        ''')
        top_sellers = cursor.fetchall()
        for s in top_sellers:
            s['revenue'] = float(s['revenue'])

        # Top 5 shop owners by spending
        cursor.execute('''
            SELECT sop.shop_name,
                   SUM(o.total_price) AS spent,
                   COUNT(*)           AS orders
            FROM orders o
            JOIN shop_owner_profile sop ON o.shop_owner_id = sop.user_id
            WHERE o.status = 'delivered'
            GROUP BY o.shop_owner_id, sop.shop_name
            ORDER BY spent DESC
            LIMIT 5
        ''')
        top_buyers = cursor.fetchall()
        for b in top_buyers:
            b['spent'] = float(b['spent'])

        # Recent 10 transactions
        cursor.execute('''
            SELECT o.order_id, o.total_price, o.delivered_at,
                   p.name            AS product_name,
                   sp.company_name   AS seller,
                   sop.shop_name     AS buyer
            FROM orders o
            JOIN demands d          ON o.demand_id    = d.demand_id
            JOIN products p         ON d.product_id   = p.product_id
            JOIN stockholder_profile sp  ON o.stockholder_id = sp.user_id
            JOIN shop_owner_profile sop  ON o.shop_owner_id  = sop.user_id
            WHERE o.status = 'delivered'
            ORDER BY o.delivered_at DESC
            LIMIT 10
        ''')
        recent = cursor.fetchall()
        for r in recent:
            r['total_price']  = float(r['total_price'])
            r['platform_fee'] = round(r['total_price'] * fee, 2)
            if r.get('delivered_at'):
                r['delivered_at'] = r['delivered_at'].isoformat()

        return jsonify({
            'gmv':               round(gmv, 2),
            'platform_revenue':  round(gmv * fee, 2),
            'this_month_gmv':    round(this_gmv, 2),
            'this_month_revenue':round(this_gmv * fee, 2),
            'last_month_revenue':round(last_gmv * fee, 2),
            'total_orders':      int(row['total_orders']),
            'total_buyers':      int(row['total_buyers']),
            'total_sellers':     int(row['total_sellers']),
            'fee_rate_percent':  fee * 100,
            'monthly':           monthly,
            'top_sellers':       top_sellers,
            'top_buyers':        top_buyers,
            'recent':            recent,
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        db.close()
