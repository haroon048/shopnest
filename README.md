# ShopNest

<p align="center"><strong>Shop smart. Live better.</strong><br>A modern Flutter e-commerce application powered by Firebase.</p>

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
