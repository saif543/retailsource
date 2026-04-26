from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import JWT_SECRET_KEY
from routes.auth import auth_bp
from routes.profile import profile_bp

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = JWT_SECRET_KEY

CORS(app)
jwt = JWTManager(app)

# Register blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(profile_bp, url_prefix='/api/profile')


@app.route('/')
def index():
    return {'message': 'SupplyLink API is running'}


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
