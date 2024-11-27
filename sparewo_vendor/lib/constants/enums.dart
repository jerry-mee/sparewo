import 'package:freezed_annotation/freezed_annotation.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

enum VendorStatus {
  pending,
  approved,
  suspended,
  rejected,
}

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

enum LoadingStatus {
  initial,
  loading,
  success,
  error,
}

enum ProductStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('suspended')
  suspended
}

enum PartCondition {
  @JsonValue('new')
  new_,
  @JsonValue('used')
  used
}

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
