# Grocery App (`grocery_app_su25`) & Laravel Backend

A full-stack **Grocery Delivery Application** built with **Flutter** (Android, iOS, Web, Windows Desktop) and powered by a **Laravel 13 REST API + Filament v5 Admin Dashboard** backend.

---

## Table of Contents
1. [Key Features](#1-key-features)
2. [Tech Stack & Project Structure](#2-tech-stack--project-structure)
3. [Prerequisites](#3-prerequisites)
4. [Step 1: How to Open & Run the Backend Server](#4-step-1-how-to-open--run-the-backend-server)
5. [Step 2: How to Open & Run the Flutter App](#5-step-2-how-to-open--run-the-flutter-app)
6. [How to Use the App & Admin Dashboard](#6-how-to-use-the-app--admin-dashboard)
7. [API Endpoints Overview](#7-api-endpoints-overview)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Key Features

### Customer App (Flutter)
- **Onboarding & Guest Mode**: First-time users can view the onboarding walkthrough and tap **Continue as Guest** to browse categories, search products, and view product details without logging in.
- **Authentication Gate**: Adding items to the cart, saving favorites, or opening protected screens prompts guest users with a **Sign In / Sign Up** dialog.
- **Persistent Sessions & Auto Token Refresh**: Sanctum bearer tokens are persisted locally and automatically refreshed via `/api/auth/refresh` if expired.
- **Catalog, Categories & Search**: Browse featured items, filter by category, and search products in real time.
- **Product Details & Multi-Image Carousel**: Swipe or click through multiple product photos (supports touch, mouse drag, arrow buttons, and dot indicators), view nutritional facts, and see related items.
- **Real-Time Stock Status**: Product cards and detail screens display live stock badges (`In Stock` / `Out of Stock`) and prevent adding more than available inventory.
- **Delivery Address Management**: Add, edit, delete, and set default delivery addresses. Newly registered users without an address receive a helpful pop-up recommendation to add their address.
- **Cart, Checkout & Order Tracking**: Adjust item quantities, choose delivery address and payment method, place orders, view order history/timelines, and reorder past purchases.
- **Profile Editing & Avatar Upload**: Update name, email, phone number, password, and upload/remove a custom profile photo (with a clean vector default avatar when no photo is uploaded).

### Backend & Admin Panel (Laravel + Filament)
- **Filament v5 Admin Panel (`/admin`)**: Manage Categories, Products (including multi-image galleries and `stock_quantity`), Customer Orders, and Users.
- **Laravel Sanctum REST API (`/api/*`)**: Token-based authentication, server-side cart validation, favorite toggling, address book management, and transactional order placement with automatic stock deduction.

---

## 2. Tech Stack & Project Structure

| Layer | Technology | Location |
| :--- | :--- | :--- |
| **Frontend App** | Flutter (SDK `^3.11.5`), Riverpod, GoRouter, Dio, SharedPreferences, ImagePicker | `d:\SU25\Flutter\grocery_app_su25` |
| **Backend API** | PHP `^8.3`, Laravel `^13.17`, Laravel Sanctum `^4.0` | `D:\SU25\Flutter\backend` |
| **Admin Panel** | Filament `^5.10` (`/admin`) | `D:\SU25\Flutter\backend\app\Filament` |

```text
D:\SU25\Flutter\
├── backend\                          # Laravel 13 REST API + Filament Admin
│   ├── app\
│   │   ├── Filament\Resources\       # Admin CRUD (Categories, Products, Orders, Users)
│   │   ├── Http\Controllers\Api\     # REST API Controllers (Auth, Catalog, Cart, Order, Address, Favorite)
│   │   └── Models\                   # Eloquent Models
│   ├── database\migrations\          # Database schema migrations
│   └── routes\api.php                # Public & Sanctum-protected API routes
│
└── grocery_app_su25\                 # Flutter Client Application
    ├── assets\                       # Fonts (Inter), icons, and images
    └── lib\
        ├── main.dart                 # App entry point (initializes AuthState & ProviderScope)
        ├── app.dart                  # MaterialApp.router & cross-device scroll behavior
        ├── core\                     # AuthState, GoRouter config, theme, shared widgets
        ├── models\                   # Dart data models (Product, Category, CartItem, Order, Address)
        ├── providers\                # Riverpod state notifiers (app_providers.dart)
        ├── services\                 # Dio ApiClient (api_client.dart)
        └── features\                 # Feature screens (auth, home, categories, search, cart, checkout, orders, favorites, addresses, profile)
```

---

## 3. Prerequisites

Make sure the following tools are installed on your computer before opening the project:

1. **Flutter SDK** (`>= 3.11.5`) — Check with `flutter --version`
2. **PHP** (`>= 8.3`) & **Composer** — Check with `php -v` and `composer -V`
3. **Database** — SQLite (enabled by default in Laravel) or MySQL / MariaDB (via XAMPP, Laragon, or Herd)
4. **IDE / Editor** — VS Code, Antigravity, or Android Studio (with Flutter & Dart extensions)

---

## 4. Step 1: How to Open & Run the Backend Server

 You should always start the **Laravel backend** first so the Flutter app can fetch live categories, products, images, and user data.

### 1. Open the Backend Folder
Open a terminal (PowerShell or Command Prompt) and navigate to the backend folder:
```powershell
cd D:\SU25\Flutter\backend
```

### 2. Install PHP Dependencies & Configure Environment (First-Time Setup)
```powershell
# Install Composer packages
composer install

# Copy .env.example to .env if .env does not exist yet
copy .env.example .env

# Generate application encryption key
php artisan key:generate
```

> **Note:** Check `D:\SU25\Flutter\backend\.env` to verify your database connection (`DB_CONNECTION=sqlite` or `DB_CONNECTION=mysql`).

### 3. Run Database Migrations, Seed Sample Data & Link Storage
```powershell
# Run database migrations and seed initial categories/products/test user
php artisan migrate --seed

# Create the symbolic link for uploaded product & profile images
php artisan storage:link
```

### 4. Create an Admin Account for the Filament Dashboard (Optional)
If you need a new admin user to log into `http://127.0.0.1:8000/admin`:
```powershell
php artisan make:filament-user
```

### 5. Start the Laravel API Server
Run the server on port `8000`:
```powershell
php artisan serve --host=0.0.0.0 --port=8000
```
- **API Base URL**: `http://127.0.0.1:8000/api`
- **Admin Panel URL**: `http://127.0.0.1:8000/admin`

---

## 5. Step 2: How to Open & Run the Flutter App

### 1. Open the Flutter Project in Your IDE
- **VS Code / Antigravity**: Click **File -> Open Folder...** and select `d:\SU25\Flutter\grocery_app_su25`, or run:
  ```powershell
  cd d:\SU25\Flutter\grocery_app_su25
  ```

### 2. Install Flutter Dependencies
```powershell
flutter pub get
```

### 3. Run the App on Your Target Platform

#### Option A: Run on Web (Chrome) — Recommended with a Fixed Port
Using a fixed `--web-port` keeps your browser's `localStorage` (saved login token, cart, and preferences) on the same origin across restarts:
```powershell
flutter run -d chrome --web-port=5000
```

#### Option B: Run on Windows Desktop
```powershell
flutter run -d windows
```

#### Option C: Run on Android Emulator
`ApiClient` automatically maps `localhost` to `http://10.0.2.2:8000/api` on the Android emulator:
```powershell
flutter run -d android
```

#### Option D: Run on a Physical Device (Custom Backend IP)
If testing on a real phone connected to the same Wi-Fi network as your PC, pass your PC's LAN IP address using `--dart-define`:
```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api
```

---

## 6. How to Use the App & Admin Dashboard

### A. Using the Customer App
1. **First Launch & Guest Browsing**:
   - Swipe through the **Onboarding** screens or tap **Skip**.
   - On the **Sign In** screen, tap **Continue as Guest** at the bottom to explore the store immediately without an account.
2. **Sign Up & Delivery Address Setup**:
   - Tap **Sign Up** (or attempt to add an item to your cart / favorites as a guest) to create an account.
   - Alternatively, sign in with the seeded test account:
     - **Email**: `test@example.com`
     - **Password**: `password`
   - When a newly registered user has no saved address, the app automatically displays a pop-up recommending you to **Add Address**.
3. **Shopping & Stock Validation**:
   - Browse products on **Home**, **Categories**, or **Search**.
   - Products display live stock badges (`In Stock (N)` or `Out of Stock`).
   - Open any product to swipe/click through its **Image Carousel**, read nutrition details, and tap **Add to Cart**.
4. **Checkout & Orders**:
   - Open the **Cart**, review quantities, and tap **Proceed to Checkout**.
   - Select your delivery address and payment method, then place your order.
   - Track active and past orders under the **Orders** tab.
5. **Profile & Avatar Customization**:
   - Go to the **Profile** tab and tap the edit icon (or **Edit Profile**).
   - Upload a profile picture from your device, update your name/email/phone, or change your password.
   - If you don't upload a photo, a clean default profile avatar is displayed automatically.

### B. Using the Filament Admin Panel (`http://127.0.0.1:8000/admin`)
1. Log in at `http://127.0.0.1:8000/admin` with your admin credentials.
2. **Categories**: Add or reorder grocery categories and upload category icons.
3. **Products**: Create products, upload primary and gallery images, set `price` / `original_price`, and update `stock_quantity` (setting `stock_quantity` to `0` immediately marks the product as **Out of Stock** in the Flutter app).
4. **Orders**: View incoming customer orders and update their fulfillment status (`processing`, `out_for_delivery`, `delivered`, `cancelled`).

---

## 7. API Endpoints Overview

| Method | Endpoint | Access | Description |
| :--- | :--- | :--- | :--- |
| `POST` | `/api/auth/register` | Public | Register a new customer account |
| `POST` | `/api/auth/login` | Public | Log in and receive a 30-day Sanctum token |
| `POST` | `/api/auth/refresh` | Public | Refresh an expired bearer token |
| `GET` | `/api/categories` | Public | Fetch active product categories |
| `GET` | `/api/products` | Public | Fetch products (`?category=` & `?q=` filters) |
| `GET` | `/api/products/{id}` | Public | Fetch single product details & image gallery |
| `GET` | `/api/auth/me` | Protected | Get current user profile |
| `POST` | `/api/auth/profile` | Protected | Update profile info, password, or avatar image |
| `POST` | `/api/auth/logout` | Protected | Revoke active bearer token |
| `GET/POST/PUT/DELETE` | `/api/cart` | Protected | View, add, update, remove, or clear cart items |
| `GET/POST` | `/api/favorites` | Protected | List favorite products or toggle favorite status |
| `GET/POST/PUT/DELETE` | `/api/addresses` | Protected | Manage customer delivery addresses |
| `GET/POST` | `/api/orders` | Protected | List customer orders or place a new order |

---

## 8. Troubleshooting

- **"Cannot connect to backend server"**:
  - Make sure `php artisan serve --host=0.0.0.0 --port=8000` is running in `D:\SU25\Flutter\backend`.
- **Product or Avatar Images Return 404**:
  - Run `php artisan storage:link` inside `D:\SU25\Flutter\backend`.
- **Session Reset After Stopping & Re-running Flutter Web**:
  - Always launch Chrome with a fixed port (`flutter run -d chrome --web-port=5000`) so the browser keeps the same `localhost:5000` storage origin.
- **CORS Issues on Flutter Web**:
  - Ensure `http://127.0.0.1:8000` is running and `config/cors.php` in the Laravel backend allows `*` or `localhost` origins.
