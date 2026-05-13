"""
Seed script: 5 stockholders + 5 shop owners with locations, stocks, and demands.
Run: py seed_test_data.py
"""

import bcrypt
from db import get_db

PASSWORD = "123456"
pw_hash = bcrypt.hashpw(PASSWORD.encode(), bcrypt.gensalt()).decode()

# ── Dhaka-area coordinates (all within ~10 km of each other) ─────────────────
STOCKHOLDERS = [
    {
        "name": "Rafiq Rahman",
        "phone": "01700000001",
        "email": "rafiq@test.com",
        "company": "Rahman Traders",
        "warehouse_address": "Block A, Mirpur-10, Dhaka",
        "area": "Mirpur",
        "district": "Dhaka",
        "lat": 23.8069, "lng": 90.3666,
        "specialization": "Grocery",
    },
    {
        "name": "Karim Uddin",
        "phone": "01700000002",
        "email": "karim@test.com",
        "company": "Karim Wholesale",
        "warehouse_address": "Road 7, Dhanmondi, Dhaka",
        "area": "Dhanmondi",
        "district": "Dhaka",
        "lat": 23.7461, "lng": 90.3742,
        "specialization": "Grocery",
    },
    {
        "name": "Hasan Ali",
        "phone": "01700000003",
        "email": "hasan@test.com",
        "company": "Hasan Supplies",
        "warehouse_address": "Gulshan-2 Circle, Dhaka",
        "area": "Gulshan",
        "district": "Dhaka",
        "lat": 23.7925, "lng": 90.4078,
        "specialization": "Pharmacy",
    },
    {
        "name": "Alam Chowdhury",
        "phone": "01700000004",
        "email": "alam@test.com",
        "company": "Alam Distribution",
        "warehouse_address": "Mohammadpur Bus Stand, Dhaka",
        "area": "Mohammadpur",
        "district": "Dhaka",
        "lat": 23.7592, "lng": 90.3573,
        "specialization": "Stationary",
    },
    {
        "name": "Nasir Khan",
        "phone": "01700000005",
        "email": "nasir@test.com",
        "company": "Khan Brothers Store",
        "warehouse_address": "Tejgaon Industrial Area, Dhaka",
        "area": "Tejgaon",
        "district": "Dhaka",
        "lat": 23.7695, "lng": 90.3966,
        "specialization": "Hardware",
    },
]

SHOP_OWNERS = [
    {
        "name": "Ahmed Hossain",
        "phone": "01800000001",
        "email": "ahmed@test.com",
        "shop_name": "Ahmed General Store",
        "shop_category": "Grocery",
        "shop_address": "Mirpur-12, Dhaka",
        "area": "Mirpur",
        "district": "Dhaka",
        "lat": 23.8101, "lng": 90.3681,
    },
    {
        "name": "Fatema Begum",
        "phone": "01800000002",
        "email": "fatema@test.com",
        "shop_name": "Begum Pharmacy",
        "shop_category": "Pharmacy",
        "shop_address": "Dhanmondi-15, Dhaka",
        "area": "Dhanmondi",
        "district": "Dhaka",
        "lat": 23.7490, "lng": 90.3760,
    },
    {
        "name": "Islam Mia",
        "phone": "01800000003",
        "email": "islam@test.com",
        "shop_name": "Islam Grocery",
        "shop_category": "Grocery",
        "shop_address": "Gulshan-1, Dhaka",
        "area": "Gulshan",
        "district": "Dhaka",
        "lat": 23.7908, "lng": 90.4055,
    },
    {
        "name": "Noor Alam",
        "phone": "01800000004",
        "email": "noor@test.com",
        "shop_name": "Noor Stationary",
        "shop_category": "Stationary",
        "shop_address": "Mohammadpur, Dhaka",
        "area": "Mohammadpur",
        "district": "Dhaka",
        "lat": 23.7612, "lng": 90.3590,
    },
    {
        "name": "Salam Molla",
        "phone": "01800000005",
        "email": "salam@test.com",
        "shop_name": "Salam Mart",
        "shop_category": "Grocery",
        "shop_address": "Banani, Dhaka",
        "area": "Banani",
        "district": "Dhaka",
        "lat": 23.7950, "lng": 90.4040,
    },
]


def lookup_product(cursor, product_name):
    cursor.execute("SELECT product_id FROM products WHERE name=%s LIMIT 1", (product_name,))
    row = cursor.fetchone()
    return row[0] if row else None


def lookup_variant(cursor, product_id, variant_name):
    cursor.execute(
        "SELECT variant_id FROM product_variants WHERE product_id=%s AND variant_name=%s LIMIT 1",
        (product_id, variant_name)
    )
    row = cursor.fetchone()
    return row[0] if row else None


def seed():
    db = get_db()
    c = db.cursor()

    print("Seeding test users...")

    stockholder_ids = []
    for s in STOCKHOLDERS:
        # Check if phone already exists
        c.execute("SELECT user_id FROM users WHERE phone=%s", (s["phone"],))
        existing = c.fetchone()
        if existing:
            print(f"  Skip (exists): {s['phone']}")
            stockholder_ids.append(existing[0])
            continue

        c.execute(
            "INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s,%s,%s,%s,'stockholder')",
            (s["name"], s["email"], s["phone"], pw_hash)
        )
        uid = c.lastrowid
        c.execute(
            """INSERT INTO stockholder_profile
               (user_id, company_name, warehouse_address, area, district, lat, lng, specialization, is_verified)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,1)""",
            (uid, s["company"], s["warehouse_address"], s["area"], s["district"],
             s["lat"], s["lng"], s["specialization"])
        )
        stockholder_ids.append(uid)
        print(f"  Created stockholder: {s['phone']} -> user_id={uid}")

    shop_owner_ids = []
    for o in SHOP_OWNERS:
        c.execute("SELECT user_id FROM users WHERE phone=%s", (o["phone"],))
        existing = c.fetchone()
        if existing:
            print(f"  Skip (exists): {o['phone']}")
            shop_owner_ids.append(existing[0])
            continue

        c.execute(
            "INSERT INTO users (name, email, phone, password_hash, role) VALUES (%s,%s,%s,%s,'shop_owner')",
            (o["name"], o["email"], o["phone"], pw_hash)
        )
        uid = c.lastrowid
        c.execute(
            """INSERT INTO shop_owner_profile
               (user_id, shop_name, shop_category, shop_address, area, district, lat, lng, is_verified)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,1)""",
            (uid, o["shop_name"], o["shop_category"], o["shop_address"],
             o["area"], o["district"], o["lat"], o["lng"])
        )
        shop_owner_ids.append(uid)
        print(f"  Created shop owner:  {o['phone']} -> user_id={uid}")

    db.commit()

    # ── Stock posts ──────────────────────────────────────────────────────────
    print("\nCreating stock posts...")

    STOCKS = [
        # (stockholder_idx, product, variant, qty, unit, price, notes)
        (0, "Rice",       "Basmati",  2000, "kg",    85,  "Premium grade, fresh 2024 harvest"),
        (0, "Rice",       "Miniket",  1500, "kg",    72,  "Best quality Miniket rice"),
        (0, "Sugar",      "White",    3000, "kg",    60,  "Refined white sugar"),
        (1, "Oil",        "Soybean",  500,  "litre", 150, "Teer brand soybean oil"),
        (1, "Flour",      "Wheat",    1000, "kg",    55,  "Fresh milled wheat flour"),
        (1, "Dal",        "Masur",    400,  "kg",    95,  "Red lentil, cleaned and packed"),
        (2, "Paracetamol","500mg",    2000, "piece", 5,   "500mg tablets, MFG 2025"),
        (2, "Vitamin",    "C",        500,  "pack",  120, "Vitamin C 250mg, strip of 10"),
        (2, "Antacid",    "Tablet",   300,  "pack",  80,  "Antacid tablets, 20 per strip"),
        (3, "Paper",      "A4 80GSM", 200,  "pack",  450, "500 sheets per ream"),
        (3, "Pen",        "Ball Point",1000,"piece", 8,   "Blue ball point pens"),
        (3, "Notebook",   "100 page", 500,  "piece", 40,  "Spiral notebook 100 pages"),
        (4, "Cement",     "OPC 53",   500,  "pack",  520, "50 kg bag, fresh stock"),
        (4, "Rod",        "10mm",     200,  "piece", 85,  "10mm steel rod per piece"),
        (4, "Paint",      "Wall",     100,  "pack",  380, "Asian paints 4 litre can"),
    ]

    for si, product_name, variant_name, qty, unit, price, notes in STOCKS:
        uid = stockholder_ids[si]
        s_info = STOCKHOLDERS[si]

        pid = lookup_product(c, product_name)
        if not pid:
            print(f"  Product not found: {product_name}")
            continue
        vid = lookup_variant(c, pid, variant_name)
        if not vid:
            print(f"  Variant not found: {product_name} - {variant_name}")
            continue

        c.execute(
            """INSERT INTO stock
               (stockholder_id, product_id, variant_id, quantity_available, unit,
                price_per_unit, warehouse_area, lat, lng, status, additional_notes)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,'available',%s)""",
            (uid, pid, vid, qty, unit, price,
             s_info["area"], s_info["lat"], s_info["lng"], notes)
        )
        print(f"  Stock: {s_info['company']} -> {product_name} ({variant_name}) {qty}{unit} @ BDT{price}")

    # ── Demand posts ─────────────────────────────────────────────────────────
    print("\nCreating demand posts...")

    DEMANDS = [
        # (shop_owner_idx, product, variant, qty, unit, notes)
        (0, "Rice",       "Basmati",  300, "kg",    "Need premium quality for Eid season"),
        (0, "Sugar",      "White",    100, "kg",    "Urgent need"),
        (0, "Oil",        "Soybean",  50,  "litre", "Any brand accepted"),
        (1, "Paracetamol","500mg",    500, "piece", "500mg tablets only"),
        (1, "Vitamin",    "C",        100, "pack",  "Ascorbic acid preferred"),
        (2, "Rice",       "Miniket",  200, "kg",    "Fresh stock only"),
        (2, "Dal",        "Masur",    50,  "kg",    "Red lentil for restaurant supply"),
        (3, "Paper",      "A4 80GSM", 50,  "pack",  "For school, bulk order"),
        (3, "Pen",        "Ball Point",200,"piece", "Blue color only"),
        (4, "Rice",       "Basmati",  500, "kg",    "Regular monthly supply needed"),
        (4, "Flour",      "Wheat",    100, "kg",    "For bakery use"),
    ]

    for oi, product_name, variant_name, qty, unit, notes in DEMANDS:
        uid = shop_owner_ids[oi]
        o_info = SHOP_OWNERS[oi]

        pid = lookup_product(c, product_name)
        if not pid:
            print(f"  Product not found: {product_name}")
            continue
        vid = lookup_variant(c, pid, variant_name)
        if not vid:
            print(f"  Variant not found: {product_name} - {variant_name}")
            continue

        c.execute(
            """INSERT INTO demands
               (shop_owner_id, product_id, variant_id, quantity, unit,
                location_area, lat, lng, additional_notes, status)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,'open')""",
            (uid, pid, vid, qty, unit,
             o_info["area"], o_info["lat"], o_info["lng"], notes)
        )
        print(f"  Demand: {o_info['shop_name']} -> {product_name} ({variant_name}) {qty}{unit}")

    db.commit()
    c.close()
    db.close()

    print("\n" + "="*60)
    print("SEED COMPLETE")
    print("="*60)
    print("\n5 STOCKHOLDER ACCOUNTS")
    print("-"*40)
    for i, s in enumerate(STOCKHOLDERS):
        print(f"  Phone: {s['phone']}  Pass: {PASSWORD}")
        print(f"  Name:  {s['name']} ({s['company']})")
        print(f"  Area:  {s['area']}")
        print()

    print("5 SHOP OWNER ACCOUNTS")
    print("-"*40)
    for i, o in enumerate(SHOP_OWNERS):
        print(f"  Phone: {o['phone']}  Pass: {PASSWORD}")
        print(f"  Name:  {o['name']} ({o['shop_name']})")
        print(f"  Area:  {o['area']}")
        print()


if __name__ == "__main__":
    seed()
