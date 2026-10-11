ShopNest 🛍️
<p align="center">
  <strong>Shop smart. Live better.</strong><br>
  A premium Flutter e-commerce app with a full admin panel, powered by Firebase.
</p>
<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.4%2B-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/State-Provider-8B5CF6" alt="Provider">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-34D399" alt="Platform">
</p>
✨ Overview
ShopNest is a production-style e-commerce application built with Flutter and Firebase. It ships two complete experiences in one codebase: a customer shopping app with a Midnight Luxe dark-premium design, and a full admin panel for managing products, categories, orders, chats, and users.
📱 Screenshots
Customer Home
Product Detail
!Customer Home
!Product Detail
Cart
Admin Dashboard
!Cart
!Admin Dashboard
🚀 Features
Customer app
Onboarding with persistent first-launch state and role selection
Authentication — email/password and Google sign-in via Firebase Auth
Animated auth screens — hand-drawn swinging lamp (CustomPainter), glowing focus text fields
Home — banners, flash deals with countdown, category chips, product sections
Shop — glassmorphism product cards, search, category filter, price/rating sort
Product detail — swipeable image gallery, ratings & reviews, live stock status, quantity-aware Add to Cart, direct chat with seller
Cart — real-time per-user sync, quantity steppers, promo codes (WELCOME10, SAVE20), delivery fee logic, order totals
Wishlist — save favourites with one tap
Orders — place orders and track their status
Real-time chat — customer ↔ admin messaging with unread badges on the bottom nav
Profile & notifications — account management and in-app notification feed
Admin panel
Dashboard — animated count-up stats (orders, revenue, products, users), recent orders
Products — full CRUD with Cloudinary image uploads, stock management
Categories — create, edit, delete with image support
Orders — view and update order statuses
Chats — reply to customer conversations in real time, unread indicators
Users — browse registered users
🛠️ Tech stack
Area
Technology
UI
Flutter, Material 3, custom animations
Language
Dart
State management
Provider
Authentication
Firebase Auth (Email/Password, Google)
Database
Cloud Firestore
Image hosting
Cloudinary (unsigned uploads)
Push-ready
Firebase Cloud Messaging
Media
Cached Network Image, Image Picker
UI polish
Custom painters, shimmer, staggered animations
📁 Project structure
lib/
├── core/            # Theme, routes, reusable widgets, services
├── features/
│   ├── splash/      # Animated splash
│   ├── onboarding/  # First-launch onboarding
│   ├── auth/        # Login, signup, role select
│   ├── home/        # Customer home
│   ├── shop/        # Product browsing, search, filters
│   ├── product/     # Product detail, reviews
│   ├── cart/        # Cart provider & screens
│   ├── wishlist/    # Favourites
│   ├── checkout/    # Checkout flow
│   ├── orders/      # Order history & tracking
│   ├── chat/        # Real-time customer-admin chat
│   ├── admin/       # Dashboard, products, categories, orders, users
│   ├── profile/     # Account & settings
│   └── notifications/
└── models/          # Product, CartItem, Order, ChatMessage, ...
⚙️ Getting started
Requirements
Flutter SDK 3.4.0 or newer
A Firebase project with Authentication (Email/Password + Google), Cloud Firestore, and Cloud Messaging enabled
A Cloudinary account for product image uploads
Setup
git clone https://github.com/haroon048/shopnest.git
cd shopnest
flutter pub get
flutterfire configure
In the Firebase console, enable Email/Password and Google sign-in.
Create the Firestore collections: products, categories, users, orders, chats.
In lib/core/services/cloudinary_service.dart, set your Cloudinary cloud name and unsigned upload preset.
Create an admin user: register in the app, then set role: "admin" on that user's document in the users collection.
flutter run
Never commit API keys, google-services.json, GoogleService-Info.plist, or other secrets.
🗄️ Firestore data model
Collection
Purpose
products
Product catalog (name, price, oldPrice, images, stock, rating, categoryId, sellerId)
categories
Category names + image URLs
users/{uid}
Profiles, roles; subcollection cart/{productId} for the live cart
orders
Placed orders with items, totals, and status
chats
Customer-admin threads; subcollection messages
Security rules should restrict carts and profiles to their owners, keep the catalog publicly readable, and gate all admin collections behind role == "admin".
🗺️ Roadmap
[ ] Payment gateway integration (checkout is UI-complete)
[ ] Order tracking timeline
[ ] Product reviews with photos
[ ] Background push notifications (foreground in-app notifications live)
[ ] Multi-vendor support
🤝 Contributing
Contributions are welcome. Create a focused feature branch, run flutter analyze, and open a pull request with a clear description.
👨‍💻 Author
Built by Muhammad Haroon — Flutter Developer.
Connect on LinkedIn.

<p align="center">Made with Flutter 💜</p>
