# SpareWo Client App - Technical Documentation

## 1. System Architecture

### 1.1 Overview

SpareWo is a comprehensive auto parts marketplace platform consisting of three main components:

1. **Admin Dashboard** (admin.sparewo.ug): Backend control panel for vetting vendors and products
2. **Vendor App** (vendor.sparewo.ug): Mobile and web application for auto parts suppliers
3. **Client App** (store.sparewo.ug): Consumer-facing marketplace for purchasing auto parts

This document focuses on the Client App architecture, which serves as the primary interface for end-users to browse, purchase, and manage auto parts and service appointments.

### 1.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       SpareWo Client App                         │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐ │
│ │  User Interface │ │  Business Logic │ │      Data Layer     │ │
│ ├─────────────────┤ ├─────────────────┤ ├─────────────────────┤ │
│ │ - Flutter UI    │ │ - Providers     │ │ - Firebase Services │ │
│ │ - Material      │ │ - State Mgmt    │ │ - API Clients       │ │
│ │ - Custom Widgets│ │ - Service Layer │ │ - Local Storage     │ │
│ └─────────────────┘ └─────────────────┘ └─────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Firebase Backend Services                    │
├─────────────────┬─────────────────┬────────────────┬────────────┤
│ Authentication  │ Cloud Firestore │ Cloud Storage  │ Cloud      │
│ (User Accounts) │ (Product Data)  │ (Product Images)│ Functions │
└─────────────────┴─────────────────┴────────────────┴────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Admin Dashboard & Vendor App                   │
│  (Product management, Order processing, AutoHub appointments)    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Integration Architecture

The Client App integrates with the broader SpareWo ecosystem through Firebase services:

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   Client App   │────▶│ Firebase Cloud │────▶│  Admin Panel   │
│                │◀────│   Platform     │◀────│                │
└────────────────┘     └────────────────┘     └────────────────┘
        │                     │                      │
        │                     │                      │
        ▼                     ▼                      ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Vendor App    │◀───▶│ Order & Product│◀───▶│ Email & Notif. │
│                │     │   Processing   │     │   Services     │
└────────────────┘     └────────────────┘     └────────────────┘
```

## 2. User Journey

### 2.1 End-User Flow

```
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Onboarding│     │Account        │     │ Home Screen       │
│ & Signup  │────▶│Creation       │────▶│ & Browsing        │
└───────────┘     └───────────────┘     └───────────────────┘
                                                 │
                                                 ▼
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Checkout  │◀────│   Cart        │◀────│ Product Details   │
│ Process   │     │ Management    │     │ & Selection       │
└───────────┘     └───────────────┘     └───────────────────┘
      │                                           ▲
      │                                           │
      ▼                                           │
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Order     │────▶│ User          │────▶│ AutoHub          │
│ Tracking  │     │ Profile       │     │ Service Booking   │
└───────────┘     └───────────────┘     └───────────────────┘
```

### 2.2 Detailed Flow Description

1. **Onboarding & Signup**
   - Welcome screen introduces SpareWo's value proposition
   - User registration flow collects basic information
   - Optional guest browsing for initial exploration

2. **Account Creation**
   - Firebase Authentication creates secure user accounts
   - Email verification for secure access
   - Optional social authentication

3. **Home Screen & Browsing**
   - Featured products and categories
   - Search functionality for finding specific parts
   - Vehicle compatibility filtering
   - Special promotions and deals

4. **Product Details & Selection**
   - Comprehensive product information
   - Compatibility checking with user's vehicles
   - Image gallery for product visualization
   - Add to cart functionality

5. **Cart Management**
   - Product quantity adjustment
   - Price calculations and summaries
   - Save for later functionality
   - Proceed to checkout

6. **Checkout Process**
   - Delivery information collection
   - Payment method selection
   - Order summary and confirmation
   - Receipt generation

7. **Order Tracking**
   - Order status updates
   - Delivery tracking
   - Order history

8. **User Profile**
   - Personal information management
   - Saved vehicles for easy compatibility checking
   - Order history access
   - Account settings

9. **AutoHub Service Booking**
   - Car service appointment scheduling
   - Service type selection
   - Appointment time and location selection
   - Confirmation and tracking

## 3. Technical Implementation

### 3.1 Core Technologies

- **Framework**: Flutter (Dart)
- **State Management**: Provider + ChangeNotifier
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Architecture**: Provider-Service-Repository pattern
- **Navigation**: Named routes with app_router
- **Error Handling**: Custom exception hierarchy
- **UI/UX**: Material Design with custom theming

### 3.2 Authentication System

The app implements a comprehensive authentication system using Firebase Authentication:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Auth Screens   │      │ Firebase Auth  │      │ Firestore      │
│ (UI Layer)     │      │ (Identity)     │      │ (User Data)    │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ AuthProvider   │      │ FirebaseService│      │ StorageService │
│ (State)        │◀────▶│ (Auth Logic)   │◀────▶│ (Data Storage) │
└───────┬────────┘      └────────────────┘      └────────────────┘
        │
        ▼
┌────────────────┐
│ App Router     │
│ (Navigation)   │
└────────────────┘
```

Key authentication features:
- Email/password authentication
- Guest browsing capabilities
- Secure token storage and refresh
- Session management
- Profile management

### 3.3 Product Browsing and Cart System

The product browsing and cart system allows users to explore and purchase products:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Catalog Screens│      │ Firebase       │      │ API Service    │
│ (UI Layer)     │      │ Firestore      │      │ (Data Fetching)│
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ DataProvider   │      │ CartHelper     │      │ ProductProvider│
│ (State)        │◀────▶│ (Cart Logic)   │◀────▶│ (Product State)│
└────────────────┘      └────────────────┘      └────────────────┘
```

Key product management features:
- Product listing and filtering
- Category-based browsing
- Search functionality
- Cart management
- Price calculations
- Order placement

### 3.4 AutoHub Booking System

The AutoHub booking system allows users to schedule service appointments:

```
┌────────────────┐      ┌────────────────┐      
│ AutoHub Screens│      │ Firebase       │      
│ (UI Layer)     │      │ Firestore      │      
└───────┬────────┘      └───────┬────────┘      
        │                       │                
        ▼                       ▼                
┌────────────────┐      ┌────────────────┐      
│ Form Components│      │ API Service    │      
│ (UI Components)│◀────▶│ (Data Submission)      
└────────────────┘      └────────────────┘      
```

Key AutoHub features:
- Service type selection
- Appointment scheduling
- Vehicle information collection
- Confirmation and notifications

## 4. Component Structure

### 4.1 Directory Organization

```
lib/
├── main.dart                       # Application entry point
├── firebase_options.dart           # Firebase configuration
├── constants/                      # Application constants
│   └── theme.dart                  # Global styling
├── exceptions/                     # Custom exception handling
│   ├── api_exception.dart          # Network/API exceptions
│   └── auth_exceptions.dart        # Authentication exceptions
├── models/                         # Data structures
│   ├── user_model.dart             # User profile data
│   └── cart_item_model.dart        # Cart item data structure
├── providers/                      # State management
│   ├── auth_provider.dart          # Authentication state
│   ├── data_provider.dart          # Data management state
│   └── product_provider.dart       # Product state management
├── routes/                         # Navigation
│   ├── app_router.dart             # Central routing definition
│   └── route_constants.dart        # Route path definitions
├── screens/                        # Application UI screens
│   ├── auth/                       # Authentication screens
│   ├── home/                       # Home screen and components
│   ├── catalog/                    # Product catalog screens
│   ├── cart/                       # Cart management screens
│   ├── autohub/                    # AutoHub booking screens
│   ├── profile/                    # User profile screens
│   └── settings/                   # App settings screens
├── services/                       # Business logic
│   ├── api/                        # API communication
│   ├── firebase_service.dart       # Firebase operations
│   ├── storage/                    # Local storage management
│   ├── navigation_service.dart     # Navigation helpers
│   ├── feedback_service.dart       # User feedback handling
│   └── system_ui_service.dart      # System UI configuration
├── utils/                          # Utility functions
│   ├── cart_helper.dart            # Cart calculations
│   └── error_handler.dart          # Error handling utilities
└── widgets/                        # Reusable UI components
    ├── auth/                       # Authentication widgets
    ├── product_card.dart           # Product display components
    ├── category_card.dart          # Category display components
    ├── cart_icon_widget.dart       # Cart indicator
    ├── responsive_builder.dart     # Responsive layout support
    └── year_picker.dart            # Date selection component
```

### 4.2 Key Components

1. **Authentication**
   - `AuthProvider`: Central authentication state management
   - `FirebaseService`: Firebase Authentication integration
   - Auth screens: Login, signup, splash, onboarding

2. **Product Browsing**
   - `ProductProvider`: Product state management
   - `CatalogScreen`: Product browsing interface
   - `ProductDetailScreen`: Detailed product view

3. **Cart Management**
   - `DataProvider`: Cart state management
   - `CartScreen`: Cart interface
   - `CheckoutScreen`: Checkout process

4. **AutoHub Booking**
   - `AutoHubScreen`: Service booking interface
   - Form components: Service selection, scheduling, etc.
   - Integration with backend services

5. **User Profile**
   - `UserProfileScreen`: User information management
   - `SettingsScreen`: App configuration

## 5. Implementation Status

### 5.1 Completed Features

- ✅ User authentication system
- ✅ Product browsing and catalog view
- ✅ Cart management and checkout
- ✅ Basic user profile management
- ✅ Home screen with categories and featured products
- ✅ AutoHub UI components and form

### 5.2 In Progress

- ⚠️ AutoHub service booking backend integration
- ⚠️ Email notifications for AutoHub appointments
- ⚠️ Admin panel notifications for new bookings
- ⚠️ Order status tracking and updates

### 5.3 Planned Features

- ⬜ Vehicle compatibility filtering
- ⬜ User vehicle management
- ⬜ Enhanced search functionality
- ⬜ Order history and tracking
- ⬜ Payment integration
- ⬜ Push notifications for order updates
