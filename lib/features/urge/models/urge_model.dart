// lib/features/urge/models/urge_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UrgeModel {
  final String id;
  final String type;
  final int intensity;
  final String emotion;
  final String trigger;
  final String notes;
  final String context;       // "Alone" | "With people" | "Online" | "Working" | etc.
  final String bodyLocation;  // Where the urge is felt physically
  final String timeOfDayLabel;// "Morning" | "Afternoon" | "Evening" | "Night"
  final DateTime timestamp;
  final String date;
  final int hour;

  UrgeModel({
    required this.id,
    required this.type,
    required this.intensity,
    required this.emotion,
    required this.timestamp,
    this.trigger = '',
    this.notes = '',
    this.context = '',
    this.bodyLocation = '',
    this.timeOfDayLabel = '',
    required this.date,
    required this.hour,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'intensity': intensity,
      'emotion': emotion,
      'trigger': trigger,
      'notes': notes,
      'context': context,
      'bodyLocation': bodyLocation,
      'timeOfDayLabel': timeOfDayLabel,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'hour': hour,
    };
  }

  factory UrgeModel.fromMap(String id, Map<String, dynamic> map) {
    return UrgeModel(
      id: id,
      type: map['type'] ?? '',
      intensity: (map['intensity'] as num?)?.toInt() ?? 0,
      emotion: map['emotion'] ?? '',
      trigger: map['trigger'] ?? '',
      notes: map['notes'] ?? '',
      context: map['context'] ?? '',
      bodyLocation: map['bodyLocation'] ?? '',
      timeOfDayLabel: map['timeOfDayLabel'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      date: map['date'] ?? '',
      hour: (map['hour'] as num?)?.toInt() ?? 0,
    );
  }

  /// Human-readable intensity label
  String get intensityLabel {
    if (intensity <= 2) return 'Minimal';
    if (intensity <= 4) return 'Low';
    if (intensity <= 6) return 'Moderate';
    if (intensity <= 8) return 'High';
    return 'Extreme';
  }

  /// Color value int for intensity (used in UI)
  int get intensityColorValue {
    if (intensity <= 3) return 0xFF00C853;
    if (intensity <= 5) return 0xFFFFD600;
    if (intensity <= 7) return 0xFFFF6D00;
    return 0xFFE53935;
  }
}