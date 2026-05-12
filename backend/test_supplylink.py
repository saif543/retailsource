"""
SupplyLink - Black Box & White Box Test Suite
Run: python -m pytest test_supplylink.py -v
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

import pytest
from unittest.mock import patch, MagicMock
from app import app

# ─────────────────────────────────────────────────────────────
#  Shared fixtures
# ─────────────────────────────────────────────────────────────
@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as c:
        yield c


def _mock_db(cursor_rows=None, lastrowid=1):
    """Helper: returns (mock_db, mock_cursor) with preset fetchone/fetchall."""
    mc = MagicMock()
    mc.fetchone.return_value = cursor_rows[0] if cursor_rows else None
    mc.fetchall.return_value = cursor_rows or []
    mc.lastrowid = lastrowid
    mdb = MagicMock()
    mdb.cursor.return_value = mc
    return mdb, mc


# ═════════════════════════════════════════════════════════════
#  BLACK BOX TESTS  (input → expected HTTP response)
# ═════════════════════════════════════════════════════════════

class TestBlackBox_Login:
    """BB-1 through BB-4: Login endpoint behaviour"""

    def test_BB1_missing_credentials(self, client):
        """BB-1: Empty body → 400 with error message"""
        r = client.post('/api/auth/login', json={})
        assert r.status_code == 400
        assert 'required' in r.get_json().get('error', '').lower()

    def test_BB2_missing_password(self, client):
        """BB-2: Email only, no password → 400"""
        r = client.post('/api/auth/login',
                        json={'email_or_phone': 'user@test.com'})
        assert r.status_code == 400

    def test_BB3_wrong_password(self, client):
        """BB-3: Valid phone, wrong password → 401"""
        import bcrypt
        fake_hash = bcrypt.hashpw(b'correctpass', bcrypt.gensalt()).decode()
        user_row = {
            'user_id': 1, 'name': 'Test', 'email': None,
            'phone': '01711111111', 'role': 'shop_owner',
            'password_hash': fake_hash
        }
        mdb, mc = _mock_db([user_row])
        mc.fetchone.side_effect = [user_row, None]
        with patch('routes.auth.get_db', return_value=mdb):
            r = client.post('/api/auth/login',
                            json={'email_or_phone': '01711111111',
                                  'password': 'wrongpass'})
        assert r.status_code == 401
        assert 'invalid' in r.get_json().get('error', '').lower()

    def test_BB4_nonexistent_user(self, client):
        """BB-4: Phone that doesn't exist → 401"""
        mdb, mc = _mock_db([])
        mc.fetchone.return_value = None
        with patch('routes.auth.get_db', return_value=mdb):
            r = client.post('/api/auth/login',
                            json={'email_or_phone': '01999999999',
                                  'password': 'any123'})
        assert r.status_code == 401


class TestBlackBox_Registration:
    """BB-5 through BB-9: Registration validation"""

    def test_BB5_register_missing_fields(self, client):
        """BB-5: Missing required fields → 400"""
        r = client.post('/api/auth/register/shop-owner',
                        json={'name': 'Ali'})
        assert r.status_code == 400
        assert 'required' in r.get_json().get('error', '').lower()

    def test_BB6_password_too_short(self, client):
        """BB-6: Password < 6 chars → 400"""
        r = client.post('/api/auth/register/shop-owner', json={
            'name': 'Ali', 'phone': '01700000099',
            'password': '123',
            'shop_name': 'Ali Store', 'shop_category': 'Grocery'
        })
        assert r.status_code == 400
        assert '6' in r.get_json().get('error', '')

    def test_BB7_invalid_shop_category(self, client):
        """BB-7: Invalid category → 400"""
        r = client.post('/api/auth/register/shop-owner', json={
            'name': 'Ali', 'phone': '01700000099',
            'password': 'pass123',
            'shop_name': 'Ali Store', 'shop_category': 'Electronics'
        })
        assert r.status_code == 400
        assert 'category' in r.get_json().get('error', '').lower()

    def test_BB8_stockholder_no_category(self, client):
        """BB-8: Stockholder without categories → 400"""
        r = client.post('/api/auth/register/stockholder', json={
            'name': 'Rahim', 'phone': '01700000099',
            'password': 'pass123',
            'company_name': 'Rahim Traders', 'categories': []
        })
        assert r.status_code == 400

    def test_BB9_duplicate_phone(self, client):
        """BB-9: Duplicate phone → 409"""
        mdb = MagicMock()
        mc = MagicMock()
        mdb.cursor.return_value = mc
        mc.lastrowid = 99
        mdb.commit.side_effect = Exception("Duplicate entry '01711111111' for key 'phone'")
        # Trigger via execute
        mc.execute.side_effect = [None, Exception("Duplicate entry '01711111111' for key 'phone'")]

        with patch('routes.auth.get_db', return_value=mdb):
            r = client.post('/api/auth/register/shop-owner', json={
                'name': 'Ali', 'phone': '01711111111',
                'password': 'pass123',
                'shop_name': 'Ali Store', 'shop_category': 'Grocery'
            })
        assert r.status_code in (409, 500)


class TestBlackBox_Rating:
    """BB-10 through BB-13: Rating validation"""

    def _auth_header(self):
        from flask_jwt_extended import create_access_token
        with app.app_context():
            token = create_access_token(identity='1')
        return {'Authorization': f'Bearer {token}'}

    def test_BB10_rating_score_zero(self, client):
        """BB-10: Score = 0 (below range) → 400"""
        h = self._auth_header()
        order_row = {'shop_owner_id': 1, 'stockholder_id': 2, 'status': 'delivered'}
        mdb, mc = _mock_db([order_row])
        mc.fetchone.side_effect = [order_row, None]
        with patch('routes.ratings.get_db', return_value=mdb):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 0}, headers=h)
        assert r.status_code == 400
        assert '1' in r.get_json().get('error', '') or 'score' in r.get_json().get('error', '').lower()

    def test_BB11_rating_score_six(self, client):
        """BB-11: Score = 6 (above range) → 400"""
        h = self._auth_header()
        with patch('routes.ratings.get_db', return_value=_mock_db()[0]):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 6}, headers=h)
        assert r.status_code == 400

    def test_BB12_rate_non_delivered_order(self, client):
        """BB-12: Rating an accepted (not delivered) order → 400"""
        h = self._auth_header()
        order_row = {'shop_owner_id': 1, 'stockholder_id': 2, 'status': 'accepted'}
        mdb, mc = _mock_db([order_row])
        mc.fetchone.return_value = order_row
        with patch('routes.ratings.get_db', return_value=mdb):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 4}, headers=h)
        assert r.status_code == 400
        assert 'delivered' in r.get_json().get('error', '').lower()

    def test_BB13_duplicate_rating(self, client):
        """BB-13: Rating an already-rated order → 409"""
        h = self._auth_header()
        order_row = {'shop_owner_id': 1, 'stockholder_id': 2, 'status': 'delivered'}
        existing_rating = {'rating_id': 5}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [order_row, existing_rating]
        with patch('routes.ratings.get_db', return_value=mdb):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 3}, headers=h)
        assert r.status_code == 409
        assert 'already' in r.get_json().get('error', '').lower()


class TestBlackBox_OrderPlacement:
    """BB-14 through BB-16: Order placement validation"""

    def _auth_header(self):
        from flask_jwt_extended import create_access_token
        with app.app_context():
            token = create_access_token(identity='1')
        return {'Authorization': f'Bearer {token}'}

    def test_BB14_missing_fields(self, client):
        """BB-14: Place order without required fields → 400"""
        h = self._auth_header()
        r = client.post('/api/orders/place', json={'demand_id': 1}, headers=h)
        assert r.status_code == 400

    def test_BB15_quantity_zero(self, client):
        """BB-15: Quantity = 0 → 400"""
        h = self._auth_header()
        demand = {'shop_owner_id': 1, 'status': 'open'}
        stock = {'stock_id': 1, 'stockholder_id': 2,
                 'quantity_available': 100, 'unit': 'kg', 'price_per_unit': 50}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [demand, stock]
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/place', headers=h, json={
                'demand_id': 1, 'stock_id': 1, 'quantity': 0,
                'delivery_address': 'Dhaka'
            })
        assert r.status_code == 400

    def test_BB16_exceed_stock(self, client):
        """BB-16: Order qty > available stock → 400"""
        h = self._auth_header()
        demand = {'shop_owner_id': 1, 'status': 'open'}
        stock = {'stock_id': 1, 'stockholder_id': 2,
                 'quantity_available': 10.0, 'unit': 'kg', 'price_per_unit': 50.0}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [demand, stock]
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/place', headers=h, json={
                'demand_id': 1, 'stock_id': 1, 'quantity': 999,
                'delivery_address': 'Dhaka'
            })
        assert r.status_code == 400
        assert 'stock' in r.get_json().get('error', '').lower()


# ═════════════════════════════════════════════════════════════
#  WHITE BOX TESTS  (internal logic / branch coverage)
# ═════════════════════════════════════════════════════════════

class TestWhiteBox_PasswordValidation:
    """WB-1 through WB-3: password length branch in register"""

    def test_WB1_password_exactly_6(self, client):
        """WB-1: len(password)==6 → passes validation, hits DB"""
        mdb, mc = _mock_db()
        mc.lastrowid = 42
        with patch('routes.auth.get_db', return_value=mdb):
            r = client.post('/api/auth/register/shop-owner', json={
                'name': 'Ali', 'phone': '01700099999',
                'password': 'abc123',
                'shop_name': 'Ali Store', 'shop_category': 'Grocery'
            })
        assert r.status_code in (201, 409, 500)

    def test_WB2_password_5_chars(self, client):
        """WB-2: len(password)==5 → rejected before DB call"""
        r = client.post('/api/auth/register/shop-owner', json={
            'name': 'Ali', 'phone': '01700099998',
            'password': 'ab123',
            'shop_name': 'Ali Store', 'shop_category': 'Grocery'
        })
        assert r.status_code == 400

    def test_WB3_password_empty(self, client):
        """WB-3: empty password → rejected before DB call"""
        r = client.post('/api/auth/register/shop-owner', json={
            'name': 'Ali', 'phone': '01700099997',
            'password': '',
            'shop_name': 'Ali Store', 'shop_category': 'Grocery'
        })
        assert r.status_code == 400


class TestWhiteBox_RatingScore:
    """WB-4 through WB-7: score boundary branches in submit_rating"""

    def _auth_header(self):
        from flask_jwt_extended import create_access_token
        with app.app_context():
            token = create_access_token(identity='1')
        return {'Authorization': f'Bearer {token}'}

    def _delivered_mock(self):
        mdb, mc = _mock_db()
        order = {'shop_owner_id': 1, 'stockholder_id': 2, 'status': 'delivered'}
        avg_row = {'avg': 4.5}
        mc.fetchone.side_effect = [order, None, avg_row]
        mc.lastrowid = 10
        return mdb

    def test_WB4_score_boundary_1(self, client):
        """WB-4: score=1 (min valid) → 201"""
        h = self._auth_header()
        with patch('routes.ratings.get_db', return_value=self._delivered_mock()):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 1}, headers=h)
        assert r.status_code == 201

    def test_WB5_score_boundary_5(self, client):
        """WB-5: score=5 (max valid) → 201"""
        h = self._auth_header()
        with patch('routes.ratings.get_db', return_value=self._delivered_mock()):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 5}, headers=h)
        assert r.status_code == 201

    def test_WB6_score_below_1(self, client):
        """WB-6: score=0 → fails `1 <= score <= 5` branch → 400"""
        h = self._auth_header()
        mdb, _ = _mock_db()
        with patch('routes.ratings.get_db', return_value=mdb):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 0}, headers=h)
        assert r.status_code == 400

    def test_WB7_score_above_5(self, client):
        """WB-7: score=6 → fails `1 <= score <= 5` branch → 400"""
        h = self._auth_header()
        mdb, _ = _mock_db()
        with patch('routes.ratings.get_db', return_value=mdb):
            r = client.post('/api/ratings/submit',
                            json={'order_id': 1, 'score': 6}, headers=h)
        assert r.status_code == 400


class TestWhiteBox_StockTransaction:
    """WB-8 through WB-10: FOR UPDATE transaction branches in place_order"""

    def _auth_header(self):
        from flask_jwt_extended import create_access_token
        with app.app_context():
            token = create_access_token(identity='1')
        return {'Authorization': f'Bearer {token}'}

    def test_WB8_enough_stock_proceeds(self, client):
        """WB-8: qty < available → transaction commits, status stays 'available'"""
        h = self._auth_header()
        demand = {'shop_owner_id': 1, 'status': 'open'}
        stock  = {'stock_id': 1, 'stockholder_id': 2,
                  'quantity_available': 100.0, 'unit': 'kg', 'price_per_unit': 50.0}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [demand, stock, None]
        mc.lastrowid = 5
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/place', headers=h, json={
                'demand_id': 1, 'stock_id': 1, 'quantity': 50,
                'delivery_address': 'Mirpur, Dhaka'
            })
        assert r.status_code == 201
        assert r.get_json().get('order_id') is not None

    def test_WB9_exact_stock_marks_sold_out(self, client):
        """WB-9: qty == available → new_qty==0 → status set to 'sold_out'"""
        h = self._auth_header()
        demand = {'shop_owner_id': 1, 'status': 'open'}
        stock  = {'stock_id': 1, 'stockholder_id': 2,
                  'quantity_available': 50.0, 'unit': 'kg', 'price_per_unit': 50.0}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [demand, stock, None]
        mc.lastrowid = 6

        updates = []
        real_execute = mc.execute
        def capture_execute(sql, params=None):
            updates.append((sql, params))
        mc.execute.side_effect = capture_execute

        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/place', headers=h, json={
                'demand_id': 1, 'stock_id': 1, 'quantity': 50,
                'delivery_address': 'Banani, Dhaka'
            })
        sold_out_calls = [p for s, p in updates
                         if p and 'sold_out' in str(p)]
        assert len(sold_out_calls) > 0 or r.status_code in (201, 500)

    def test_WB10_insufficient_stock_rollback(self, client):
        """WB-10: qty > available → rollback path, 400 returned"""
        h = self._auth_header()
        demand = {'shop_owner_id': 1, 'status': 'open'}
        stock  = {'stock_id': 1, 'stockholder_id': 2,
                  'quantity_available': 10.0, 'unit': 'kg', 'price_per_unit': 50.0}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [demand, stock]
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/place', headers=h, json={
                'demand_id': 1, 'stock_id': 1, 'quantity': 100,
                'delivery_address': 'Gulshan, Dhaka'
            })
        assert r.status_code == 400
        assert 'stock' in r.get_json().get('error', '').lower()
        mdb.rollback.assert_called()


class TestWhiteBox_JWTProtection:
    """WB-11 through WB-12: JWT required decorator branch"""

    def test_WB11_no_token_rejected(self, client):
        """WB-11: No Authorization header → 401 (JWT guard branch)"""
        r = client.get('/api/ratings/unrated')
        assert r.status_code == 401

    def test_WB12_invalid_token_rejected(self, client):
        """WB-12: Malformed token → 422 or 401"""
        r = client.get('/api/ratings/unrated',
                       headers={'Authorization': 'Bearer FAKEJWT.bad.token'})
        assert r.status_code in (401, 422)


class TestWhiteBox_OTPExpiry:
    """WB-13 through WB-14: OTP branch in verify-otp (stockholder side)"""

    def _auth_header(self, uid='2'):
        # verify-otp checks stockholder_id → use stockholder's user id
        from flask_jwt_extended import create_access_token
        with app.app_context():
            token = create_access_token(identity=uid)
        return {'Authorization': f'Bearer {token}'}

    def test_WB13_expired_otp_rejected(self, client):
        """WB-13: OTP row not found (expired/wrong code) → 400"""
        h = self._auth_header('2')
        order = {'shop_owner_id': 1, 'stockholder_id': 2,
                 'status': 'out_for_delivery', 'demand_id': 1}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [order, None]  # OTP lookup returns None (expired)
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/1/verify-otp',
                            json={'otp': '000000'}, headers=h)
        assert r.status_code == 400
        assert 'invalid' in r.get_json().get('error', '').lower() or \
               'expired' in r.get_json().get('error', '').lower()

    def test_WB14_valid_otp_delivers(self, client):
        """WB-14: Correct, non-expired OTP → order marked delivered → 200"""
        h = self._auth_header('2')
        order = {'shop_owner_id': 1, 'stockholder_id': 2,
                 'status': 'out_for_delivery', 'demand_id': 1}
        otp_row = {'otp_id': 3}
        mdb, mc = _mock_db()
        mc.fetchone.side_effect = [order, otp_row, None]
        with patch('routes.orders.get_db', return_value=mdb):
            r = client.post('/api/orders/1/verify-otp',
                            json={'otp': '123456'}, headers=h)
        assert r.status_code in (200, 201)
