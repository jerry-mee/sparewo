import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    this.city,
    this.landmark,
    this.phone,
    this.recipientName,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String? city;
  final String? landmark;
  final String? phone;
  final String? recipientName;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get shortTitle {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isNotEmpty) return normalizedLabel;
    return 'Address';
  }

  String get fullAddress {
    final parts = <String>[
      line1.trim(),
      (line2 ?? '').trim(),
      (city ?? '').trim(),
      (landmark ?? '').trim(),
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  String get subtitle {
    final address = fullAddress;
    if (address.isNotEmpty) return address;
    return line1;
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? landmark,
    String? phone,
    String? recipientName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      landmark: landmark ?? this.landmark,
      phone: phone ?? this.phone,
      recipientName: recipientName ?? this.recipientName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory SavedAddress.fromMap(String id, Map<String, dynamic> map) {
    return SavedAddress(
      id: id,
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : 'Address',
      line1: (map['line1'] as String?)?.trim() ?? '',
      line2: (map['line2'] as String?)?.trim(),
      city: (map['city'] as String?)?.trim(),
      landmark: (map['landmark'] as String?)?.trim(),
      phone: (map['phone'] as String?)?.trim(),
      recipientName: (map['recipientName'] as String?)?.trim(),
      isDefault: map['isDefault'] == true,
      createdAt: _toDateTime(map['createdAt']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label.trim(),
      'line1': line1.trim(),
      'line2': line2?.trim(),
      'city': city?.trim(),
      'landmark': landmark?.trim(),
      'phone': phone?.trim(),
      'recipientName': recipientName?.trim(),
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    final asString = value?.toString();
    if (asString == null || asString.isEmpty) return null;
    return DateTime.tryParse(asString);
  }
}
