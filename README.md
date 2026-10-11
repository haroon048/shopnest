# ShopNest

<p align="center"><strong>Shop smart. Live better.</strong><br>A modern Flutter e-commerce application powered by Firebase.</p>

<p align="center">
  <a href="https://github.com/haroon048/shopnest/stargazers"><img src="https://img.shields.io/github/stars/haroon048/shopnest?style=flat-square&color=gold" alt="GitHub stars"></a>
  <a href="https://github.com/haroon048/shopnest/commits/main"><img src="https://img.shields.io/github/last-commit/haroon048/shopnest?style=flat-square" alt="Last commit"></a>
  <a href="https://github.com/haroon048/shopnest"><img src="https://img.shields.io/github/repo-size/haroon048/shopnest?style=flat-square" alt="Repository size"></a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-546E7A?style=flat-square" alt="Platforms">
</p>

## App preview

<p align="center">
  <img src="assets/images/onboarding/onboarding_1.png" width="30%" alt="ShopNest onboarding preview">
  <img src="assets/images/banners/banner_1.jpg" width="30%" alt="ShopNest home banner preview">
  <img src="assets/images/placeholders/empty_cart.png" width="30%" alt="ShopNest cart preview">
</p>

<p align="center"><em>Real project assets from the ShopNest Flutter app. The gallery is kept inside the repository so it remains available offline and renders directly on GitHub.</em></p>

## Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Motion and interaction](#motion-and-interaction)
- [Tech stack](#tech-stack)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Firestore data model](#firestore-data-model)
- [Quality checks](#quality-checks)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

## Overview

ShopNest is a production-style shopping app built with Flutter. It provides authentication, product discovery, categories, cart management, promotions, and Firebase-backed data synchronization.

## Features

- Onboarding with persistent first-launch state
- Email/password and Google authentication through Firebase Auth
- Product browsing with categories, banners, search, and product details
- Cached network images and shimmer loading states
- Cloud Firestore product and cart data
- Real-time cart synchronization per authenticated user
- Quantity updates, remove/clear cart, subtotal, delivery fee, and order total
- Promo codes: `WELCOME10` and `SAVE20`
- Firebase Cloud Messaging integration ready for notifications

## Architecture

ShopNest follows a feature-first Flutter architecture designed to keep UI, state, services, and domain models easy to evolve:

```text
lib/
├── app.dart                    # App shell and global configuration
├── main.dart                   # Entry point and service bootstrap
├── core/
│   ├── routes/                 # Centralized navigation routes
│   ├── services/               # Notifications and Cloudinary services
│   ├── theme/                  # Colors, typography, and app theme
│   ├── utils/                  # Validators, constants, helpers
│   └── widgets/                # Reusable design-system widgets
├── features/
│   ├── auth/                   # Login, signup, roles, password recovery
│   ├── home/                   # Home feed and discovery
│   ├── product/                # Product details and product state
│   ├── cart/                   # Real-time cart and pricing logic
│   ├── checkout/               # Checkout and order success flow
│   ├── orders/                 # Customer order history and details
│   ├── wishlist/               # Saved products
│   ├── chat/                   # Customer support chat
│   └── admin/                  # Dashboard, products, orders, categories
└── models/                     # Typed Firestore/domain models
```

### Data flow

```text
Flutter UI → Provider state → Firebase services → Firestore / Storage
     ↑              │                    │
     └──── reactive updates ────────────┘
```

## Motion and interaction

The UI is designed to feel responsive and modern without distracting from shopping:

- `flutter_animate` for entrance, fade, scale, and slide effects
- `shimmer` for smooth loading placeholders
- `carousel_slider` for interactive promotional banners
- `smooth_page_indicator` for onboarding progress feedback
- `lottie` for expressive success and empty-state illustrations
- `AnimatedNavIcon` and reusable widgets for consistent micro-interactions
- Provider-driven updates so cart badges and totals react immediately to Firestore changes

The existing animation assets live in `assets/animations/`, while reusable motion components are organized under `lib/core/widgets/`.

## Tech stack

| Area | Technology |
| --- | --- |
| UI | Flutter, Material Design |
| Language | Dart |
| State management | Provider |
| Authentication | Firebase Authentication, Google Sign-In |
| Database | Cloud Firestore |
| Notifications | Firebase Cloud Messaging |
| Storage | Firebase Storage |
| Networking | HTTP |
| Local persistence | SharedPreferences |
| Media | Image Picker, Cached Network Image |
| UI polish | Shimmer, Lottie, animations, carousels |

## Requirements

- Flutter SDK 3.4.0 or newer
- Dart SDK 3.4.0 or newer
- Android Studio or Xcode for mobile builds
- A Firebase project configured for the target platforms

## Getting started

```bash
git clone https://github.com/haroon048/shopnest.git
cd shopnest
flutter pub get
flutterfire configure
flutter run
```

Enable Email/Password and Google Authentication, Cloud Firestore, Firebase Storage, and Cloud Messaging. Never commit private credentials or production secrets.

## Firestore data model

The cart provider stores each user's cart at `users/{uid}/cart/{productId}`. Each cart document contains the product identifier, name, price, image URL, and quantity. Configure Firestore security rules so users can only access their own cart.

## Quality checks

```bash
dart format lib test
flutter analyze
flutter test
```

## Roadmap

- Checkout and payment gateway integration
- Order history and tracking
- Wishlist and product reviews
- Admin product management dashboard
- Automated CI builds and release distribution

## Contributing

Contributions are welcome. Create a focused feature branch, run the quality checks, and open a pull request with a clear description.

## License

This project is intended for learning and portfolio use. Add a `LICENSE` file with the terms you want to apply before distributing it publicly.

## Author

Built by [Haroon](https://github.com/haroon048).






For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
