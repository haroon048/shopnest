# 🛍️ ShopNest — Flutter E-Commerce App

<p align="center">
  <strong>Shop smart. Live better.</strong><br>
  A modern Flutter shopping experience powered by Firebase.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Provider-State%20Management-7952B3?style=for-the-badge" alt="Provider">
</p>

<p align="center">
  <a href="https://github.com/haroon048/shopnest">View Repository</a> •
  <a href="https://github.com/haroon048/shopnest/issues">Report an Issue</a>
</p>

---

## 📌 Overview

**ShopNest** is a Flutter-based e-commerce application designed to provide a smooth, modern, and user-friendly online shopping experience.

Built with Flutter, Dart, Firebase Authentication, Cloud Firestore, and Provider, the application focuses on secure authentication, product discovery, interactive shopping cart management, and synchronized user data.

The project combines modern UI design with practical mobile app development concepts, making it suitable for learning, development practice, and a developer portfolio.

## 📸 Application Screenshots

Explore the ShopNest interface, from onboarding and authentication to product browsing and shopping cart management.

> Add your actual app screenshots to the `screenshots/` folder using the filenames shown below. GitHub will display them automatically once the images are committed.

### 🏠 Onboarding & Home

<p align="center">
  <img src="screenshots/onboarding.png" width="30%" alt="ShopNest onboarding screen">
  &nbsp;
  <img src="screenshots/home.png" width="30%" alt="ShopNest home screen">
  &nbsp;
  <img src="screenshots/categories.png" width="30%" alt="ShopNest categories screen">
</p>

### 🛍️ Product Discovery

<p align="center">
  <img src="screenshots/products.png" width="30%" alt="Product listing">
  &nbsp;
  <img src="screenshots/product_details.png" width="30%" alt="Product details">
  &nbsp;
  <img src="screenshots/search.png" width="30%" alt="Product search">
</p>

### 🛒 Shopping Cart & Authentication

<p align="center">
  <img src="screenshots/cart.png" width="30%" alt="Shopping cart">
  &nbsp;
  <img src="screenshots/login.png" width="30%" alt="Login screen">
  &nbsp;
  <img src="screenshots/signup.png" width="30%" alt="Registration screen">
</p>

## ✨ Key Features

* **User Authentication:** Email/password authentication and Google Sign-In integration.
* **First-Launch Onboarding:** Introduces users to the application with persistent onboarding state.
* **Product Discovery:** Browse products, explore categories, view promotional banners, and search for products.
* **Product Details:** View product information and images.
* **Shopping Cart:** Add items, update quantities, remove individual products, and clear the cart.
* **Real-Time Synchronization:** Keep authenticated users' cart data synchronized through Cloud Firestore.
* **Order Summary:** Calculate subtotal, delivery fees, discounts, and the final estimated total.
* **Promo Codes:** Support for `WELCOME10` and `SAVE20`, according to the application's implemented validation rules.
* **Loading Experience:** Shimmer effects and cached network images for a smoother browsing experience.
* **Modern UI:** Animations, carousels, Lottie assets, and reusable Flutter components.
* **Push Notifications:** Firebase Cloud Messaging integration, subject to platform configuration and implementation.

## 🧰 Technology Stack

| Category              | Technology                    |
| --------------------- | ----------------------------- |
| Framework             | Flutter                       |
| Programming Language  | Dart                          |
| UI                    | Material Design               |
| State Management      | Provider                      |
| Authentication        | Firebase Authentication       |
| Database              | Cloud Firestore               |
| Google Authentication | Google Sign-In                |
| Notifications         | Firebase Cloud Messaging      |
| Cloud Storage         | Firebase Storage              |
| Networking            | HTTP                          |
| Local Persistence     | SharedPreferences             |
| Image Loading         | Cached Network Image          |
| Image Selection       | Image Picker                  |
| Loading Effects       | Shimmer                       |
| Animations            | Lottie and Flutter animations |
| Development Tools     | VS Code, Android Studio, Git  |

## 🏗️ Project Architecture

The application uses Flutter's widget-based architecture and Provider for state management. Organize the project into reusable components and separate responsibilities as appropriate for the existing codebase.

A suggested structure for future development:

```text
shopnest/
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   └── animations/
├── lib/
│   ├── main.dart
│   ├── models/
│   ├── providers/
│   ├── services/
│   ├── repositories/
│   ├── screens/
│   ├── widgets/
│   ├── utils/
│   └── firebase_options.dart
├── screenshots/
├── test/
├── pubspec.yaml
└── README.md
```

*Note: This is a suggested structure. Keep the documentation aligned with the folders and files that actually exist in your repository.*

## ⚙️ Prerequisites

Before running ShopNest, install and configure:

* Flutter SDK 3.4.0 or a compatible newer version.
* Dart SDK compatible with the project's Flutter version.
* Android Studio or Xcode for the target platform.
* VS Code or another preferred code editor.
* A configured Firebase project.
* FlutterFire CLI.

Check your Flutter installation:

```bash
flutter doctor
```

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/haroon048/shopnest.git
cd shopnest
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Firebase

Install the FlutterFire CLI if it is not already installed:

```bash
dart pub global activate flutterfire_cli
```

Sign in to Firebase CLI if required, then configure the application:

```bash
flutterfire configure
```

Select your Firebase project and the platforms you intend to support.

### 4. Enable Firebase Services

In the Firebase Console, configure the services your application uses:

* **Authentication:** Enable Email/Password and Google sign-in providers.
* **Cloud Firestore:** Create a database and configure secure access rules.
* **Cloud Storage:** Enable storage if the app uploads or retrieves files through Firebase Storage.
* **Cloud Messaging:** Configure the required platform settings if push notifications are implemented.

Complete any required Google Sign-In configuration, including Android SHA fingerprints and platform-specific settings.

### 5. Run the Application

Connect an Android device or start a supported emulator:

```bash
flutter run
```

To run the web version, if web support and Firebase web configuration are available:

```bash
flutter run -d chrome
```

## 🔥 Firestore Data Model

ShopNest stores each authenticated user's cart under their own user document:

```text
users/
└── {uid}/
    └── cart/
        ├── {productId}/
        └── {productId}/
```

A cart document can contain fields such as:

```json
{
  "productId": "product_001",
  "name": "Sample Product",
  "price": 1200.0,
  "imageUrl": "https://example.com/product.png",
  "quantity": 2
}
```

The example represents the intended data model; actual field names and types should match the implementation in your project.

### 🔐 Security Considerations

* Authenticate users before allowing access to their personal cart.
* Enforce user ownership through Firestore Security Rules.
* Do not use unrestricted test-mode rules in production.
* Validate prices and discounts on a trusted backend before accepting real payments.
* Never commit private service-account credentials, API secrets, or sensitive configuration files.

## 🧪 Code Quality & Testing

Format the Dart code:

```bash
dart format lib test
```

Analyze the project:

```bash
flutter analyze
```

Run automated tests:

```bash
flutter test
```

Resolve any reported issues before preparing a release.

## 📦 Build a Release APK

To generate an Android APK:

```bash
flutter build apk --release
```

The APK is normally generated at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

For Google Play distribution, build an Android App Bundle:

```bash
flutter build appbundle --release
```

Ensure that release signing and Firebase configuration are properly set up before publishing.

## 🗺️ Future Enhancements

* Checkout and payment gateway integration.
* Order placement, order history, and order tracking.
* Wishlist and product reviews.
* Admin dashboard for product and category management.
* Improved filtering, sorting, and personalized recommendations.
* Expanded notification workflows.
* Automated testing and continuous integration.
* Production deployment and release distribution.

*These are planned improvements, not claims that every feature is currently implemented.*

## 🤝 Contributing

Contributions and suggestions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Implement your changes.
4. Run formatting, analysis, and tests.
5. Open a pull request with a clear description.

## 📄 License

This project is intended for learning and portfolio use. Add a `LICENSE` file to the repository before specifying redistribution or usage terms.

## 👨‍💻 Author

**Haroon — Flutter Developer**

* GitHub: [@haroon048](https://github.com/haroon048)

---

<p align="center">
  <strong>ShopNest — Shop smart. Live better. 🛍️</strong>
</p>
