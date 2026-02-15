# SpareWo Vendor App - Technical Documentation

## 1. System Architecture

### 1.1 Overview

SpareWo is a comprehensive auto parts marketplace platform consisting of three main components:

1. **Admin Dashboard** (admin.sparewo.ug): Backend control panel for vetting vendors and products
2. **Vendor App** (vendor.sparewo.ug): Mobile and web application for auto parts suppliers
3. **Client App** (store.sparewo.ug): Consumer-facing marketplace for purchasing auto parts

This document focuses on the Vendor App architecture, which serves as the onboarding and inventory management platform for auto parts suppliers.

### 1.2 Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                       SpareWo Vendor App                         │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐ │
│ │  User Interface │ │  Business Logic │ │      Data Layer     │ │
│ ├─────────────────┤ ├─────────────────┤ ├─────────────────────┤ │
│ │ - Flutter UI    │ │ - Providers     │ │ - Firebase Services │ │
│ │ - Material      │ │ - State Notif.  │ │ - API Clients       │ │
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
- Products created by vendors are stored in Firestore
- Admin panel reviews and approves products for client visibility
- Approved products appear in the client marketplace
- Orders placed by clients trigger notifications to vendors

## 2. User Journey

### 2.1 Vendor User Flow

```
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Onboarding│     │Account        │     │ Email             │
│ & Signup  │────▶│Creation       │────▶│ Verification      │
└───────────┘     └───────────────┘     └───────────────────┘
                                                 │
                                                 ▼
┌───────────┐     ┌───────────────┐     ┌───────────────────┐
│ Inventory │◀────│   Dashboard   │◀────│ Business Profile  │
│ Management│     │               │     │ Setup             │
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

1. **Onboarding & Signup**
   - Welcome screen introduces SpareWo's value proposition
   - Vendor registration flow collects business information
   - Form validation ensures complete vendor profiles

2. **Account Creation**
   - Firebase Authentication creates secure vendor accounts
   - Vendor data stored in Firestore with pending status
   - Security measures prevent unauthorized access

3. **Email Verification**
   - Verification code sent to vendor's email
   - Multi-step verification process ensures legitimate businesses
   - Secure token-based verification system

4. **Business Profile Setup**
   - Vendors complete business details (name, address, categories)
   - Profile information used for order fulfillment
   - Business categorization for specialized product segments

5. **Dashboard**
   - Central hub showing pending approvals, orders, and stats
   - Quick access to all app functionality
   - Real-time updates for new orders and product status changes

6. **Inventory Management**
   - Product creation with detailed specifications
   - Vehicle compatibility selection for precise fitment
   - Image upload with multiple product angles
   - Pricing and stock management

7. **Order Management**
   - List of orders requiring fulfillment
   - Order status tracking and updates
   - Communication channel with SpareWo admins

8. **Order Fulfillment**
   - Step-by-step process for preparing orders
   - Delivery coordination with SpareWo
   - Order completion and confirmation

## 3. Technical Implementation

### 3.1 Core Technologies

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod + State Notifiers
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **Architecture**: Service-Repository-Provider pattern
- **Code Generation**: Freezed for immutable models
- **Form Management**: Custom form validation
- **Navigation**: Named routes with app_router
- **Error Handling**: Custom exception hierarchy

### 3.2 Authentication System

The app implements a comprehensive authentication system using Firebase Authentication:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ AuthScreen     │      │ Firebase Auth  │      │ Firestore      │
│ (UI Layer)     │      │ (Identity)     │      │ (User Data)    │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ AuthProvider   │      │ AuthStateManager│      │ UserRepository │
│ (State)        │◀────▶│ (Persistence)  │◀────▶│ (Data Access)  │
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
- Secure token storage and refresh
- Email verification system
- Password reset functionality
- Session management
- Role-based access control

### 3.3 Product Management System

The product management system allows vendors to create, edit, and manage auto parts:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Product Screens│      │ Firebase       │      │ Cloud Storage  │
│ (UI Layer)     │      │ Firestore      │      │ (Images)       │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ ProductProvider│      │ ProductService │      │ CameraService  │
│ (State)        │◀────▶│ (Business Logic)◀────▶│ (Image Upload) │
└────────────────┘      └────────────────┘      └────────────────┘
```

Key product management features:
- Detailed product information collection
- Vehicle compatibility selection
- Multiple image upload and management
- Product status tracking (pending, approved, rejected)
- Inventory and stock management
- Draft saving and restoration

### 3.4 Order Processing System

The order processing system handles incoming orders from clients:

```
┌────────────────┐      ┌────────────────┐      
│ Order Screens  │      │ Firebase       │      
│ (UI Layer)     │      │ Firestore      │      
└───────┬────────┘      └───────┬────────┘      
        │                       │                
        ▼                       ▼                
┌────────────────┐      ┌────────────────┐      
│ OrderProvider  │      │ OrderService   │      
│ (State)        │◀────▶│ (Business Logic)      
└────────────────┘      └────────────────┘      
```

Key order processing features:
- Real-time order notifications
- Order status management
- Order details view
- Fulfillment workflow
- Order history tracking

### 3.5 Notification System

The notification system keeps vendors informed about important events:

```
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ Notification UI│      │ Firebase       │      │ FCM            │
│ (UI Layer)     │      │ Firestore      │      │ (Push)         │
└───────┬────────┘      └───────┬────────┘      └───────┬────────┘
        │                       │                       │
        ▼                       ▼                       ▼
┌────────────────┐      ┌────────────────┐      ┌────────────────┐
│ NotificationPrv│      │ NotificationSvc│      │ UI Notification│
│ (State)        │◀────▶│ (Business Logic)◀────▶│ (User Feedback)│
└────────────────┘      └────────────────┘      └────────────────┘
```

Key notification features:
- In-app notifications list
- Push notifications (FCM)
- Type-based notification classification
- Read/unread status management
- Action-based notification responses

## 4. Component Structure

### 4.1 Directory Organization

```
lib/
├── main.dart                       # Application entry point
├── firebase_options.dart           # Firebase configuration
├── theme.dart                      # Global styling
├── auth/                           # Authentication components
├── constants/                      # Application constants
│   ├── api_constants.dart          # API endpoints and parameters
│   ├── enums.dart                  # Enumerations for app states
│   ├── notification_types.dart     # Notification categorization
│   └── route_paths.dart            # Navigation route definitions
├── exceptions/                     # Custom exception handling
│   ├── api_exceptions.dart         # Network/API exceptions
│   ├── auth_exceptions.dart        # Authentication exceptions
│   └── firebase_exceptions.dart    # Firebase-related exceptions
├── models/                         # Data structures
│   ├── vendor.dart                 # Vendor profile data
│   ├── vendor_product.dart         # Product data structure
│   ├── order.dart                  # Order data structure
│   ├── notification.dart           # Notification data structure
│   └── vehicle_compatibility.dart  # Vehicle fitment data
├── providers/                      # State management
│   ├── auth_provider.dart          # Authentication state
│   ├── vendor_product_provider.dart # Product management state
│   ├── order_provider.dart         # Order handling state
│   └── notification_provider.dart  # Notification state
├── routes/                         # Navigation
│   └── app_router.dart             # Central routing definition
├── screens/                        # Application UI screens
│   ├── authentication screens      # Login, signup, verification
│   ├── dashboard screens           # Main app screens
│   ├── product screens             # Product management
│   └── order screens               # Order management
├── services/                       # Business logic
│   ├── firebase_service.dart       # Firebase wrapper
│   ├── vendor_product_service.dart # Product operations
│   ├── order_service.dart          # Order operations
│   └── notification_service.dart   # Notification handling
└── widgets/                        # Reusable UI components
    ├── custom_text_field.dart      # Input controls
    ├── product_grid.dart           # Product display components
    └── vehicle_compatibility_selector.dart # Vehicle selection UI
```

### 4.2 Key Components

1. **Authentication**
   - `AuthNotifier`: Central authentication state management
   - `FirebaseService`: Firebase Authentication integration
   - `LoginScreen`, `SignupScreen`, `EmailVerificationScreen`: User-facing UI

2. **Product Management**
   - `VendorProductsNotifier`: Product state management
   - `VendorProductService`: CRUD operations for products
   - `AddEditProductScreen`, `ProductDetailScreen`: User interfaces

3. **Vehicle Compatibility**
   - `VehicleCompatibilitySelector`: Multi-select vehicle compatibility UI
   - `ExpandableYearSelector`: Year range selection component
   - Vehicle make/model data fetched from Firestore

4. **Order Processing**
   - `OrderNotifier`: Order state management
   - `OrderService`: Order status and fulfillment operations
   - `OrdersScreen`, `OrderDetailsScreen`: Order management UI

5. **Image Handling**
   - `CameraService`: Image capture and upload functionality
   - Multi-image support with upload progress
   - Firebase Storage integration

## 5. Implementation Status

### 5.1 Completed Features

- ✅ Vendor authentication system
- ✅ Email verification flow
- ✅ Product creation and management
- ✅ Vehicle compatibility selection
- ✅ Product image upload
- ✅ Basic order management
- ✅ Dashboard statistics
- ✅ Notification system

### 5.2 In Progress

- ⚠️ Vendor profile completion
- ⚠️ Enhanced order fulfillment workflow
- ⚠️ Advanced product search and filtering
- ⚠️ Real-time synchronization improvements

### 5.3 Planned Features

- ⬜ Vendor analytics dashboard
- ⬜ Integrated messaging system
- ⬜ Bulk product operations
- ⬜ Enhanced inventory management
- ⬜ Vendor ratings and performance metrics