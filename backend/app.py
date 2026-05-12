from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import JWT_SECRET_KEY
from routes.auth import auth_bp
from routes.profile import profile_bp
from routes.products import products_bp
from routes.demands import demands_bp
from routes.shop_dashboard import shop_dashboard_bp
<<<<<<< Updated upstream
from routes.orders import orders_bp
from routes.stocks import stocks_bp
from routes.notifications import notifications_bp
from routes.ratings import ratings_bp
from routes.earnings import earnings_bp
from routes.admin import admin_bp
=======
>>>>>>> Stashed changes

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = JWT_SECRET_KEY

CORS(app)
jwt = JWTManager(app)

# Register blueprints
<<<<<<< Updated upstream
app.register_blueprint(auth_bp,            url_prefix='/api/auth')
app.register_blueprint(profile_bp,         url_prefix='/api/profile')
app.register_blueprint(products_bp,        url_prefix='/api/products')
app.register_blueprint(demands_bp,         url_prefix='/api/demands')
app.register_blueprint(shop_dashboard_bp,  url_prefix='/api/shop')
app.register_blueprint(orders_bp,          url_prefix='/api/orders')
app.register_blueprint(stocks_bp,          url_prefix='/api/stocks')
app.register_blueprint(notifications_bp,   url_prefix='/api/notifications')
app.register_blueprint(ratings_bp,         url_prefix='/api/ratings')
app.register_blueprint(earnings_bp,        url_prefix='/api/earnings')
app.register_blueprint(admin_bp,           url_prefix='/api/admin')
=======
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(profile_bp, url_prefix='/api/profile')
app.register_blueprint(products_bp, url_prefix='/api/products')
app.register_blueprint(demands_bp, url_prefix='/api/demands')
app.register_blueprint(shop_dashboard_bp, url_prefix='/api/shop')
>>>>>>> Stashed changes


@app.route('/')
def index():
    return {'message': 'SupplyLink API is running'}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
