/// Request DTOs for the Settl backend API.
///
/// These are wire bodies: nullable fields are omitted from the JSON when null
/// so the backend's defaulting applies. Money in requests is rupee doubles
/// (the backend converts to paise), mirroring `models.go` request structs.
/// Every DTO that can be enqueued for offline replay also implements
/// `fromJson` so the queue payload round-trips unchanged (Phase 8).
library;

/// Body for `POST /v1/profile` (T7.1).
class ApiCreateProfileRequest {
  const ApiCreateProfileRequest({
    required this.displayName,
    required this.phoneNumber,
    this.upiId,
  });

  final String displayName;
  final String phoneNumber;
  final String? upiId;

  factory ApiCreateProfileRequest.fromJson(Map<String, dynamic> json) =>
      ApiCreateProfileRequest(
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
        upiId: json['upi_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'display_name': displayName,
        'phone_number': phoneNumber,
        if (upiId != null) 'upi_id': upiId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateProfileRequest &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber &&
          other.upiId == upiId;

  @override
  int get hashCode => Object.hash(displayName, phoneNumber, upiId);

  @override
  String toString() => 'ApiCreateProfileRequest(displayName: $displayName, '
      'phoneNumber: $phoneNumber, upiId: $upiId)';
}

/// Body for `POST /v1/contacts` (T7.2).
class ApiCreateContactRequest {
  const ApiCreateContactRequest({
    this.id,
    required this.displayName,
    required this.phoneNumber,
  });

  /// Optional client-generated participant id; the backend generates one when
  /// absent.
  final String? id;
  final String displayName;
  final String phoneNumber;

  factory ApiCreateContactRequest.fromJson(Map<String, dynamic> json) =>
      ApiCreateContactRequest(
        id: json['id'] as String?,
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'display_name': displayName,
        'phone_number': phoneNumber,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateContactRequest &&
          other.id == id &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber;

  @override
  int get hashCode => Object.hash(id, displayName, phoneNumber);

  @override
  String toString() =>
      'ApiCreateContactRequest(id: $id, displayName: $displayName, '
      'phoneNumber: $phoneNumber)';
}

/// Body for `POST /v1/contacts/claim` (T7.2).
class ApiClaimContactsRequest {
  const ApiClaimContactsRequest({required this.phoneNumber});

  final String phoneNumber;

  Map<String, dynamic> toJson() => {'phone_number': phoneNumber};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiClaimContactsRequest && other.phoneNumber == phoneNumber;

  @override
  int get hashCode => phoneNumber.hashCode;

  @override
  String toString() => 'ApiClaimContactsRequest(phoneNumber: $phoneNumber)';
}

/// Body for `POST /v1/groups/` (T7.3).
class ApiCreateCollectionRequest {
  const ApiCreateCollectionRequest({
    this.id,
    required this.name,
    this.currency,
  });

  /// Optional client-generated list id; the backend generates one when absent.
  final String? id;
  final String name;

  /// ISO 4217 code; defaults to `"INR"` server-side.
  final String? currency;

  factory ApiCreateCollectionRequest.fromJson(Map<String, dynamic> json) =>
      ApiCreateCollectionRequest(
        id: json['id'] as String?,
        name: json['name'] as String,
        currency: json['currency'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (currency != null) 'currency': currency,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateCollectionRequest &&
          other.id == id &&
          other.name == name &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(id, name, currency);

  @override
  String toString() =>
      'ApiCreateCollectionRequest(id: $id, name: $name, currency: $currency)';
}

/// Body for `POST /v1/groups/{groupId}/members` (T7.3).
class ApiAddMemberRequest {
  const ApiAddMemberRequest({required this.userId});

  /// Participant id of the member to add.
  final String userId;

  Map<String, dynamic> toJson() => {'user_id': userId};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiAddMemberRequest && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'ApiAddMemberRequest(userId: $userId)';
}

/// Body for `POST /v1/expenses/` and `PUT /v1/expenses/{id}` (T7.4).
class ApiCreateExpenseRequest {
  const ApiCreateExpenseRequest({
    this.id,
    this.groupId,
    required this.payerId,
    required this.amount,
    required this.splitType,
    this.category,
    this.note,
    this.idempotencyKey,
    this.timestamp,
    this.splits = const [],
  });

  /// Optional client-generated expense id; the backend generates one when
  /// absent (required to make retries idempotent alongside [idempotencyKey]).
  final String? id;

  /// Collection (group) id; expenses may be group-less (personal).
  final String? groupId;

  /// The backend forces this to the authenticated caller.
  final String payerId;

  /// Total amount in rupees (the backend stores paise).
  final double amount;

  /// One of `"equal" | "exact" | "percentage" | "shares"`.
  final String splitType;

  /// Defaults to `"Uncategorized"` server-side.
  final String? category;

  final String? note;
  final String? idempotencyKey;

  /// RFC3339 timestamp; defaults to the server time when absent.
  final String? timestamp;

  /// Per-participant split instructions; resolved server-side.
  final List<ApiCreateSplitItem> splits;

  factory ApiCreateExpenseRequest.fromJson(Map<String, dynamic> json) =>
      ApiCreateExpenseRequest(
        id: json['id'] as String?,
        groupId: json['group_id'] as String?,
        payerId: json['payer_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        splitType: json['split_type'] as String,
        category: json['category'] as String?,
        note: json['note'] as String?,
        idempotencyKey: json['idempotency_key'] as String?,
        timestamp: json['timestamp'] as String?,
        splits: (json['splits'] as List? ?? const [])
            .map((e) => ApiCreateSplitItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (groupId != null) 'group_id': groupId,
        'payer_id': payerId,
        'amount': amount,
        'split_type': splitType,
        if (category != null) 'category': category,
        if (note != null) 'note': note,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (timestamp != null) 'timestamp': timestamp,
        'splits': splits.map((s) => s.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateExpenseRequest &&
          other.id == id &&
          other.groupId == groupId &&
          other.payerId == payerId &&
          other.amount == amount &&
          other.splitType == splitType &&
          other.category == category &&
          other.note == note &&
          other.idempotencyKey == idempotencyKey &&
          other.timestamp == timestamp &&
          _listEquals(other.splits, splits);

  @override
  int get hashCode => Object.hash(id, groupId, payerId, amount, splitType,
      category, note, idempotencyKey, timestamp, Object.hashAll(splits));

  @override
  String toString() => 'ApiCreateExpenseRequest(id: $id, groupId: $groupId, '
      'payerId: $payerId, amount: $amount, splitType: $splitType, '
      'splits: ${splits.length})';

  static bool _listEquals(
      List<ApiCreateSplitItem> a, List<ApiCreateSplitItem> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One split instruction inside [ApiCreateExpenseRequest.splits].
class ApiCreateSplitItem {
  const ApiCreateSplitItem({
    required this.userId,
    this.exactAmount,
    this.percentage,
    this.shareCount,
  });

  /// Participant id (backend key `user_id`).
  final String userId;

  /// Rupees for `split_type: "exact"`.
  final double? exactAmount;

  /// 0–100 for `split_type: "percentage"`.
  final double? percentage;

  /// Integer shares for `split_type: "shares"`.
  final int? shareCount;

  factory ApiCreateSplitItem.fromJson(Map<String, dynamic> json) =>
      ApiCreateSplitItem(
        userId: json['user_id'] as String,
        exactAmount: (json['exact_amount'] as num?)?.toDouble(),
        percentage: (json['percentage'] as num?)?.toDouble(),
        shareCount: json['share_count'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        if (exactAmount != null) 'exact_amount': exactAmount,
        if (percentage != null) 'percentage': percentage,
        if (shareCount != null) 'share_count': shareCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateSplitItem &&
          other.userId == userId &&
          other.exactAmount == exactAmount &&
          other.percentage == percentage &&
          other.shareCount == shareCount;

  @override
  int get hashCode => Object.hash(userId, exactAmount, percentage, shareCount);

  @override
  String toString() =>
      'ApiCreateSplitItem(userId: $userId, exactAmount: $exactAmount, '
      'percentage: $percentage, shareCount: $shareCount)';
}

/// Body for `POST /v1/expenses/{expenseId}/receipt` (T7.4).
class ApiCreateReceiptRequest {
  const ApiCreateReceiptRequest({
    this.merchant,
    this.ocrTotal,
    this.ocrDate,
    this.lineItems = const [],
  });

  final String? merchant;

  /// OCR-extracted total in rupees (the backend stores paise).
  final double? ocrTotal;

  /// OCR-extracted date, raw string (e.g. `"2026-07-01"`).
  final String? ocrDate;

  final List<String> lineItems;

  Map<String, dynamic> toJson() => {
        if (merchant != null) 'merchant': merchant,
        if (ocrTotal != null) 'ocr_total': ocrTotal,
        if (ocrDate != null) 'ocr_date': ocrDate,
        'line_items': lineItems,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCreateReceiptRequest &&
          other.merchant == merchant &&
          other.ocrTotal == ocrTotal &&
          other.ocrDate == ocrDate &&
          _listEquals(other.lineItems, lineItems);

  @override
  int get hashCode =>
      Object.hash(merchant, ocrTotal, ocrDate, Object.hashAll(lineItems));

  @override
  String toString() =>
      'ApiCreateReceiptRequest(merchant: $merchant, ocrTotal: $ocrTotal, '
      'ocrDate: $ocrDate, lineItems: ${lineItems.length})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
