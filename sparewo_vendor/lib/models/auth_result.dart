// lib/models/auth_result.dart

import './vendor.dart';
import './user_roles.dart';

class AuthResult {
  final Vendor? vendor;
  final String token;
  final bool isNewUser;
  final UserRoles? userRole;

  const AuthResult({
    this.vendor,
    required this.token,
    this.isNewUser = false,
    this.userRole,
  });

  AuthResult copyWith({
    Vendor? vendor,
    String? token,
    bool? isNewUser,
    UserRoles? userRole,
  }) {
    return AuthResult(
      vendor: vendor ?? this.vendor,
      token: token ?? this.token,
      isNewUser: isNewUser ?? this.isNewUser,
      userRole: userRole ?? this.userRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendor': vendor?.toJson(),
      'token': token,
      'isNewUser': isNewUser,
      'userRole': userRole?.toJson(),
    };
  }

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
      token: json['token'],
      isNewUser: json['isNewUser'] ?? false,
      userRole: json['userRole'] != null
          ? UserRoles.fromJson(json['userRole'])
          : null,
    );
  }
}
