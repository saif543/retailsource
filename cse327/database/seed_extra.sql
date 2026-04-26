-- Extra products for Bangladesh shops
USE supplylink;

-- =====================
-- GROCERY (category_id = 1)
-- =====================
INSERT INTO products (category_id, name) VALUES
(1, 'Salt'),
(1, 'Spices'),
(1, 'Tea'),
(1, 'Milk Powder'),
(1, 'Biscuit'),
(1, 'Noodles'),
(1, 'Soap'),
(1, 'Detergent'),
(1, 'Shampoo'),
(1, 'Toothpaste'),
(1, 'Edible Oil'),
(1, 'Ghee'),
(1, 'Honey'),
(1, 'Puffed Rice (Muri)'),
(1, 'Flattened Rice (Chira)'),
(1, 'Vermicelli (Semai)'),
(1, 'Dates (Khejur)'),
(1, 'Onion'),
(1, 'Garlic'),
(1, 'Ginger'),
(1, 'Potato'),
(1, 'Egg'),
(1, 'Bread'),
(1, 'Butter'),
(1, 'Jam'),
(1, 'Sauce'),
(1, 'Vinegar'),
(1, 'Condensed Milk'),
(1, 'Coconut Oil'),
(1, 'Dry Fish (Shutki)');

-- Salt variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Iodized' AS variant UNION SELECT 'Rock Salt' UNION SELECT 'Powder' UNION SELECT 'Other') v
WHERE p.name = 'Salt' AND p.category_id = 1;

-- Spices variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Turmeric (Holud)' AS variant UNION SELECT 'Chili Powder' UNION SELECT 'Cumin (Jeera)' UNION SELECT 'Coriander (Dhonia)' UNION SELECT 'Garam Masala' UNION SELECT 'Black Pepper' UNION SELECT 'Cinnamon (Daruchini)' UNION SELECT 'Cardamom (Elaichi)' UNION SELECT 'Bay Leaf (Tejpata)' UNION SELECT 'Other') v
WHERE p.name = 'Spices' AND p.category_id = 1;

-- Tea variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Ispahani' AS variant UNION SELECT 'Lipton' UNION SELECT 'Taaza' UNION SELECT 'National' UNION SELECT 'Kazi & Kazi' UNION SELECT 'Green Tea' UNION SELECT 'Other') v
WHERE p.name = 'Tea' AND p.category_id = 1;

-- Milk Powder variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Dano' AS variant UNION SELECT 'Diploma' UNION SELECT 'Marks' UNION SELECT 'Nido' UNION SELECT 'Other') v
WHERE p.name = 'Milk Powder' AND p.category_id = 1;

-- Biscuit variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Olympic' AS variant UNION SELECT 'Haque' UNION SELECT 'Danish' UNION SELECT 'Nabisco' UNION SELECT 'Cream' UNION SELECT 'Other') v
WHERE p.name = 'Biscuit' AND p.category_id = 1;

-- Noodles variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Maggi' AS variant UNION SELECT 'Mr. Noodles' UNION SELECT 'Cocola' UNION SELECT 'Doodles' UNION SELECT 'Other') v
WHERE p.name = 'Noodles' AND p.category_id = 1;

-- Soap variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Lux' AS variant UNION SELECT 'Lifebuoy' UNION SELECT 'Dettol' UNION SELECT 'Keya' UNION SELECT 'Other') v
WHERE p.name = 'Soap' AND p.category_id = 1;

-- Detergent variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Wheel' AS variant UNION SELECT 'Surf Excel' UNION SELECT 'RIN' UNION SELECT 'Jet' UNION SELECT 'Other') v
WHERE p.name = 'Detergent' AND p.category_id = 1;

-- Shampoo variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Sunsilk' AS variant UNION SELECT 'Dove' UNION SELECT 'Clear' UNION SELECT 'Clinic Plus' UNION SELECT 'Other') v
WHERE p.name = 'Shampoo' AND p.category_id = 1;

-- Toothpaste variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Closeup' AS variant UNION SELECT 'Pepsodent' UNION SELECT 'Colgate' UNION SELECT 'Sensodyne' UNION SELECT 'Other') v
WHERE p.name = 'Toothpaste' AND p.category_id = 1;

-- Edible Oil variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Radhuni Soybean' AS variant UNION SELECT 'Teer Soybean' UNION SELECT 'Rupchanda' UNION SELECT 'Fresh' UNION SELECT 'Other') v
WHERE p.name = 'Edible Oil' AND p.category_id = 1;

-- Ghee variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Pure Ghee' AS variant UNION SELECT 'Banaspati' UNION SELECT 'Aarong' UNION SELECT 'Other') v
WHERE p.name = 'Ghee' AND p.category_id = 1;

-- Honey variants
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Sundarbani' AS variant UNION SELECT 'Litchi Flower' UNION SELECT 'Mustard Flower' UNION SELECT 'Other') v
WHERE p.name = 'Honey' AND p.category_id = 1;

-- Simple variants for remaining grocery items
INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Regular' AS variant UNION SELECT 'Premium' UNION SELECT 'Other') v
WHERE p.name IN ('Puffed Rice (Muri)', 'Flattened Rice (Chira)', 'Vermicelli (Semai)', 'Dates (Khejur)', 'Dry Fish (Shutki)') AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Local' AS variant UNION SELECT 'Imported' UNION SELECT 'Other') v
WHERE p.name IN ('Onion', 'Garlic', 'Ginger', 'Potato') AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Farm' AS variant UNION SELECT 'Desi' UNION SELECT 'Other') v
WHERE p.name = 'Egg' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'White' AS variant UNION SELECT 'Brown' UNION SELECT 'Other') v
WHERE p.name = 'Bread' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Salted' AS variant UNION SELECT 'Unsalted' UNION SELECT 'Other') v
WHERE p.name = 'Butter' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Strawberry' AS variant UNION SELECT 'Mixed Fruit' UNION SELECT 'Orange' UNION SELECT 'Other') v
WHERE p.name = 'Jam' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Tomato' AS variant UNION SELECT 'Chili' UNION SELECT 'Soy' UNION SELECT 'Other') v
WHERE p.name = 'Sauce' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'White' AS variant UNION SELECT 'Apple Cider' UNION SELECT 'Other') v
WHERE p.name = 'Vinegar' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Marks' AS variant UNION SELECT 'Denmark' UNION SELECT 'Other') v
WHERE p.name = 'Condensed Milk' AND p.category_id = 1;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Parachute' AS variant UNION SELECT 'Local' UNION SELECT 'Other') v
WHERE p.name = 'Coconut Oil' AND p.category_id = 1;

-- =====================
-- PHARMACY (category_id = 2)
-- =====================
INSERT INTO products (category_id, name) VALUES
(2, 'Antibiotics'),
(2, 'Omeprazole'),
(2, 'Metformin'),
(2, 'Insulin'),
(2, 'Bandage'),
(2, 'Cotton'),
(2, 'Thermometer'),
(2, 'Blood Pressure Monitor'),
(2, 'Mask'),
(2, 'Hand Sanitizer'),
(2, 'Eye Drops'),
(2, 'Ear Drops'),
(2, 'Pain Balm'),
(2, 'Calcium Tablet'),
(2, 'Iron Tablet');

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Amoxicillin' AS variant UNION SELECT 'Azithromycin' UNION SELECT 'Ciprofloxacin' UNION SELECT 'Other') v
WHERE p.name = 'Antibiotics' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '20mg' AS variant UNION SELECT '40mg' UNION SELECT 'Other') v
WHERE p.name = 'Omeprazole' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '500mg' AS variant UNION SELECT '850mg' UNION SELECT '1000mg' UNION SELECT 'Other') v
WHERE p.name = 'Metformin' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Regular' AS variant UNION SELECT 'Pen' UNION SELECT 'Other') v
WHERE p.name = 'Insulin' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Regular' AS variant UNION SELECT 'Crepe' UNION SELECT 'Elastic' UNION SELECT 'Other') v
WHERE p.name = 'Bandage' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Roll' AS variant UNION SELECT 'Ball' UNION SELECT 'Other') v
WHERE p.name = 'Cotton' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Digital' AS variant UNION SELECT 'Mercury' UNION SELECT 'Infrared' UNION SELECT 'Other') v
WHERE p.name IN ('Thermometer') AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Digital' AS variant UNION SELECT 'Manual' UNION SELECT 'Other') v
WHERE p.name = 'Blood Pressure Monitor' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Surgical' AS variant UNION SELECT 'N95' UNION SELECT 'Cloth' UNION SELECT 'Other') v
WHERE p.name = 'Mask' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '100ml' AS variant UNION SELECT '250ml' UNION SELECT '500ml' UNION SELECT 'Other') v
WHERE p.name = 'Hand Sanitizer' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Regular' AS variant UNION SELECT 'Antibiotic' UNION SELECT 'Other') v
WHERE p.name IN ('Eye Drops', 'Ear Drops') AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Tiger Balm' AS variant UNION SELECT 'Zandu' UNION SELECT 'Other') v
WHERE p.name = 'Pain Balm' AND p.category_id = 2;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '500mg' AS variant UNION SELECT '1000mg' UNION SELECT 'Other') v
WHERE p.name IN ('Calcium Tablet', 'Iron Tablet') AND p.category_id = 2;

-- =====================
-- STATIONARY (category_id = 3)
-- =====================
INSERT INTO products (category_id, name) VALUES
(3, 'Eraser'),
(3, 'Sharpener'),
(3, 'Ruler'),
(3, 'Glue'),
(3, 'Tape'),
(3, 'Stapler'),
(3, 'File Folder'),
(3, 'Marker'),
(3, 'Color Pencil'),
(3, 'Crayon'),
(3, 'Calculator'),
(3, 'Geometry Box'),
(3, 'Drawing Paper'),
(3, 'Envelope'),
(3, 'Whiteboard Marker');

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Small' AS variant UNION SELECT 'Large' UNION SELECT 'Other') v
WHERE p.name IN ('Eraser', 'Sharpener', 'Ruler') AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Stick' AS variant UNION SELECT 'Liquid' UNION SELECT 'Fevicol' UNION SELECT 'Other') v
WHERE p.name = 'Glue' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Scotch' AS variant UNION SELECT 'Masking' UNION SELECT 'Packing' UNION SELECT 'Other') v
WHERE p.name = 'Tape' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Mini' AS variant UNION SELECT 'Full Size' UNION SELECT 'Other') v
WHERE p.name = 'Stapler' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Plastic' AS variant UNION SELECT 'Cardboard' UNION SELECT 'Ring Binder' UNION SELECT 'Other') v
WHERE p.name = 'File Folder' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Permanent' AS variant UNION SELECT 'Highlighter' UNION SELECT 'Other') v
WHERE p.name = 'Marker' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '12 pcs' AS variant UNION SELECT '24 pcs' UNION SELECT 'Other') v
WHERE p.name IN ('Color Pencil', 'Crayon') AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Scientific' AS variant UNION SELECT 'Basic' UNION SELECT 'Other') v
WHERE p.name = 'Calculator' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Standard' AS variant UNION SELECT 'Premium' UNION SELECT 'Other') v
WHERE p.name = 'Geometry Box' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'A3' AS variant UNION SELECT 'A4' UNION SELECT 'Other') v
WHERE p.name = 'Drawing Paper' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'White' AS variant UNION SELECT 'Brown' UNION SELECT 'Other') v
WHERE p.name = 'Envelope' AND p.category_id = 3;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Black' AS variant UNION SELECT 'Blue' UNION SELECT 'Red' UNION SELECT 'Other') v
WHERE p.name = 'Whiteboard Marker' AND p.category_id = 3;

-- =====================
-- HARDWARE (category_id = 4)
-- =====================
INSERT INTO products (category_id, name) VALUES
(4, 'Brick'),
(4, 'Sand'),
(4, 'Tile'),
(4, 'Wire'),
(4, 'Switch'),
(4, 'Socket'),
(4, 'Pipe'),
(4, 'Nail'),
(4, 'Hammer'),
(4, 'Drill Bit'),
(4, 'Plywood'),
(4, 'Glass'),
(4, 'Lock'),
(4, 'Hinge'),
(4, 'Bulb');

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'First Class' AS variant UNION SELECT 'Second Class' UNION SELECT 'Hollow' UNION SELECT 'Other') v
WHERE p.name = 'Brick' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Sylhet Sand' AS variant UNION SELECT 'Local Sand' UNION SELECT 'Coarse' UNION SELECT 'Other') v
WHERE p.name = 'Sand' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Floor' AS variant UNION SELECT 'Wall' UNION SELECT 'Bathroom' UNION SELECT 'Other') v
WHERE p.name = 'Tile' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '1mm' AS variant UNION SELECT '1.5mm' UNION SELECT '2.5mm' UNION SELECT '4mm' UNION SELECT 'Other') v
WHERE p.name = 'Wire' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'One Way' AS variant UNION SELECT 'Two Way' UNION SELECT 'Other') v
WHERE p.name = 'Switch' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '2 Pin' AS variant UNION SELECT '3 Pin' UNION SELECT 'Multi Plug' UNION SELECT 'Other') v
WHERE p.name = 'Socket' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'PVC' AS variant UNION SELECT 'GI' UNION SELECT 'CPVC' UNION SELECT 'Other') v
WHERE p.name = 'Pipe' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '1 inch' AS variant UNION SELECT '2 inch' UNION SELECT '3 inch' UNION SELECT 'Other') v
WHERE p.name = 'Nail' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Claw' AS variant UNION SELECT 'Ball Peen' UNION SELECT 'Other') v
WHERE p.name = 'Hammer' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '6mm' AS variant UNION SELECT '8mm' UNION SELECT '10mm' UNION SELECT 'Other') v
WHERE p.name = 'Drill Bit' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '12mm' AS variant UNION SELECT '18mm' UNION SELECT 'Other') v
WHERE p.name = 'Plywood' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Clear' AS variant UNION SELECT 'Tinted' UNION SELECT 'Frosted' UNION SELECT 'Other') v
WHERE p.name = 'Glass' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'Padlock' AS variant UNION SELECT 'Door Lock' UNION SELECT 'Digital' UNION SELECT 'Other') v
WHERE p.name = 'Lock' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT '3 inch' AS variant UNION SELECT '4 inch' UNION SELECT 'Other') v
WHERE p.name = 'Hinge' AND p.category_id = 4;

INSERT INTO product_variants (product_id, variant_name)
SELECT product_id, v.variant FROM products p
CROSS JOIN (SELECT 'LED' AS variant UNION SELECT 'CFL' UNION SELECT 'Filament' UNION SELECT 'Other') v
WHERE p.name = 'Bulb' AND p.category_id = 4;
