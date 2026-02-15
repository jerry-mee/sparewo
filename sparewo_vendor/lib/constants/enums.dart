// lib/constants/enums.dart

// --- Core App & Authentication Enums ---

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  unverified,
  needsReauthentication,
  onboardingRequired,
}

enum LoadingStatus {
  initial,
  loading,
  success,
  error,
}

// --- Vendor & Product Enums ---

enum VendorStatus {
  pending,
  approved,
  suspended,
  rejected,
}

extension VendorStatusExt on VendorStatus {
  String get displayName {
    switch (this) {
      case VendorStatus.pending:
        return 'Pending';
      case VendorStatus.approved:
        return 'Approved';
      case VendorStatus.suspended:
        return 'Suspended';
      case VendorStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ProductStatus { pending, approved, rejected, suspended }

extension ProductStatusExt on ProductStatus {
  String get displayName {
    switch (this) {
      case ProductStatus.pending:
        return 'Pending';
      case ProductStatus.approved:
        return 'Approved';
      case ProductStatus.rejected:
        return 'Rejected';
      case ProductStatus.suspended:
        return 'Suspended';
    }
  }
}

enum PartCondition { new_, used }

extension PartConditionExt on PartCondition {
  String get displayName {
    switch (this) {
      case PartCondition.new_:
        return 'New';
      case PartCondition.used:
        return 'Used';
    }
  }
}

// Product Category Enum
enum ProductCategory {
  tyres,
  bodyKits,
  engine,
  electrical,
  chassis,
  accessories,
}

extension ProductCategoryExt on ProductCategory {
  String get displayName {
    switch (this) {
      case ProductCategory.tyres:
        return 'Tyres';
      case ProductCategory.bodyKits:
        return 'Body Kits';
      case ProductCategory.engine:
        return 'Engine';
      case ProductCategory.electrical:
        return 'Electrical';
      case ProductCategory.chassis:
        return 'Chassis';
      case ProductCategory.accessories:
        return 'Accessories';
    }
  }
}

// --- Order & Payment Enums ---

enum OrderStatus {
  pending,
  accepted,
  processing,
  readyForDelivery,
  delivered,
  cancelled,
  rejected,
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
}

// --- Notification Enums ---

enum NotificationType {
  order,
  orderUpdate,
  productUpdate,
  stockAlert,
  promotion,
  general,
  newMessage,
}

extension NotificationTypeExt on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.order:
        return 'New Order';
      case NotificationType.orderUpdate:
        return 'Order Update';
      case NotificationType.productUpdate:
        return 'Product Update';
      case NotificationType.stockAlert:
        return 'Stock Alert';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.general:
        return 'General';
      case NotificationType.newMessage:
        return 'New Message';
    }
  }
}
