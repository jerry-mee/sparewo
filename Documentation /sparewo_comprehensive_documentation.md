# SpareWo Platform - Complete Technical Implementation Guide

## Table of Contents
1. [Platform Architecture](#1-platform-architecture)
2. [Data Models & Collections](#2-data-models--collections)
3. [Authentication System](#3-authentication-system)
4. [Service Layer Architecture](#4-service-layer-architecture)
5. [State Management](#5-state-management)
6. [API Endpoints & Cloud Functions](#6-api-endpoints--cloud-functions)
7. [Security & Permissions](#7-security--permissions)
8. [Error Handling & Recovery](#8-error-handling--recovery)
9. [Implementation Checklist](#9-implementation-checklist)
10. [Troubleshooting Guide](#10-troubleshooting-guide)

## 1. Platform Architecture

### 1.1 System Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SpareWo Ecosystem                              │
├─────────────────────────┬─────────────────────┬────────────────────────┤
│    Admin Dashboard      │    Vendor App       │     Client App         │
│  (admin.sparewo.ug)     │(vendor.sparewo.ug)  │  (store.sparewo.ug)    │
├─────────────────────────┼─────────────────────┼────────────────────────┤
│ Technologies:           │ Technologies:       │ Technologies:          │
│ • Next.js/React        │ • Flutter           │ • Flutter              │
│ • TypeScript           │ • Dart              │ • Dart                 │
│ • Firebase Admin SDK   │ • Riverpod          │ • Riverpod             │
│ • Tailwind CSS         │ • Freezed           │ • Provider             │
├─────────────────────────┴─────────────────────┴────────────────────────┤
│                        Shared Infrastructure                            │
├─────────────────────────────────────────────────────────────────────────┤
│ • Firebase Auth (Multi-tenant)                                          │
│ • Cloud Firestore (NoSQL Database)                                      │
│ • Cloud Storage (Images & Documents)                                    │
│ • Cloud Functions (Business Logic)                                      │
│ • Resend API (Email Service)                                           │
│ • Firebase Cloud Messaging (Push Notifications)                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Inter-App Communication Flow

```
Vendor App                    Firebase                    Admin Dashboard
    │                            │                              │
    ├── Create Product ─────────>│                              │
    │                            ├── vendor_products            │
    │                            │                              │
    │                            ├── Trigger Function ─────────>│
    │                            │                              ├── Review
    │                            │                              │
    │                            │<──── Approve/Reject ─────────┤
    │                            ├── catalog_products           │
    │                            │                              │
Client App                       │                              │
    │                            │                              │
    ├── Browse Products ────────>│                              │
    │<──── catalog_products ─────┤                              │
    │                            │                              │
    ├── Place Order ─────────────>│                              │
    │                            ├── orders collection          │
    │                            ├── Notify Vendor ─────────────┤
    │                            │                              │
```

## 2. Data Models & Collections

### 2.1 Core Collections

#### vendors Collection
```typescript
interface Vendor {
  // Identity
  id: string;              // Firebase Auth UID
  email: string;           // Login email
  name: string;            // Personal name
  phone: string;           // Contact number
  
  // Business Information
  businessName: string;    // Store name
  businessAddress: string; // Physical location
  categories: string[];    // Product categories
  businessHours?: Map<string, BusinessHours>;
  
  // Verification & Status
  isVerified: boolean;     // Email verified
  status: 'pending' | 'approved' | 'suspended' | 'rejected';
  
  // Metadata
  rating: number;          // Average rating (0-5)
  completedOrders: number; // Total fulfilled
  totalProducts: number;   // Active products
  
  // System
  fcmToken?: string;       // Push notifications
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### vendor_products Collection
```typescript
interface VendorProduct {
  // Identity
  id: string;              // Auto-generated
  vendorId: string;        // Owner reference
  
  // Product Details
  partName: string;        // Display name
  partNumber?: string;     // Manufacturer code
  brand: string;           // Manufacturer
  description: string;     // Full description
  
  // Inventory
  stockQuantity: number;   // Available units
  unitPrice: number;       // Price in UGX
  condition: 'new' | 'used';
  qualityGrade: 'A' | 'B' | 'C';
  
  // Media
  images: string[];        // Storage URLs
  
  // Compatibility
  compatibility: VehicleCompatibility[];
  
  // Status
  status: 'pending' | 'approved' | 'rejected' | 'suspended';
  
  // Metadata
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### orders Collection
```typescript
interface Order {
  // Identity
  id: string;              // Auto-generated
  orderNumber: string;     // Human-readable
  
  // Parties
  customerId: string;      // Buyer
  vendorId: string;        // Seller
  
  // Items
  items: OrderItem[];
  
  // Pricing
  subtotal: number;
  tax: number;
  deliveryFee: number;
  totalAmount: number;
  
  // Status
  status: 'pending' | 'accepted' | 'processing' | 
          'readyForDelivery' | 'delivered' | 
          'cancelled' | 'rejected';
  paymentStatus: 'pending' | 'paid' | 'failed' | 'refunded';
  
  // Delivery
  deliveryAddress: Address;
  deliveryMethod: 'pickup' | 'delivery';
  
  // Timestamps
  createdAt: Timestamp;
  acceptedAt?: Timestamp;
  deliveredAt?: Timestamp;
}
```

#### Vehicle Data Collections
```typescript
// car_brand Collection
interface CarBrand {
  id: number;           // Numeric identifier
  part_name: string;    // "MERCEDES-BENZ", "TOYOTA"
  // Migration metadata
  originalId: number;
  originalTable: string;
}

// car_models Collection  
interface CarModel {
  id: number;           // Auto-increment
  car_makeid: string;   // String version of brand.id
  model: string;        // "CAMRY", "E-CLASS"
  // Migration metadata
  originalId: number;
  originalTable: string;
}
```

### 2.2 Supporting Collections

#### notifications Collection
```typescript
interface VendorNotification {
  id: string;
  recipientId: string;     // vendorId
  type: 'order' | 'orderUpdate' | 'productUpdate' | 
        'stockAlert' | 'promotion' | 'general';
  title: string;
  message: string;
  data?: Map<string, dynamic>;
  isRead: boolean;
  createdAt: Timestamp;
}
```

#### verificationCodes Collection
```typescript
interface VerificationCode {
  email: string;          // Document ID
  code: string;           // 6-digit code
  attempts: number;       // Failed attempts
  verified: boolean;      // Success flag
  created_at: Timestamp;
  expires_at: Timestamp;  // 30 minutes
  verified_at?: Timestamp;
}
```

#### userRoles Collection
```typescript
interface UserRoles {
  uid: string;            // Document ID
  role: 'vendor' | 'admin' | 'super_admin';
  isAdmin: boolean;       // Quick check
  permissions?: string[]; // Granular permissions
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

## 3. Authentication System

### 3.1 Authentication Flow

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│   Signup    │────>│ Firebase Auth   │────>│ Create Vendor│
└─────────────┘     └─────────────────┘     └──────────────┘
                             │                       │
                             ▼                       ▼
                    ┌─────────────────┐     ┌──────────────┐
                    │ Send Email Code │     │ Create Role  │
                    └─────────────────┘     └──────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Verify Email    │
                    └─────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Dashboard Access│
                    └─────────────────┘
```

### 3.2 AuthNotifier State Machine

```typescript
enum AuthStatus {
  initial,               // App startup
  loading,               // Auth operation in progress
  authenticated,         // Verified vendor logged in
  unauthenticated,       // No user session
  unverified,           // Logged in but email not verified
  onboardingRequired,   // Auth exists but no vendor profile
  needsReauthentication,// Token expired
  error                 // Auth operation failed
}
```

### 3.3 Verification Service

The `VerificationService` generates cryptographically secure 6-digit codes:

```dart
String _generateVerificationCode() {
  final random = Random.secure();
  return List.generate(6, (_) => random.nextInt(10)).join();
}
```

**Security Features:**
- 30-minute expiration
- 5 attempt limit
- Rate limiting per email
- Secure random generation

### 3.4 Storage Service

Manages persistent authentication state:

```dart
class StorageService {
  // Keys matching legacy AuthStateManager for compatibility
  static const String _authTokenKey = 'auth_token';
  static const String _vendorIdKey = 'vendor_id';
  static const String _userRoleKey = 'user_role';
  static const String _emailKey = 'user_email';
  static const String _isAuthenticatedKey = 'is_authenticated';
}
```

## 4. Service Layer Architecture

### 4.1 Service Hierarchy

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer (Screens)                    │
├─────────────────────────────────────────────────────────┤
│                 State Management (Riverpod)              │
├─────────────────────────────────────────────────────────┤
│                    Service Layer                         │
├──────────────┬──────────────┬──────────────────────────┤
│ FirebaseService │ EmailService │ VerificationService    │
│ OrderService    │ StatsService │ NotificationService    │
│ VendorProductService │ CameraService │ StorageService   │
├─────────────────────────────────────────────────────────┤
│                 Firebase SDK Layer                       │
├──────────────┬──────────────┬──────────────────────────┤
│ Firebase Auth │ Firestore    │ Cloud Storage            │
└──────────────┴──────────────┴──────────────────────────┘
```

### 4.2 Key Services

#### FirebaseService
- Wraps Firebase Auth operations
- Handles vendor profile CRUD
- Manages vehicle data queries
- Error transformation

#### VendorProductService
- Product CRUD operations
- Image upload orchestration
- Stock management
- Bulk operations

#### NotificationService
- Real-time notification streams
- Unread count tracking
- Notification creation
- Mark as read

#### StatsService
- Dashboard statistics
- Sales analytics
- Order metrics
- Performance tracking

## 5. State Management

### 5.1 Provider Architecture

```dart
// Service Providers (Singletons)
final firebaseServiceProvider = Provider<FirebaseService>
final storageServiceProvider = FutureProvider<StorageService>
final emailServiceProvider = Provider<EmailService>

// Feature Providers (Stateful)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>
final vendorProductsProvider = StateNotifierProvider<VendorProductsNotifier, AsyncValue<List>>
final orderNotifierProvider = StateNotifierProvider<OrderNotifier, OrderState>

// Computed Providers (Derived)
final currentVendorProvider = Provider<Vendor?>
final isAuthenticatedProvider = Provider<bool>
final filteredProductsProvider = Provider.family<List<Product>, String?>
```

### 5.2 State Flow

```
User Action → Notifier → Service → Firebase → Response
     ↓                                            ↓
    UI ←──── State Update ←──── Notifier ←───────┘
```

## 6. API Endpoints & Cloud Functions

### 6.1 Cloud Functions (Required)

```typescript
// Product Approval Workflow
exports.onProductCreated = functions.firestore
  .document('vendor_products/{productId}')
  .onCreate(async (snap, context) => {
    // 1. Notify admins
    // 2. Run automated checks
    // 3. Update vendor stats
  });

// Order Assignment
exports.onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    // 1. Notify vendor
    // 2. Update inventory
    // 3. Send confirmation email
  });

// Stats Aggregation
exports.updateVendorStats = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    // 1. Calculate vendor metrics
    // 2. Update dashboard_stats
  });
```

### 6.2 Email Integration (Resend API)

```typescript
// Email Templates
interface EmailTemplates {
  verificationCode: {
    to: string;
    code: string;
    isVendor: boolean;
  };
  
  orderConfirmation: {
    to: string;
    orderId: string;
    items: OrderItem[];
  };
  
  welcomeVendor: {
    to: string;
    vendorName: string;
  };
}
```

## 7. Security & Permissions

### 7.1 Firestore Security Rules

```javascript
// Critical Rules for Vendor App
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Vendor signup flow
    match /vendors/{vendorId} {
      // Allow self-registration
      allow create: if request.auth.uid == vendorId &&
        request.resource.data.keys().hasAll(['email', 'name', 'phone', 'businessName']);
      
      // Allow self-read and update
      allow read, update: if request.auth.uid == vendorId || isAdmin();
      
      // Only admins can delete
      allow delete: if isAdmin();
    }
    
    // User roles creation
    match /userRoles/{userId} {
      // Allow self-creation during signup
      allow create: if request.auth.uid == userId;
      allow read: if request.auth.uid == userId || isAdmin();
      allow update, delete: if isAdmin();
    }
    
    // Product management
    match /vendor_products/{productId} {
      // Vendors create their own products
      allow create: if request.auth.uid == request.resource.data.vendorId;
      
      // Read own products or if admin
      allow read: if request.auth.uid == resource.data.vendorId || isAdmin();
      
      // Update own products
      allow update: if request.auth.uid == resource.data.vendorId || isAdmin();
      
      // Delete own products
      allow delete: if request.auth.uid == resource.data.vendorId || isAdmin();
    }
    
    // Vehicle data (public read)
    match /car_brand/{document=**} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /car_models/{document=**} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

### 7.2 API Security

```dart
// Request signing
class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'X-Platform': 'vendor-app',
      'X-Version': packageInfo.version,
    };
  }
}
```

## 8. Error Handling & Recovery

### 8.1 Error Hierarchy

```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
}

class AuthException extends AppException
class FirestoreException extends AppException  
class StorageException extends AppException
class NetworkException extends AppException
class ValidationException extends AppException
```

### 8.2 Error Recovery Strategies

```dart
// Retry with exponential backoff
Future<T> retryWithBackoff<T>(Future<T> Function() operation) async {
  int attempts = 0;
  while (attempts < 3) {
    try {
      return await operation();
    } catch (e) {
      attempts++;
      if (attempts >= 3) rethrow;
      await Future.delayed(Duration(seconds: pow(2, attempts)));
    }
  }
}

// Offline queue for critical operations
class OfflineQueue {
  void enqueue(Operation operation) {
    // Store in local database
    // Retry when connection restored
  }
}
```

## 9. Implementation Checklist

### 9.1 Initial Setup
- [ ] Firebase project created
- [ ] Flutter app configured
- [ ] Environment variables set (.env file)
- [ ] Firebase services enabled (Auth, Firestore, Storage)
- [ ] Resend API key configured
- [ ] App bundle identifiers set

### 9.2 Backend Setup
- [ ] Firestore collections created
- [ ] Security rules deployed
- [ ] Cloud Functions deployed
- [ ] Indexes created
- [ ] Initial data seeded (car brands/models)

### 9.3 App Configuration
- [ ] Dependencies installed
- [ ] Code generation run
- [ ] Assets configured
- [ ] Deep links configured
- [ ] Push notifications setup

### 9.4 Testing Checklist
- [ ] Signup flow works
- [ ] Email verification works
- [ ] Login flow works
- [ ] Product creation works
- [ ] Order management works
- [ ] Offline functionality works

## 10. Troubleshooting Guide

### 10.1 Common Issues

#### PigeonUserDetails Type Error
**Symptom**: `type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'`
**Cause**: Firebase Auth plugin version mismatch
**Solution**: 
```yaml
dependencies:
  firebase_auth: ^4.17.0
  firebase_core: ^2.25.0
```

#### Car Models Not Loading
**Symptom**: 0 models returned for any brand
**Cause**: Data type mismatch (numeric vs string)
**Solution**: Ensure `car_makeid` in car_models matches `id` type in car_brand

#### Permission Denied
**Symptom**: Firestore permission denied on signup
**Cause**: Security rules blocking vendor creation
**Solution**: Update rules to allow self-registration

#### Null Check Error
**Symptom**: App crashes on startup with null check error
**Cause**: Service initialization order
**Solution**: Ensure StorageService initializes before AuthNotifier

### 10.2 Debug Commands

```bash
# Clear all caches
flutter clean
rm -rf ~/.pub-cache
flutter pub get

# Regenerate code
flutter pub run build_runner build --delete-conflicting-outputs

# Check Firebase setup
flutterfire configure

# Verify environment
flutter doctor -v
```

### 10.3 Monitoring

```dart
// Add comprehensive logging
class LoggerService {
  void logAuthEvent(String event, Map<String, dynamic> params) {
    FirebaseAnalytics.instance.logEvent(
      name: 'auth_$event',
      parameters: params,
    );
  }
  
  void logError(String message, dynamic error, StackTrace? stack) {
    FirebaseCrashlytics.instance.recordError(error, stack);
  }
}
```

## Appendix: Data Migration Scripts

### Migrate Vehicle Data
```javascript
// Firestore Admin SDK script
async function migrateVehicleData() {
  const brands = await db.collection('car_brand').get();
  
  for (const brand of brands.docs) {
    const brandData = brand.data();
    const numericId = brandData.id;
    
    // Find all models for this brand
    const models = await db.collection('car_models')
      .where('car_makeid', '==', numericId.toString())
      .get();
      
    console.log(`Brand: ${brandData.part_name}, Models: ${models.size}`);
  }
}
```

This comprehensive guide covers all aspects of the SpareWo platform implementation with specific details for troubleshooting and integration.