# SpareWo Vendor App - Comprehensive Technical Documentation

## 1. Application Overview

### 1.1 Purpose
The SpareWo Vendor App is a cross-platform application that enables automotive parts vendors to manage their inventory, receive orders, track performance, and interact with the SpareWo marketplace ecosystem.

### 1.2 Technology Stack
- **Framework**: Flutter 3.x
- **State Management**: Riverpod 2.x
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Language**: Dart
- **Architecture**: Feature-first with Repository pattern
- **Code Generation**: Freezed for immutable models
- **Serialization**: json_serializable
- **Authentication**: Firebase Auth with Chrome Password Manager support

### 1.3 Platform Support
- Android (minimum SDK 21)
- iOS (minimum iOS 12.0)
- Web (Progressive Web App with responsive design)
- Desktop (macOS, Windows, Linux with responsive layouts)

### 1.4 Responsive Design Support
- Mobile: < 600px width
- Tablet: 600px - 1200px width
- Desktop: > 1200px width
- 4K Display Support: Up to 1600px max content width
- Retina/High DPI screen optimization

## 2. Architecture

### 2.1 Layer Architecture

**Presentation Layer**
- Screens (UI pages with responsive layouts)
- Widgets (Reusable UI components)
- Controllers (UI logic)
- Responsive wrappers for desktop/tablet views

**Business Logic Layer**
- Providers (State management)
- Notifiers (State mutation)
- Use Cases (Business rules)

**Data Layer**
- Services (External communication)
- Repositories (Data abstraction)
- Models (Data structures with safe enum parsing)

**Infrastructure Layer**
- Firebase configuration
- Network clients
- Local storage (Hive)
- Platform-specific implementations

### 2.2 Directory Structure

```
lib/
├── models/              # Data models with Freezed immutability
├── providers/           # Riverpod state management
├── screens/            # Feature-specific UI pages
│   ├── dashboard/
│   ├── products/
│   ├── orders/
│   ├── settings/
│   └── notifications/
├── services/           # Business logic and external integrations
├── widgets/            # Reusable UI components
│   ├── responsive_wrapper.dart
│   ├── custom_text_field.dart
│   └── ...
├── utils/              # Helper functions and extensions
├── constants/          # App-wide constants and enums
├── routes/             # Navigation configuration
└── theme.dart          # App theming
```

## 3. Core Features

### 3.1 Authentication & Onboarding

**Signup Flow**
1. Email/password registration with Chrome autofill support
2. Business information collection
3. Email verification via 6-digit code
4. Admin approval pending state
5. Dashboard access upon approval

**Login Flow**
1. Email/password authentication with autofill
2. Biometric authentication (if enabled)
3. Session persistence with secure storage
4. Automatic token refresh
5. Enter key support for form submission

**Security Features**
- JWT token management
- Secure credential storage
- Session timeout handling
- Device fingerprinting
- Chrome Password Manager integration via AutofillGroup

### 3.2 Product Management

**Product Creation**
- Multi-step form with validation
- Image capture and upload (up to 5 images)
- Vehicle compatibility selection
- Specific year compatibility
- Real-time inventory tracking
- Draft saving capability
- Responsive form layouts

**Product Listing**
- Grid/list view toggle
- Responsive grid columns based on screen size
- Status filtering (pending, approved, rejected, suspended)
- Search functionality
- Stock level indicators
- Bulk operations support

**Product Updates**
- Quick stock updates
- Price adjustments
- Image management
- Compatibility modifications
- Status tracking

### 3.3 Order Management

**Order Reception**
- Real-time order notifications via order_fulfillments collection
- Order detail viewing
- Customer information (protected)
- Delivery requirements
- Order acceptance/rejection

**Fulfillment Tracking**
- Status updates through fulfillment documents
- Delivery scheduling
- Completion confirmation
- Issue reporting

### 3.4 Dashboard & Analytics

**Performance Metrics**
- Total products
- Active orders
- Revenue tracking
- Average rating
- Daily/monthly statistics

**Visual Analytics**
- Responsive chart representations
- Trend analysis
- Comparative metrics
- Performance indicators

### 3.5 Notifications

**Types**
- Order notifications
- Product approval updates
- Stock alerts
- System announcements
- Promotional messages

**Delivery Methods**
- In-app notifications with badge count
- Push notifications (FCM)
- Email notifications
- SMS alerts (optional)

## 4. Data Models

### 4.1 Core Models

**Vendor Model**
```dart
- id: String
- businessName: String
- email: String
- phone: String
- businessAddress: String
- categories: List<String>
- isVerified: bool
- createdAt: DateTime
- updatedAt: DateTime
```

**VendorProduct Model**
```dart
- id: String
- vendorId: String
- partName: String
- description: String
- brand: String
- partNumber: String?
- condition: PartCondition (with legacy "new" support)
- qualityGrade: String
- stockQuantity: int
- unitPrice: double
- wholesalePrice: double?
- compatibility: List<VehicleCompatibility>
- images: List<String>
- status: ProductStatus
- reviewNotes: String?
- createdAt: DateTime
- updatedAt: DateTime
```

**Order Model (accessed via fulfillments)**
```dart
- id: String
- fulfillmentId: String
- vendorId: String
- productId: String
- quantity: int
- totalAmount: double
- status: OrderStatus
- deliveryAddress: String
- customerName: String
- createdAt: DateTime
```

### 4.2 Enum Handling

**PartCondition Enum**
- Special handling for legacy "new" values
- Maps "new" → "new_" automatically
- Safe parsing with fallback defaults

**ProductStatus Enum**
- pending
- approved
- rejected
- suspended

## 5. State Management

### 5.1 Provider Architecture

**Service Providers**
- Singleton instances with lazy initialization
- No more FutureProvider for initialization
- Dependency injection
- Lifecycle management

**State Notifiers**
- Immutable state
- Atomic updates
- Error handling
- Loading states

### 5.2 Key Providers

**AuthNotifier**
- Authentication state management
- User session handling
- Token refresh logic
- Logout handling

**VendorProductsNotifier**
- Product list management
- CRUD operations
- Real-time updates via vendor_products collection
- Filtering/sorting

**OrderNotifier**
- Order stream management via order_fulfillments
- Status updates
- Fulfillment tracking

## 6. Services Layer

### 6.1 Firebase Services

**FirebaseService**
- Authentication wrapper
- Firestore operations
- Error transformation
- Offline support

**Collection Structure**
- `vendors/` - Vendor profiles
- `vendor_products/` - Products uploaded by vendors
- `order_fulfillments/` - Order assignments to vendors
- `product_drafts/` - Unsaved product drafts
- `notifications/` - Vendor notifications

### 6.2 Business Services

**VendorProductService**
- CRUD operations on vendor_products collection
- Batch operations
- Search functionality
- Inventory management

**OrderService**
- Queries order_fulfillments for vendor orders
- Joins with orders collection for full data
- Status updates
- Stock management on order status changes

## 7. Responsive Design Implementation

### 7.1 Breakpoints
```dart
- Mobile: < 600px
- Tablet: 600px - 1200px  
- Desktop: ≥ 1200px
```

### 7.2 Layout Strategies

**ResponsiveWrapper Widget**
- Constrains content width on large screens
- Max width: 1600px for 4K displays
- Centered content with proper margins

**ResponsiveBuilder Widget**
- Different layouts for mobile/tablet/desktop
- Adaptive UI components
- Dynamic grid columns

### 7.3 Desktop-Specific Features
- Hover effects
- Keyboard navigation
- Multi-column layouts
- Side navigation panels
- Floating action buttons → Standard buttons

## 8. Security Implementation

### 8.1 Authentication Security
- Firebase Authentication integration
- Token-based authorization
- Biometric authentication
- Session management
- AutofillGroup for password managers

### 8.2 Data Security
- Firestore security rules
- Vendor isolation via fulfillments
- Row-level security
- Data encryption at rest
- Input validation and sanitization

### 8.3 App Security
- HTTPS enforcement
- Secure storage implementation
- Permission management
- No client-side admin operations

## 9. Chrome Password Manager Integration

### 9.1 Implementation
- AutofillGroup widgets wrap all forms
- Proper autofillHints on text fields
- Support for email, password, name, phone fields
- Enter key handling for form submission

### 9.2 Supported Fields
```dart
AutofillHints.email
AutofillHints.password
AutofillHints.newPassword
AutofillHints.name
AutofillHints.telephoneNumber
AutofillHints.streetAddressLine1
AutofillHints.organizationName
```

## 10. Performance Optimization

### 10.1 Image Handling
- Lazy loading with caching
- Progressive image loading
- Compression before upload
- Memory management for large images

### 10.2 Data Management
- Pagination for large lists
- Stream-based real-time updates
- Query optimization with indexes
- Offline-first with Firestore

### 10.3 UI Performance
- Widget recycling in lists
- Smooth animations (60fps)
- Responsive image sizing
- Debounced search inputs

## 11. Error Handling

### 11.1 Error Types
- Network errors
- Authentication errors
- Validation errors
- Permission errors (proper Firestore rules)
- Enum parsing errors (graceful fallbacks)

### 11.2 User Experience
- Friendly error messages
- Inline validation
- Loading states
- Empty states
- Retry mechanisms

## 12. Recent Updates & Fixes

### 12.1 Zone Mismatch Fix
- Wrapped app initialization in runZonedGuarded
- Ensures consistent zone usage

### 12.2 Collection Access Fix
- Orders accessed via order_fulfillments
- Proper vendor isolation
- Fixed permission denied errors

### 12.3 Enum Parsing Fix
- Safe parsing of PartCondition
- Legacy "new" value support
- Fallback to defaults

### 12.4 Responsive Design
- Desktop layouts for all screens
- 4K display support
- Proper constraints on large screens

### 12.5 Chrome Password Manager
- AutofillGroup implementation
- Proper autofillHints
- Enter key support

## 13. Testing Strategy

### 13.1 Unit Testing
- Model testing with enum edge cases
- Service testing with mock Firebase
- Provider testing
- Utility testing

### 13.2 Widget Testing
- Responsive layout testing
- Form autofill testing
- Navigation testing
- Error state testing

### 13.3 Integration Testing
- Authentication flow
- Product management flow
- Order fulfillment flow
- Cross-platform testing

## 14. Deployment

### 14.1 Build Configuration
- Environment variables
- Firebase configuration per platform
- Build flavors (dev, staging, prod)
- Version management

### 14.2 Platform-Specific
**Web**
- index.html optimization
- PWA manifest
- Service worker

**Desktop**
- Window size constraints
- Native menus
- File system access

**Mobile**
- App store configurations
- Push notification setup
- Deep linking

## 15. Maintenance & Migration

### 15.1 Data Migrations
- Condition value migration ("new" → "new_")
- Run via FixConditionMigration service

### 15.2 Regular Tasks
- Dependency updates
- Security patches
- Performance monitoring
- User feedback integration

## Appendix: Technical Decisions

### State Management
Riverpod chosen for type safety, testing capabilities, and superior dependency injection.

### Firebase Firestore Structure
Vendor isolation through order_fulfillments ensures proper data access control.

### Responsive Design
Desktop-first approach for business users while maintaining excellent mobile experience.

### Password Manager Support
Native autofill integration provides seamless authentication experience across platforms.