/*
 * Filename: coupon_model.dart
 * Purpose: Data model for booking coupon codes (percent off, dollar off, or free)
 * Author: Kevin Doyle Jr. / Infinitum Imagery LLC
 * Last Modified: 2026-01-31
 * Dependencies: cloud_firestore, equatable, json_annotation
 * Platform Compatibility: iOS, Android, Web
 */

// MARK: - Imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'coupon_model.g.dart';

// MARK: - Coupon Discount Type Enum
/// Type of discount: percent off, fixed dollar amount off, or free (100% off)
enum CouponDiscountType {
  @JsonValue('percent')
  percent,
  @JsonValue('fixed')
  fixed,
  @JsonValue('free')
  free,
}

// MARK: - Coupon Model
/// Represents a coupon code that clients can apply at booking
/// Admin can set percent off, dollar amount off, or make the deposit free
@JsonSerializable()
class CouponModel extends Equatable {
  /// Unique identifier for the coupon
  final String id;

  /// Coupon code (case-insensitive when validating)
  final String code;

  /// Type of discount: percent, fixed amount, or free
  @JsonKey(defaultValue: CouponDiscountType.percent)
  final CouponDiscountType discountType;

  /// Percent off (0–100). Used when discountType is percent or free (100).
  /// When free, treat as 100% off deposit.
  final int? percentOff;

  /// Fixed amount off in cents. Used when discountType is fixed.
  final int? amountOffCents;

  /// Whether this coupon is active and can be used
  @JsonKey(defaultValue: true)
  final bool isActive;

  /// Optional: valid from date (null = no start limit)
  @JsonKey(fromJson: _timestampNullableFromJson, toJson: _timestampToJson)
  final DateTime? validFrom;

  /// Optional: valid until date (null = no end limit)
  @JsonKey(fromJson: _timestampNullableFromJson, toJson: _timestampToJson)
  final DateTime? validUntil;

  /// Optional: maximum number of times this coupon can be used (null = unlimited)
  final int? usageLimit;

  /// Number of times this coupon has been used (incremented when applied at booking)
  @JsonKey(defaultValue: 0)
  final int timesUsed;

  /// Timestamp when the coupon was created
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  /// Timestamp when the coupon was last updated
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  /// Optional description for admin reference
  final String? description;

  // MARK: - Constructor
  const CouponModel({
    required this.id,
    required this.code,
    this.discountType = CouponDiscountType.percent,
    this.percentOff,
    this.amountOffCents,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
    this.usageLimit,
    this.timesUsed = 0,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  // MARK: - Factory Constructors
  /// Create a CouponModel from Firestore document
  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponModel.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  /// Create a CouponModel from JSON
  factory CouponModel.fromJson(Map<String, dynamic> json) =>
      _$CouponModelFromJson(json);

  // MARK: - Conversion Methods
  /// Convert CouponModel to JSON
  Map<String, dynamic> toJson() => _$CouponModelToJson(this);

  /// Convert CouponModel to Firestore document data
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  // MARK: - Helper Methods
  /// Calculate discount amount in cents for a given deposit total in cents
  /// Returns the amount to subtract (0 to totalDepositCents)
  int calculateDiscountCents(int totalDepositCents) {
    switch (discountType) {
      case CouponDiscountType.free:
        return totalDepositCents;
      case CouponDiscountType.percent:
        final pct = (percentOff ?? 0).clamp(0, 100);
        return ((totalDepositCents * pct) / 100).round();
      case CouponDiscountType.fixed:
        final off = amountOffCents ?? 0;
        return off.clamp(0, totalDepositCents);
    }
  }

  /// Human-readable discount description for UI
  String get discountDescription {
    switch (discountType) {
      case CouponDiscountType.free:
        return 'Free';
      case CouponDiscountType.percent:
        return '${percentOff ?? 0}% off';
      case CouponDiscountType.fixed:
        final dollars = ((amountOffCents ?? 0) / 100).toStringAsFixed(2);
        return '\$$dollars off';
    }
  }

  /// Create a copy with updated fields
  CouponModel copyWith({
    String? id,
    String? code,
    CouponDiscountType? discountType,
    int? percentOff,
    int? amountOffCents,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? timesUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
  }) {
    return CouponModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      percentOff: percentOff ?? this.percentOff,
      amountOffCents: amountOffCents ?? this.amountOffCents,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      timesUsed: timesUsed ?? this.timesUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
    );
  }

  // MARK: - Equatable
  @override
  List<Object?> get props => [
        id,
        code,
        discountType,
        percentOff,
        amountOffCents,
        isActive,
        validFrom,
        validUntil,
        usageLimit,
        timesUsed,
        createdAt,
        updatedAt,
        description,
      ];

  // MARK: - Timestamp Helpers
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  static DateTime? _timestampNullableFromJson(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) return DateTime.parse(timestamp);
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return null;
  }

  static dynamic _timestampToJson(DateTime? dateTime) {
    if (dateTime == null) return null;
    return Timestamp.fromDate(dateTime);
  }
}

// Suggestions For Features and Additions Later:
// - Add minimum booking amount for coupon
// - Add service-specific or category-specific coupons
// - Add one-time-use-per-client option
// - Add expiry after first use
