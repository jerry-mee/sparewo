# SpareWo Vendor App - Technical Documentation (19/06/25)

## 1. System Architecture

### 1.1 Overview

SpareWo is a comprehensive auto parts marketplace platform consisting of three main components:

1.  **Admin Dashboard** (admin.sparewo.ug): Backend control panel for vetting vendors and products
2.  **Vendor App** (vendor.sparewo.ug): Mobile and web application for auto parts suppliers
3.  **Client App** (store.sparewo.ug): Consumer-facing marketplace for purchasing auto parts

This document focuses on the Vendor App architecture, which serves as the onboarding and inventory management platform for auto parts suppliers.

### 1.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       SpareWo Vendor App                         │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐ │
│ │  User Interface │ │  Business Logic │ │      Data Layer     │ │
│ ├─────────────────┤ ├─────────────────┤ ├─────────────────────┤ │
│ │ - Flutter UI    │ │ - Riverpod      │ │ - Firebase Services │ │
│ │ - Material 3    │ │ - Notifiers     │ │ - Repositories      │ │
│ │ - Custom Widgets│ │ - Service Layer │ │ - Local Storage     │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Firebase Backend Services                    │
├─────────────────┬─────────────────┬────────────────┬────────────┤
│ Authentication  │ Cloud Firestore │ Cloud Storage  │ Cloud      │
│ (Vendor Accounts)│ (Product Data)  │ (Product Images)│ Functions │
└─────────────────┴─────────────────┴────────────────┴────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   SpareWo Admin Dashboard                        │
│  (Product approval, Vendor management, Catalog synchronization)  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Integration Architecture

The Vendor App integrates with the broader SpareWo ecosystem through a multi-layered approach:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   Vendor App   │────▶│ Firebase Cloud │────▶│  Admin Panel   │
│                │◀────│   Platform     │◀────│                │
└────────────────┘     └────────────────┘     └────────────────┘
                                │
                                ▼
                        ┌────────────────┐
                        │  Client App    │
                        │  Marketplace   │
                        └────────────────┘
```

Key integration points:
- Products created by vendors are stored in `vendor_products`.
- Admin panel reviews and approves products for client visibility.
- Approved products may be transformed into `catalog_products` for the client app.
- Orders placed by clients are stored in the `orders` collection and trigger notifications to vendors.

## 2. User Journey

### 2.1 Vendor User Flow

The application guides vendors through a structured lifecycle from initial interest to active selling.

```
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Onboarding│     │Account        │     │ Email             │
│ & Signup  │────▶│Creation       │────▶│ Verification      │
└───────────┘     └───────────────┘     └───────────────────┘
                                                 │
                                                 ▼
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Inventory │◀────│   Dashboard   │◀────│ Business Profile  │
│ Management│     │ (Stats/Nav)   │     │ (Settings)        │
└───────────┘     └───────────────┘     └───────────────────┘
      │                   ▲                      
      │                   │                      
      ▼                   │                      
┌───────────┐     ┌───────────────┐              
│ Order     │────▶│ Order         │              
│ Fulfillment│    │ Management    │              
└───────────┘     └───────────────┘              
```

### 2.2 Detailed Flow Description

1.  **Onboarding & Signup**: A `SplashScreen` checks auth state, leading to the `OnboardingScreen` for new users, then to `SignupScreen`.
2.  **Account Creation**: `AuthNotifier` and `FirebaseAuthService` handle user creation in Firebase Authentication. A corresponding document is created in the `vendors` or `users` collection.
3.  **Email Verification**: The `EmailVerificationScreen` manages the OTP/code flow using the `VerificationService`.
4.  **Business Profile Setup**: Post-verification, the vendor lands on the dashboard and is guided to the `Settings` screens (`ProfileScreen`, `StoreSettingsScreen`) to complete their profile.
5.  **Dashboard**: The `DashboardScreen` acts as the central hub, displaying key statistics fetched by the `StatsProvider` and `StatsService`.
6.  **Inventory Management**: The `ProductManagementScreen` allows vendors to view, add (`AddEditProductScreen`), and manage their products in the `vendor_products` collection.
7.  **Order Management**: The `OrdersScreen` lists all orders assigned to the vendor, with details available on the `OrderDetailsScreen`.
8.  **Order Fulfillment**: Vendors update order statuses through the app, which is managed by the `OrderService`.

## 3. Technical Implementation

### 3.1 Core Technologies

-   **Framework**: Flutter (Dart)
-   **State Management**: Riverpod (Providers, Notifiers)
-   **Backend**: Firebase (Authentication, Firestore, Storage)
-   **Architecture**: Service-Repository-Provider pattern
-   **Code Generation**: Freezed for immutable models, `flutter_gen` for assets.
-   **Form Management**: Custom `Validators` class
-   **Navigation**: Named routes with `app_router.dart`
-   **Error Handling**: Custom exception hierarchy (`exceptions/`)
-   **Platform Support**: Web & Mobile separation for services like `camera_service`

*(This section remains accurate as it reflects the current architecture well.)*

## 4. Component Structure

### 4.1 Directory Organization

The project structure is organized by feature and layer, promoting separation of concerns.

```
lib/
├── main.dart                       # Application entry point
├── firebase_options.dart           # Firebase configuration
├── theme.dart                      # Global styling and theming
├── config/                         # Environment configuration
├── constants/                      # App-wide constants (enums, vehicle data)
├── exceptions/                     # Custom exception classes for error handling
├── gen/                            # Auto-generated asset and font references
├── models/                         # Data models (Freezed classes)
│   ├── auth_result.dart            # Authentication result wrapper
│   ├── catalog_product.dart        # Client-facing product model
│   ├── dashboard_stats.dart        # Data model for dashboard statistics
│   ├── notification.dart           # Notification model
│   ├── order.dart                  # Order model
│   ├── settings.dart               # App settings model
│   ├── user_model.dart             # Core user/vendor data
│   ├── vehicle_compatibility.dart  # Vehicle fitment data structure
│   └── vendor_product.dart         # Vendor-specific product model
│   └── ... (*.freezed.dart, *.g.dart auto-generated files)
├── providers/                      # Riverpod state management providers & notifiers
│   ├── auth_notifier.dart          # Manages authentication state (login, logout, user)
│   ├── order_notifier.dart         # Manages state for orders
│   ├── providers.dart              # Central hub for provider definitions
│   ├── settings_provider.dart      # Manages app settings state
│   ├── stats_provider.dart         # Manages dashboard statistics state
│   ├── theme_notifier.dart         # Manages light/dark theme state
│   └── vendor_product_provider.dart # Manages state for vendor products
├── repositories/                   # Data abstraction layer
│   └── user_repository.dart        # Handles user data operations
├── routes/                         # Navigation logic
│   └── app_router.dart             # Central routing definition for all screens
├── screens/                        # UI screens, organized by feature
│   ├── dashboard/                  # Main dashboard screen and widgets
│   ├── notifications/              # Notification list screen and items
│   ├── orders/                     # Order list and detail screens
│   ├── products/                   # Product management, detail, and add/edit screens
│   ├── settings/                   # Profile, store, and support settings screens
│   ├── email_verification_screen.dart
│   ├── forgot_password_screen.dart
│   ├── login_screen.dart
│   ├── onboarding_screen.dart
│   ├── signup_screen.dart
│   └── splash_screen.dart
├── services/                       # Business logic and external API communication
│   ├── api_service.dart            # Generic API service
│   ├── auth_state_manager.dart     # Manages persistence of auth state
│   ├── camera_service.dart         # Abstract image capture/picking service
│   ├── catalog_product_service.dart# Logic for client-facing catalog products
│   ├── firebase_auth_service.dart  # Wrapper for Firebase Authentication
│   ├── firebase_service.dart       # Wrapper for general Firebase operations (Firestore)
│   ├── logger_service.dart         # App-wide logging service
│   ├── notification_service.dart   # Logic for push and in-app notifications
│   ├── order_service.dart          # Business logic for orders
│   ├── settings_service.dart       # Logic for persisting settings
│   ├── stats_service.dart          # Logic for fetching dashboard stats
│   ├── storage_service.dart        # Wrapper for Firebase Storage
│   └── vendor_product_service.dart # Business logic for vendor products
├── utils/                          # Utility functions and helpers
│   ├── platform/                   # Platform-specific helper functions
│   ├── string_extensions.dart      # String helper extensions
│   └── validators.dart             # Form validation functions
└── widgets/                        # Reusable UI components
    ├── app_drawer.dart             # Main navigation drawer
    ├── custom_text_field.dart      # Standardized text input field
    ├── empty_state_widget.dart     # Widget for empty lists
    ├── loading_button.dart         # Button with a loading state
    ├── vehicle_compatibility_selector.dart # Complex vehicle selection widget
    └── ... (product cards, order cards, dialogs, etc.)
```

## 5. Implementation Status

### 5.1 Completed Features

-   ✅ Robust Authentication System (Login, Signup, Forgot Password, Verification)
-   ✅ Comprehensive Product Management (Create, Read, Update, Delete)
-   ✅ Advanced Data Models with Freezed (Type-safe and immutable)
-   ✅ Rich Service Layer abstracting all business logic.
-   ✅ Riverpod State Management for all core features.
-   ✅ Vehicle Compatibility Selection UI
-   ✅ Multi-Image Upload for products
-   ✅ Dashboard with real-time statistics (`stats_provider.dart`)
-   ✅ Core Order Management and listing
-   ✅ Notification List Screen
-   ✅ Settings screens (Profile, Store, Support)
-   ✅ Light/Dark Theme support (`theme_notifier.dart`)

### 5.2 In Progress

-   ⚠️ Enhanced order fulfillment workflows (e.g., status updates, shipping integration)
-   ⚠️ Real-time synchronization improvements across all modules.
-   ⚠️ Advanced product filtering and searching on the product management screen.

### 5.3 Planned Features

-   ⬜ Vendor-specific analytics dashboard.
-   ⬜ Integrated messaging system for communication with admins/clients.
-   ⬜ Bulk product operations (e.g., bulk stock update, bulk upload).
-   ⬜ Enhanced inventory management features.
-   ⬜ Vendor performance metrics and ratings.

---
