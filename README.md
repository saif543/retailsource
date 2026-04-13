# SupplyLink - Retail Sourcing and Supply Coordination System

A mobile app connecting small shop owners with product suppliers in Bangladesh.

---

## For Team Members — Setup Guide (Step by Step)

### Step 1: Install Required Software

Download and install these (all free):

1. **Git** — https://git-scm.com/downloads
2. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows/mobile
3. **Python** (3.10 or above) — https://www.python.org/downloads/ (check "Add to PATH" during install)
4. **XAMPP** — https://www.apachefriends.org/ (we only need MySQL from this)
5. **Android Studio** — https://developer.android.com/studio (for Android emulator)
6. **VS Code** — https://code.visualstudio.com/ (code editor)

VS Code extensions to install:
- Flutter
- Dart
- Python

---

### Step 2: Clone the Project

Open terminal (Command Prompt or Git Bash) and run:

```bash
git clone https://github.com/saif543/retailsource.git
cd retailsource
```

---

### Step 3: Create Your Branch

```bash
git checkout -b your-name
```

Replace `your-name` with your actual name like `rahim` or `fatima`. Now you work on your own branch.

---

### Step 4: Setup Database (MySQL)

1. Open **XAMPP Control Panel**
2. Click **Start** next to **Apache** and **MySQL** (both should turn green)
3. Open terminal and run:

```bash
"C:/xampp/mysql/bin/mysql.exe" -u root < database/schema.sql
"C:/xampp/mysql/bin/mysql.exe" -u root < database/seed.sql
```

This creates the `supplylink` database with all tables and product data.

To verify it worked:
```bash
"C:/xampp/mysql/bin/mysql.exe" -u root -e "USE supplylink; SHOW TABLES;"
```

You should see 12 tables listed.

---

### Step 5: Setup Flask Backend (Python)

1. Open terminal in the project folder
2. Run these commands:

```bash
cd backend
pip install -r requirements.txt
```

3. Create a file called `.env` inside the `backend/` folder with this content:

```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=supplylink
JWT_SECRET_KEY=supplylink_jwt_secret_key_2026
```

4. Start the backend server:

```bash
python app.py
```

You should see: `Running on http://0.0.0.0:5000`

Keep this terminal open while working.

---

### Step 6: Setup Flutter App

1. Open a **new terminal** (keep Flask running in the other one)
2. Run:

```bash
cd mobile
flutter pub get
```

3. Connect your Android phone via USB (enable Developer Mode + USB Debugging) OR start an Android emulator from Android Studio

4. Run the app:

```bash
flutter run
```

The app should open with the Welcome screen.

---

### Step 7: Test It Works

1. Make sure XAMPP MySQL is running (green)
2. Make sure Flask backend is running (`python app.py`)
3. Open the Flutter app
4. Tap **Create Account**
5. Fill the form and register
6. You should land on the Dashboard — it works!

---

## Project Structure

```
retailsource/
├── database/
│   ├── schema.sql       ← Creates all 12 tables
│   └── seed.sql         ← Fills product catalog (Rice, Sugar, etc.)
├── backend/
│   ├── app.py           ← Flask server (start with: python app.py)
│   ├── config.py        ← Database settings
│   ├── db.py            ← Database connection
│   ├── requirements.txt ← Python packages to install
│   └── routes/
│       └── auth.py      ← Login/Register API
├── mobile/
│   └── lib/
│       ├── main.dart           ← App entry point
│       ├── config/             ← Colors and API URLs
│       ├── services/           ← Code that talks to Flask API
│       └── screens/
│           ├── auth/           ← Welcome, Login, Register
│           ├── shop_owner/     ← Shop owner dashboard
│           └── stockholder/    ← Supplier dashboard
```

---

## Git Workflow (How to Save Your Work)

After making changes:

```bash
git add .
git commit -m "describe what you changed"
git push origin your-branch-name
```

To get latest updates from main:

```bash
git checkout main
git pull origin main
git checkout your-branch-name
git merge main
```

---

## API Endpoints (Currently Working)

| Method | URL | What it does |
|--------|-----|-------------|
| POST | `/api/auth/register` | Create new account |
| POST | `/api/auth/login` | Login with email + password |
| GET | `/api/auth/me` | Get current user info (needs JWT token) |

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Flask (Python)
- **Database:** MySQL (via XAMPP)
- **Auth:** JWT tokens + bcrypt password hashing
