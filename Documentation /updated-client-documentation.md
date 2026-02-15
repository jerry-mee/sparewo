# SpareWo Client App - Technical Documentation (v2.0)

## 1. System Architecture

### 1.1 Overview

SpareWo is a comprehensive automotive parts marketplace ecosystem:

1. **Admin Dashboard** (admin.sparewo.ug) - Strapi-based control panel
2. **Vendor App** (vendor.sparewo.ug) - Supplier management platform  
3. **Client App** (store.sparewo.ug) - Consumer marketplace (this document)

The Client App provides a seamless shopping experience where customers browse and purchase auto parts without knowing which vendor supplies them. All products appear to come directly from SpareWo.

### 1.2 Technical Stack

- **Framework**: Flutter 3.x (Dart)
- **State Management**: Riverpod 2.x with code generation
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Architecture**: Feature-first with Repository pattern
- **Models**: Freezed for immutability + json_serializable
- **Routing**: go_router for declarative navigation
- **UI**: Material 3 with custom theming
- **Platform Support**: Android, iOS, Web (responsive)

### 1.3 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    SpareWo Client App (Flutter)                  │
├─────────────────────────────────────────────────────────────────┤
│  Presentation Layer          Business Layer         Data Layer   │
│ ┌──────────────────┐    ┌──────────────────┐   ┌──────────────┐│
│ │ Screens          │    │ Providers         │   │ Repositories ││
│ │ - HomeScreen     │    │ - authProvider    │   │ - AuthRepo   ││
│ │ - CatalogScreen  │◄──►│ - cartProvider    │◄─►│ - CartRepo   ││
│ │ - CartScreen     │    │ - productProvider │   │ - ProductRepo││
│ │ - AutoHubScreen  │    │ - carProvider     │   │ - OrderRepo  ││
│ │ Widgets          │    │ State Notifiers   │   │ Firebase APIs││
│ └──────────────────┘    └──────────────────┘   └──────────────┘│
└─────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Firebase Backend                          │
├────────────────┬────────────────┬─────────────┬────────────────┤
│ Authentication │ Cloud Firestore │Cloud Storage│ Cloud Functions│
└────────────────┴────────────────┴─────────────┴────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    ▼                             ▼
         ┌──────────────────┐          ┌──────────────────┐
         │ catalog_products │          │ vendor_products  │
         │ (Client visible) │          │ (Vendor managed) │
         └──────────────────┘          └──────────────────┘
```

### 1.4 Data Flow

```
Client App ──► catalog_products ──► Admin Approval ──► vendor_products
     │                                      │                    │
     │                                      │                    │
     └─► Orders ──► Order Fulfillments ──► Vendor Assignment ◄──┘
```

## 2. Feature-First Architecture

### 2.1 Directory Structure

```
lib/
├── main.dart                          # App entry point with Firebase init
├── firebase_options.dart              # Firebase configuration
│
├── core/                              # Core functionality
│   ├── router/
│   │   └── app_router.dart           # go_router configuration
│   ├── theme/
│   │   └── app_theme.dart            # Material 3 theming
│   ├── utils/
│   │   └── timestamp_converter.dart  # Firestore timestamp handling
│   └── widgets/
│       ├── responsive_layout.dart    # Responsive design wrapper
│       └── max_width_wrapper.dart    # Content width constraints
│
├── features/                          # Feature modules
│   ├── auth/
│   │   ├── application/              # State management
│   │   │   └── auth_provider.dart    # Authentication state
│   │   ├── data/
│   │   │   └── auth_repository.dart  # Firebase Auth integration
│   │   ├── domain/
│   │   │   └── user_model.dart       # User data model
│   │   └── presentation/
│   │       └── login_screen.dart     # Authentication UI
│   │
│   ├── catalog/
│   │   ├── application/
│   │   │   └── product_provider.dart # Product state management
│   │   ├── data/
│   │   │   ├── catalog_repository.dart # Client product data
│   │   │   └── product_repository.dart # Legacy support
│   │   ├── domain/
│   │   │   ├── catalog_product_model.dart # Product model
│   │   │   └── product_model.dart         # Legacy model
│   │   └── presentation/
│   │       ├── catalog_screen.dart        # Product browsing
│   │       └── product_detail_screen.dart # Product details
│   │
│   ├── cart/
│   │   ├── application/
│   │   │   └── cart_provider.dart    # Cart state management
│   │   ├── data/
│   │   │   └── cart_repository.dart  # Cart persistence
│   │   ├── domain/
│   │   │   ├── cart_model.dart       # Cart data structure
│   │   │   └── cart_item_model.dart  # Cart item structure
│   │   └── presentation/
│   │       └── cart_screen.dart      # Cart UI
│   │
│   ├── my_car/
│   │   ├── application/
│   │   │   ├── car_provider.dart     # User vehicle state
│   │   │   └── car_data_provider.dart # Car brands/models
│   │   ├── data/
│   │   │   ├── car_repository.dart   # User vehicle CRUD
│   │   │   └── car_data_repository.dart # Brand/model data
│   │   ├── domain/
│   │   │   └── car_model.dart        # Vehicle model
│   │   └── presentation/
│   │       ├── my_cars_screen.dart   # Vehicle management
│   │       ├── add_car_screen.dart   # Add vehicle UI
│   │       └── widgets/
│   │           └── car_selector.dart # Vehicle selection
│   │
│   ├── autohub/
│   │   └── presentation/
│   │       ├── autohub_screen.dart   # Service booking main
│   │       └── autohub_conversational.dart # Booking flow
│   │
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart      # Landing page
│   │
│   ├── profile/
│   │   └── presentation/
│   │       └── profile_screen.dart   # User profile
│   │
│   └── shared/
│       ├── providers/
│       │   └── email_provider.dart   # Email notifications
│       └── services/
│           └── email_service.dart    # Resend integration
│
└── .env                              # Environment variables
```

### 2.2 State Management

Using Riverpod with code generation for type-safe, testable state management:

```dart
// Example: Cart Provider
@Riverpod(keepAlive: true)
class CartNotifier extends _$CartNotifier {
  @override
  FutureOr<CartModel> build() async {
    // Initialize cart from Firestore or local state
  }
  
  Future<void> addItem(String productId, int quantity) async {
    // Add item with Firestore persistence
  }
}
```

## 3. Database Schema

### 3.1 Collections Structure

```
Firestore Database
│
├── users/                         # User profiles and data
│   ├── {userId}/
│   │   ├── email: string
│   │   ├── name: string
│   │   ├── phone: string
│   │   ├── address: string
│   │   ├── createdAt: timestamp
│   │   └── updatedAt: timestamp
│   │   │
│   │   ├── cart/                 # User's cart (synced across devices)
│   │   │   └── {productId}/
│   │   │       ├── quantity: number
│   │   │       ├── addedAt: timestamp
│   │   │       └── updatedAt: timestamp
│   │   │
│   │   ├── cars/                 # User's vehicles
│   │   │   └── {carId}/
│   │   │       ├── make: string
│   │   │       ├── model: string
│   │   │       ├── year: number
│   │   │       ├── plateNumber: string
│   │   │       ├── isDefault: boolean
│   │   │       └── createdAt: timestamp
│   │   │
│   │   └── addresses/            # Saved addresses
│   │       └── {addressId}/
│   │           ├── label: string
│   │           ├── street: string
│   │           ├── city: string
│   │           ├── isDefault: boolean
│   │           └── createdAt: timestamp
│
├── catalog_products/              # Client-visible products
│   └── {productId}/
│       ├── partName: string
│       ├── description: string
│       ├── brand: string
│       ├── category: string
│       ├── unitPrice: number
│       ├── stockQuantity: number
│       ├── imageUrls: array
│       ├── partNumber: string
│       ├── condition: string
│       ├── isActive: boolean
│       ├── isFeatured: boolean
│       └── createdAt: timestamp
│
├── orders/                        # Client orders
│   └── {orderId}/
│       ├── userId: string
│       ├── orderNumber: string
│       ├── items: array
│       ├── totalAmount: number
│       ├── status: string
│       ├── deliveryAddress: map
│       ├── paymentMethod: string
│       ├── createdAt: timestamp
│       └── updatedAt: timestamp
│
├── service_bookings/              # AutoHub appointments
│   └── {bookingId}/
│       ├── userId: string
│       ├── carId: string
│       ├── serviceType: string
│       ├── urgency: string
│       ├── scheduledDate: timestamp
│       ├── timeSlot: string
│       ├── status: string
│       ├── notes: string
│       └── createdAt: timestamp
│
├── car_brand/                     # Vehicle manufacturers
│   └── {brandId}/
│       └── name: string
│
├── car_models/                    # Vehicle models
│   └── {modelId}/
│       ├── car_makeid: string
│       └── model: string
│
└── user_settings/                 # App preferences
    └── {userId}/
        ├── notifications: boolean
        ├── theme: string
        └── language: string
```

### 3.2 Security Rules

```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Catalog products are public read
    match /catalog_products/{productId} {
      allow read: if true;
      allow write: if false; // Only admin can write
    }
    
    // Orders - users can read their own
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
      allow update: if false; // Only admin/system
    }
    
    // Car data is public read
    match /car_brand/{brandId} {
      allow read: if true;
      allow write: if false;
    }
    
    match /car_models/{modelId} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

## 4. Key Features

### 4.1 Cross-Platform Cart Sync

The cart is stored in Firestore under `users/{userId}/cart/`, ensuring:
- Real-time sync across all devices
- Persistence between sessions
- Guest users use local state until login
- Automatic merge on authentication

### 4.2 Product Catalog

- Shows only admin-approved products from `catalog_products`
- No vendor information visible to clients
- Real-time stock updates
- Category and search filtering
- Featured products on home screen

### 4.3 AutoHub Service Booking

- Multi-step booking flow
- Vehicle selection from saved cars
- Service type and urgency selection
- Calendar-based scheduling
- Email confirmation via Resend API

### 4.4 User Vehicle Management

- Add multiple vehicles
- Auto-complete from car brands/models database
- Set default vehicle for quick selection
- Used for service bookings and compatibility

## 5. Integration Points

### 5.1 Email Service (Resend)

```dart
// Email notifications for:
- Order confirmations
- Service booking confirmations
- Welcome emails
- Password reset
```

### 5.2 Firebase Services

```dart
// Authentication
- Email/password login
- Guest browsing
- Session management

// Firestore
- Real-time data sync
- Offline capability
- Optimistic updates

// Storage
- Product images
- User avatars
```

## 6. Development Guidelines

### 6.1 Code Standards

- Use Freezed for all models
- Implement repository pattern for data access
- Keep business logic in providers
- UI components should be stateless when possible
- Follow feature-first organization

### 6.2 Testing Strategy

- Unit tests for repositories and providers
- Widget tests for UI components
- Integration tests for critical flows
- Mock Firebase services in tests

### 6.3 Performance Optimization

- Lazy load images with CachedNetworkImage
- Paginate large lists
- Use StreamBuilder for real-time data
- Implement proper loading states
- Cache frequently accessed data

## 7. Deployment

### 7.1 Environment Configuration

```bash
# .env file
RESEND_API_KEY=your_api_key
SENDER_EMAIL=garage@sparewo.ug
APP_NAME=SpareWo
```

### 7.2 Build Commands

```bash
# Web
flutter build web --release

# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 7.3 Hosting

- Web: Firebase Hosting at store.sparewo.ug
- Android: Google Play Store
- iOS: Apple App Store

## 8. Maintenance

### 8.1 Regular Tasks

- Update dependencies monthly
- Monitor Firebase usage and costs
- Review crash reports
- Update car brands/models database
- Archive old orders

### 8.2 Monitoring

- Firebase Analytics for user behavior
- Crashlytics for error tracking
- Performance monitoring
- User feedback collection

## 9. Future Enhancements

- [ ] Payment gateway integration (Mobile Money, Cards)
- [ ] Push notifications
- [ ] Advanced search with filters
- [ ] User reviews and ratings
- [ ] Loyalty program
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Offline mode improvements