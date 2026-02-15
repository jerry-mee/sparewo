// lib/core/utils/timestamp_converter.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

/// Converts non-nullable Firestore Timestamps to DateTime
class TimestampConverter implements JsonConverter<DateTime, Object> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object json) {
    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.parse(json);
    }
    // Fallback or throw depending on strictness preference
    return DateTime.now();
  }

  @override
  Object toJson(DateTime date) {
    return Timestamp.fromDate(date);
  }
}

/// Converts nullable Firestore Timestamps to DateTime?
class NullableTimestampConverter implements JsonConverter<DateTime?, Object?> {
  const NullableTimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;

    if (json is Timestamp) {
      return json.toDate();
    } else if (json is String) {
      return DateTime.tryParse(json);
    }
    return null;
  }

  @override
  Object? toJson(DateTime? date) {
    return date != null ? Timestamp.fromDate(date) : null;
  }
}
