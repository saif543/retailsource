-- Migration 002: Simplify registration. Address fields become optional;
-- shop owners/stockholders add address later when posting demand/stock.

USE supplylink;

ALTER TABLE shop_owner_profile MODIFY shop_address TEXT NULL;
ALTER TABLE shop_owner_profile MODIFY area VARCHAR(100) NULL;
ALTER TABLE shop_owner_profile MODIFY district VARCHAR(100) NULL;

ALTER TABLE stockholder_profile MODIFY warehouse_address TEXT NULL;
ALTER TABLE stockholder_profile MODIFY area VARCHAR(100) NULL;
ALTER TABLE stockholder_profile MODIFY district VARCHAR(100) NULL;
