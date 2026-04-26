-- SupplyLink Database Schema
-- Run this file to create all tables

CREATE DATABASE IF NOT EXISTS supplylink;
USE supplylink;

-- Users table (all roles)
CREATE TABLE IF NOT EXISTS users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('shop_owner', 'stockholder', 'admin') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Shop owner profile
CREATE TABLE IF NOT EXISTS shop_owner_profile (
    profile_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    shop_name VARCHAR(100),
    shop_category ENUM('Grocery', 'Pharmacy', 'Stationary', 'Hardware'),
    shop_address TEXT,
    area VARCHAR(100),
    district VARCHAR(100),
    lat DECIMAL(10,8),
    lng DECIMAL(11,8),
    is_verified BOOLEAN DEFAULT FALSE,
    rating_avg DECIMAL(3,2) DEFAULT 0.00,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Stockholder profile
CREATE TABLE IF NOT EXISTS stockholder_profile (
    profile_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    company_name VARCHAR(100),
    warehouse_address TEXT,
    area VARCHAR(100),
    district VARCHAR(100),
    lat DECIMAL(10,8),
    lng DECIMAL(11,8),
    is_verified BOOLEAN DEFAULT FALSE,
    rating_avg DECIMAL(3,2) DEFAULT 0.00,
    specialization VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Product categories
CREATE TABLE IF NOT EXISTS product_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name ENUM('Grocery', 'Pharmacy', 'Stationary', 'Hardware') NOT NULL
);

-- Products
CREATE TABLE IF NOT EXISTS products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    category_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE
);

-- Product variants
CREATE TABLE IF NOT EXISTS product_variants (
    variant_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    variant_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE
);

-- Stock listings
CREATE TABLE IF NOT EXISTS stock (
    stock_id INT PRIMARY KEY AUTO_INCREMENT,
    stockholder_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity_available DECIMAL(10,2) NOT NULL,
    unit ENUM('kg', 'litre', 'piece', 'pack') NOT NULL,
    price_per_unit DECIMAL(10,2) NOT NULL,
    warehouse_area VARCHAR(100),
    lat DECIMAL(10,8),
    lng DECIMAL(11,8),
    status ENUM('available', 'sold_out') DEFAULT 'available',
    additional_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (stockholder_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

-- Demands
CREATE TABLE IF NOT EXISTS demands (
    demand_id INT PRIMARY KEY AUTO_INCREMENT,
    shop_owner_id INT NOT NULL,
    product_id INT NOT NULL,
    variant_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit ENUM('kg', 'litre', 'piece', 'pack') NOT NULL,
    location_area VARCHAR(100),
    lat DECIMAL(10,8),
    lng DECIMAL(11,8),
    additional_notes TEXT,
    status ENUM('open', 'matched', 'fulfilled') DEFAULT 'open',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_owner_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    demand_id INT NOT NULL,
    stock_id INT NOT NULL,
    shop_owner_id INT NOT NULL,
    stockholder_id INT NOT NULL,
    quantity DECIMAL(10,2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    price_per_unit DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    delivery_address TEXT,
    delivery_lat DECIMAL(10,8),
    delivery_lng DECIMAL(11,8),
    status ENUM('pending', 'accepted', 'declined', 'out_for_delivery', 'delivered') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    accepted_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    FOREIGN KEY (demand_id) REFERENCES demands(demand_id),
    FOREIGN KEY (stock_id) REFERENCES stock(stock_id),
    FOREIGN KEY (shop_owner_id) REFERENCES users(user_id),
    FOREIGN KEY (stockholder_id) REFERENCES users(user_id)
);

-- OTP codes
CREATE TABLE IF NOT EXISTS otp_codes (
    otp_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    code VARCHAR(6) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
);

-- Ratings
CREATE TABLE IF NOT EXISTS ratings (
    rating_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    given_by INT NOT NULL,
    given_to INT NOT NULL,
    score INT NOT NULL CHECK (score BETWEEN 1 AND 5),
    review TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (given_by) REFERENCES users(user_id),
    FOREIGN KEY (given_to) REFERENCES users(user_id)
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    notif_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    type ENUM('new_match', 'new_order', 'order_accepted', 'order_declined', 'otp_sent', 'delivery_confirmed', 'rating_received', 'stock_alert') NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    related_order_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
