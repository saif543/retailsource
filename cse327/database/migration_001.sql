-- Migration: Update schema to match app designs
-- Run this after schema.sql

USE supplylink;

-- Make email optional (phone is primary identifier now)
ALTER TABLE users MODIFY email VARCHAR(100) NULL;

-- Drop the unique constraint on email, keep unique on phone
ALTER TABLE users DROP INDEX email;
ALTER TABLE users ADD UNIQUE INDEX email_unique (email);

-- Stockholder can select multiple product categories (checkboxes in design)
CREATE TABLE IF NOT EXISTS stockholder_categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    stockholder_id INT NOT NULL,
    category_id INT NOT NULL,
    FOREIGN KEY (stockholder_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES product_categories(category_id) ON DELETE CASCADE,
    UNIQUE KEY unique_stockholder_category (stockholder_id, category_id)
);
