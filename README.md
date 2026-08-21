# Atithi Bhoj — Kanpur's First Tiffin Service App

Atithi Bhoj is a modern, premium Flutter application designed for a local single-provider tiffin service based in Kanpur. The app focuses on offering an extremely simple, high-end user experience, allowing customers to order healthy, homemade food in under 60 seconds.

---

## 📱 Product Features

### 1. Customer Experience
* **Editorial Home Dashboard:** A clean, food-magazine style homepage showcasing today's special tiffin, pricing details (with original crossed-out pricing and discount labels), and portion categorization.
* **Premium Feature Bar:** Inline brand promise capsule showing `🥬 100% Veg • 🍲 Ghar Ka Swad • 🛵 On Time Delivery` with marigold accents.
* **Swipe-to-Order Slider:** An interactive, satisfying gesture slider button. Dragging the handle flows chevrons dynamically, fades text, and uses a spring-back transition (`Curves.easeOutBack`) if released early.
* **Multistep Checkout Funnel:** A 3-step checkout wizard with a sleek Instagram-style stories progress bar indicator:
  1. *Plan Frequency:* Choose one-time, daily, weekly, or monthly subscription plans with popular/best-value gold badges.
  2. *Delivery Details:* Form fields for address and landmarks.
  3. *Payment Sheet:* A simulated Razorpay payment gateway interface.
* **Active Subscriptions Tracker:** A personal dashboard to track ongoing subscriptions, complete with a horizontal progress bar showing remaining meals and a timeline indicating scheduled or skipped slots.
* **Skip Tomorrow's Delivery:** A one-click toggle button allowing users to cancel tomorrow's meal delivery and roll over their subscription credit.

### 2. Admin Console
* **Access trigger:** Sign in using any phone number ending in `9999` (e.g., `9876549999`) to automatically gain administrator privileges and see the Admin console shortcut.
* **Business Analytics:** Real-time metrics counting total registered customers, total revenue generated, active subscribers, and popular coupons usage.
* **Menu Manager:** Form fields to update today's tiffin contents, modify prices, or change image URLs in real-time.
* **Coupon Manager:** System to add new promotional discount codes, define discount models (percentage vs fixed), set minimum order values, and toggle code activation status.

---

## 🛠️ Technical Architecture

### 1. Simulated Firestore Database (`lib/core/services/firebase_service.dart`)
To make the application completely zero-setup and run fully offline, it features a client-side singleton **Cloud Firestore Database Emulator**. 
- It emulates Firestore collections (`/users`, `/menu`, `/orders`, `/coupons`, `/payments`) using document storage maps.
- Pre-seeds initial data on start (coupon `FIRSTTIFFIN` for ₹30 off, coupon `KANPUR50` for ₹50 off, and today's Veg Tiffin menu).

### 2. Unified Brand Styling
- **Color Palette:** Saffron marigold accent (`Color(0xFFE88A1A)`) and deep forest green (`Color(0xFF1E5631)`) on a warm cream background (`Color(0xFFFBF9F6)`).
- **Global Typography:** Enforces the clean, modern geometric **Outfit** font face throughout all headlines, labels, buttons, and inputs for complete visual consistency.
- **Bloc Architecture:** Uses `flutter_bloc` (Cubit pattern) to decouple UI, business logic, and repository services.

---

## 🚀 Running the App Locally

### 1. Prerequisites
- Flutter SDK installed (`3.38.9` or higher)
- Dart SDK (`3.10.8` or higher)
- Android emulator or iOS simulator running

### 2. Launching the App
1. Clone or navigate to the workspace directory.
2. Run standard pub get:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### 3. Testing Credentials
- **Customer login:** Any 10-digit number. Enter OTP **`123456`**.
- **Admin login:** Any 10-digit number ending in **`9999`** (e.g., `9876549999`). Enter OTP **`123456`**.

---

## 📦 Building a Release Build

### 1. Android Permission Configuration
The application is pre-configured with the network permission tag inside the main [AndroidManifest.xml](file:///c:/Users/shiva/StudioProjects/tiffin_service_app/android/app/src/main/AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
*This ensures all network-based images (like the food bowl images) load successfully in compiled production APKs.*

### 2. Compilation Command
To build a release-minified Android APK, run:
```bash
flutter clean
flutter build apk
```
The compiled APK will be outputted to:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Production Firebase Migration

When you are ready to link the app to your live production Google Firebase Console, follow these steps:

### Step 1: Install official Firebase Plugins
Add dependencies to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.27.0
  cloud_firestore: ^4.15.8
  firebase_auth: ^4.17.8
```

### Step 2: Configure FlutterFire CLI
Run configuration parameters in your project folder to generate `lib/firebase_options.dart`:
```bash
firebase login
flutterfire configure
```

### Step 3: Initialize Firebase on Boot
Update `lib/main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TiffinServiceApp());
}
```

### Step 4: Swap Emulator Queries with Live Firestore
Open `lib/core/services/firebase_service.dart` and swap the local document maps with live `FirebaseFirestore` instances:
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> collectionGet(String collectionName) async {
    final snap = await _firestore.collection(collectionName).get();
    return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>> docAdd(String collectionName, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(collectionName).add(data);
    return {'id': docRef.id, ...data};
  }
  
  // Swap other methods similarly...
}
```
