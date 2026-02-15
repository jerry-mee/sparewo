// lib/providers/auth_state.dart

import '../models/vendor.dart';
import '../models/user_roles.dart';
import '../constants/enums.dart';

class AuthState {
  final bool isLoading;
  final Vendor? vendor;
  final String? error;
  final AuthStatus status;
  final bool isSkipped;
  final String? verificationEmail;
  final String? recoveryEmail;
  final bool showWelcomeDialog;
  final String? token;
  final UserRoles? userRole;

  const AuthState({
    this.isLoading = false,
    this.vendor,
    this.error,
    this.status = AuthStatus.initial,
    this.isSkipped = false,
    this.verificationEmail,
    this.recoveryEmail,
    this.showWelcomeDialog = false,
    this.token,
    this.userRole,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get needsReauthentication => status == AuthStatus.needsReauthentication;
  bool get hasError => error != null;
  bool get isAdmin => userRole?.isAdmin ?? false;
  bool get isEmailVerified => vendor?.isVerified ?? false;
  bool get canManageProducts => isAdmin || isEmailVerified;
  bool get canCreateProducts => isAdmin || isEmailVerified;

  AuthState copyWith({
    bool? isLoading,
    Vendor? vendor,
    String? error,
    AuthStatus? status,
    bool? isSkipped,
    String? verificationEmail,
    String? recoveryEmail,
    bool? showWelcomeDialog,
    String? token,
    UserRoles? userRole,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      vendor: vendor ?? this.vendor,
      error: error ?? this.error,
      status: status ?? this.status,
      isSkipped: isSkipped ?? this.isSkipped,
      verificationEmail: verificationEmail ?? this.verificationEmail,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      showWelcomeDialog: showWelcomeDialog ?? this.showWelcomeDialog,
      token: token ?? this.token,
      userRole: userRole ?? this.userRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLoading': isLoading,
      'vendor': vendor?.toJson(),
      'error': error,
      'status': status.name,
      'isSkipped': isSkipped,
      'verificationEmail': verificationEmail,
      'recoveryEmail': recoveryEmail,
      'showWelcomeDialog': showWelcomeDialog,
      'token': token,
      'userRole': userRole?.toJson(),
    };
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      isLoading: json['isLoading'] ?? false,
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
      error: json['error'],
      status: AuthStatus.values.byName(json['status'] ?? 'initial'),
      isSkipped: json['isSkipped'] ?? false,
      verificationEmail: json['verificationEmail'],
      recoveryEmail: json['recoveryEmail'],
      showWelcomeDialog: json['showWelcomeDialog'] ?? false,
      token: json['token'],
      userRole: json['userRole'] != null
          ? UserRoles.fromJson(json['userRole'])
          : null,
    );
  }
}
