# Retail Sourcing and Supply Coordination System
## Project Context for Claude CLI

---

## WHAT THIS PROJECT IS

A mobile app that connects small shop owners directly with 
product suppliers/stockholders in Bangladesh — removing middlemen.
Shop owners post demands, stockholders post stock, system 
auto-matches by product + location. Order placed, stockholder 
accepts, delivers, OTP confirms delivery, rating given.

App Name: RetailSource (or RetailConnect)
Platform: Flutter (Android first)
Backend: Flask REST API (Python)
Database: MySQL
Auth: JWT tokens + OTP via SMS (SSL Wireless or Twilio)

---

## THREE USER ROLES

1. ShopOwner — posts demands, orders, confirms via OTP, rates
2. Stockholder — posts stock, accepts/declines orders, delivers
3. Admin — manages users and product listings

---

## DATABASE SCHEMA

### users
- user_id (PK, AUTO_INCREMENT)
- name VARCHAR(100)
- email VARCHAR(100) UNIQUE
- phone VARCHAR(20) UNIQUE
- password_hash VARCHAR(255)
- role ENUM('shop_owner', 'stockholder', 'admin')
- created_at TIMESTAMP

### shop_owner_profile
- profile_id (PK)
- user_id (FK → users)
- shop_name VARCHAR(100)
- shop_category ENUM('Grocery','Pharmacy','Stationary','Hardware')
- shop_address TEXT
- area VARCHAR(100)
- district VARCHAR(100)
- lat DECIMAL(10,8)
- lng DECIMAL(11,8)
- is_verified BOOLEAN DEFAULT FALSE
- rating_avg DECIMAL(3,2) DEFAULT 0.00

### stockholder_profile
- profile_id (PK)
- user_id (FK → users)
- company_name VARCHAR(100)
- warehouse_address TEXT
- area VARCHAR(100)
- district VARCHAR(100)
- lat DECIMAL(10,8)
- lng DECIMAL(11,8)
- is_verified BOOLEAN DEFAULT FALSE
- rating_avg DECIMAL(3,2) DEFAULT 0.00
- specialization VARCHAR(100)

### product_categories
- category_id (PK)
- name ENUM('Grocery','Pharmacy','Stationary','Hardware')

### products
- product_id (PK)
- category_id (FK → product_categories)
- name VARCHAR(100)

### product_variants
- variant_id (PK)
- product_id (FK → products)
- variant_name VARCHAR(100)
-- Example: Rice → Basmati, Miniket, Chinigura, Coarse, Atap
-- Always include variant_name = 'Other' for each product

### stock
- stock_id (PK)
- stockholder_id (FK → users)
- product_id (FK → products)
- variant_id (FK → product_variants)
- quantity_available DECIMAL(10,2)
- unit ENUM('kg','litre','piece','pack')
- price_per_unit DECIMAL(10,2)
- warehouse_area VARCHAR(100)
- lat DECIMAL(10,8)
- lng DECIMAL(11,8)
- status ENUM('available','sold_out') DEFAULT 'available'
- additional_notes TEXT
- created_at TIMESTAMP
- updated_at TIMESTAMP

### demands
- demand_id (PK)
- shop_owner_id (FK → users)
- product_id (FK → products)
- variant_id (FK → product_variants)
- quantity DECIMAL(10,2)
- unit ENUM('kg','litre','piece','pack')
- location_area VARCHAR(100)
- lat DECIMAL(10,8)
- lng DECIMAL(11,8)
- additional_notes TEXT
- status ENUM('open','matched','fulfilled') DEFAULT 'open'
- created_at TIMESTAMP

### orders
- order_id (PK)
- demand_id (FK → demands)
- stock_id (FK → stock)
- shop_owner_id (FK → users)
- stockholder_id (FK → users)
- quantity DECIMAL(10,2)
- unit VARCHAR(20)
- price_per_unit DECIMAL(10,2)
- total_price DECIMAL(10,2)
- delivery_address TEXT
- delivery_lat DECIMAL(10,8)
- delivery_lng DECIMAL(11,8)
- status ENUM('pending','accepted','declined',
             'out_for_delivery','delivered') DEFAULT 'pending'
- created_at TIMESTAMP
- accepted_at TIMESTAMP NULL
- delivered_at TIMESTAMP NULL

### otp_codes
- otp_id (PK)
- order_id (FK → orders)
- code VARCHAR(6)
- is_verified BOOLEAN DEFAULT FALSE
- expires_at TIMESTAMP
- created_at TIMESTAMP

### ratings
- rating_id (PK)
- order_id (FK → orders)
- given_by (FK → users) -- shop_owner
- given_to (FK → users) -- stockholder
- score INT CHECK(score BETWEEN 1 AND 5)
- review TEXT
- created_at TIMESTAMP

### notifications
- notif_id (PK)
- user_id (FK → users)
- type ENUM('new_match','new_order','order_accepted',
           'order_declined','otp_sent','delivery_confirmed',
           'rating_received','stock_alert')
- message TEXT
- is_read BOOLEAN DEFAULT FALSE
- related_order_id INT NULL
- created_at TIMESTAMP

---

## FLASK API ENDPOINTS

### AUTH
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/verify-otp
POST   /api/auth/resend-otp

### SHOP OWNER
GET    /api/shop/dashboard
POST   /api/demands/create
GET    /api/demands/my
GET    /api/demands/{id}/matches
POST   /api/orders/place
GET    /api/orders/my
GET    /api/orders/{id}/status
POST   /api/orders/{id}/confirm-otp
POST   /api/ratings/submit

### STOCKHOLDER
GET    /api/stock/dashboard
POST   /api/stock/create
GET    /api/stock/my
PUT    /api/stock/{id}/update
DELETE /api/stock/{id}/delete
GET    /api/stock/nearby-demands
GET    /api/orders/incoming
POST   /api/orders/{id}/accept
POST   /api/orders/{id}/decline
POST   /api/orders/{id}/mark-delivered
POST   /api/orders/{id}/verify-otp

### SHARED
GET    /api/notifications
PUT    /api/notifications/mark-read
GET    /api/profile
PUT    /api/profile/update
GET    /api/products/categories
GET    /api/products/{category_id}/products
GET    /api/products/{product_id}/variants

### MATCHING (auto, called internally)
GET    /api/match/find?product_id=X&variant_id=Y&lat=A&lng=B&quantity=Z

---

## CORE BUSINESS LOGIC

### Auto-Matching SQL Query
SELECT s.*, u.name, sp.company_name, sp.rating_avg,
  (6371 * acos(cos(radians(:shop_lat))
  * cos(radians(s.lat))
  * cos(radians(s.lng) - radians(:shop_lng))
  + sin(radians(:shop_lat)) * sin(radians(s.lat)))) AS distance
FROM stock s
JOIN users u ON s.stockholder_id = u.user_id
JOIN stockholder_profile sp ON s.stockholder_id = sp.user_id
WHERE s.product_id = :product_id
AND s.variant_id = :variant_id
AND s.status = 'available'
AND s.quantity_available >= :quantity
HAVING distance <= 10
ORDER BY distance ASC, s.price_per_unit ASC

### Stock Update on Order (with transaction + row lock)
BEGIN TRANSACTION
SELECT quantity_available FROM stock 
WHERE stock_id = :id FOR UPDATE

IF quantity_available >= order_quantity:
    UPDATE stock SET 
      quantity_available = quantity_available - order_quantity,
      status = IF(quantity_available - order_quantity = 0, 
                  'sold_out', 'available')
    WHERE stock_id = :id
    INSERT INTO orders (...)
    COMMIT
ELSE:
    ROLLBACK
    RETURN error "Not enough stock available"

### OTP Generation
import random, datetime
otp_code = str(random.randint(100000, 999999))
expires_at = datetime.now() + timedelta(minutes=10)
-- Save to otp_codes table
-- Send via SMS API to shop owner phone
-- For demo: return OTP in response (skip real SMS)

### OTP Verification
SELECT * FROM otp_codes 
WHERE order_id = :order_id 
AND code = :entered_code
AND is_verified = FALSE
AND expires_at > NOW()

IF found:
    UPDATE otp_codes SET is_verified = TRUE
    UPDATE orders SET status = 'delivered'
    -- trigger rating screen notification
ELSE:
    RETURN error "Invalid or expired OTP"

### Location Privacy Rule
-- In GET /api/orders/incoming (stockholder view)
IF order.status == 'pending':
    response.delivery_address = None
    response.delivery_lat = None
    response.delivery_lng = None
    response.location_note = "Location revealed after acceptance"
ELSE:  -- accepted or later
    response.delivery_address = order.delivery_address
    -- full address shown

---

## FLUTTER APP STRUCTURE

lib/
├── main.dart
├── config/
│   ├── api_config.dart      # base URL, endpoints
│   └── app_colors.dart      # color constants
├── models/
│   ├── user_model.dart
│   ├── demand_model.dart
│   ├── stock_model.dart
│   ├── order_model.dart
│   └── notification_model.dart
├── services/
│   ├── auth_service.dart
│   ├── demand_service.dart
│   ├── stock_service.dart
│   ├── order_service.dart
│   └── notification_service.dart
├── screens/
│   ├── auth/
│   │   ├── welcome_screen.dart
│   │   ├── login_screen.dart
│   │   ├── shop_register_screen.dart
│   │   └── stock_register_screen.dart
│   ├── shop_owner/
│   │   ├── dashboard_screen.dart
│   │   ├── post_demand_screen.dart
│   │   ├── matching_suppliers_screen.dart
│   │   ├── supplier_detail_screen.dart
│   │   ├── order_confirm_screen.dart
│   │   ├── order_status_screen.dart
│   │   ├── my_demands_screen.dart
│   │   └── rate_supplier_screen.dart
│   ├── stockholder/
│   │   ├── dashboard_screen.dart
│   │   ├── post_stock_screen.dart
│   │   ├── my_stock_screen.dart
│   │   ├── order_inbox_screen.dart
│   │   ├── order_detail_screen.dart
│   │   └── nearby_demands_screen.dart
│   └── shared/
│       ├── notifications_screen.dart
│       └── profile_screen.dart
└── widgets/
    ├── supplier_card.dart
    ├── demand_card.dart
    ├── order_card.dart
    ├── otp_input_widget.dart
    └── bottom_nav_bar.dart

---

## COLOR CONSTANTS

PRIMARY_BLUE   = #1565C0   (main color, headers, buttons)
PRIMARY_GREEN  = #2E7D32   (positive actions, stockholder)
ACCENT_ORANGE  = #E65100   (warnings, system events)
ERROR_RED      = #C62828   (errors, decline)
BG_WHITE       = #FFFFFF
CARD_GREY      = #F5F5F5
TEXT_DARK      = #212121
TEXT_GREY      = #757575

---

## KEY FEATURES TO IMPLEMENT

1. JWT Authentication with role-based access
2. GPS location detection (geolocator flutter package)
3. Auto-matching with haversine distance formula
4. Stock quantity management with race condition prevention
5. Location privacy (hide address until order accepted)
6. OTP generation and verification (10 min expiry)
7. Push notifications (Firebase Cloud Messaging)
8. 5-star rating system with average calculation
9. Order status progression tracking
10. Partial stock ordering (400kg stock, order 200kg → 200kg remains)

---

## PRODUCT SEED DATA (for MySQL)

Categories: Grocery, Pharmacy, Stationary, Hardware

Grocery products:
Rice → Basmati, Miniket, Chinigura, Coarse, Atap, Other
Sugar → White, Brown, Other
Oil → Soybean, Mustard, Palm, Other
Flour → Wheat, Rice, Corn, Other
Dal → Masur, Mung, Chana, Motor, Other

Pharmacy products:
Paracetamol → 500mg, 250mg, Other
Antacid → Tablet, Syrup, Other
Vitamin → C, D, B12, Other
Saline → Normal, Other
Cough Syrup → Herbal, Other

Stationary products:
Paper → A4 80GSM, A4 70GSM, Legal, Other
Pen → Ball Point, Gel, Other
Notebook → 100 page, 200 page, Other
Pencil → HB, 2B, Other

Hardware products:
Cement → OPC 53, OPC 43, PPC, Other
Rod → 10mm, 12mm, 16mm, Other
Paint → Wall, Wood, Other
Screw → M4, M6, M8, Other

---

## DEMO CREDENTIALS (for testing)

Shop Owner:
  phone: 01711111111
  password: demo1234

Stockholder:
  phone: 01722222222
  password: demo1234

Admin:
  phone: 01733333333
  password: demo1234

---

## WHAT NOT TO BUILD (out of scope)

- No in-app chat or messaging
- No Contact button anywhere
- No WhatsApp/phone button in app
- No payment gateway (cash on delivery only)
- No stockholder sending requests to shop owners
- No delivery tracking on map (just status updates)

---

## INSTRUCTION FOR CLAUDE CLI

When I ask you to build something for this project:
1. Always use Flask for backend, Flutter for frontend
2. Always use MySQL with the schema above
3. Always implement JWT auth check on protected routes
4. For matching — always use haversine formula with 10km radius
5. For stock updates — always use database transactions with FOR UPDATE lock
6. For location — always hide address when order status is 'pending'
7. For OTP — 6 digits, 10 minute expiry, verify against database
8. Follow the folder structure above for Flutter
9. Use the color constants above for all UI
10. Bangladesh context — use ৳ for currency, +880 for phone format