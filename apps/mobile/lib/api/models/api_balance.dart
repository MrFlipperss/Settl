/// Wire-format balance summary from `GET /balances`.
class ApiBalancesResponse {
  const ApiBalancesResponse({
    required this.totalOwedPaise,
    required this.totalOwingPaise,
    required this.netPaise,
    required this.breakdown,
  });

  /// Total paise others owe the reference person.
  final int totalOwedPaise;

  /// Total paise the reference person owes others.
  final int totalOwingPaise;

  /// Signed net: owed minus owing.
  final int netPaise;

  final List<ApiBalanceEntry> breakdown;

  factory ApiBalancesResponse.fromJson(Map<String, dynamic> json) =>
      ApiBalancesResponse(
        totalOwedPaise: (json['total_owed_paise'] as num).toInt(),
        totalOwingPaise: (json['total_owing_paise'] as num).toInt(),
        netPaise: (json['net_paise'] as num).toInt(),
        breakdown: (json['breakdown'] as List? ?? const [])
            .map((e) => ApiBalanceEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'total_owed_paise': totalOwedPaise,
        'total_owing_paise': totalOwingPaise,
        'net_paise': netPaise,
        'breakdown': breakdown.map((b) => b.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiBalancesResponse &&
          other.totalOwedPaise == totalOwedPaise &&
          other.totalOwingPaise == totalOwingPaise &&
          other.netPaise == netPaise &&
          _listEquals(other.breakdown, breakdown);

  @override
  int get hashCode => Object.hash(
      totalOwedPaise, totalOwingPaise, netPaise, Object.hashAll(breakdown));

  @override
  String toString() => 'ApiBalancesResponse(totalOwedPaise: $totalOwedPaise, '
      'totalOwingPaise: $totalOwingPaise, netPaise: $netPaise, '
      'breakdown: ${breakdown.length})';

  static bool _listEquals(List<ApiBalanceEntry> a, List<ApiBalanceEntry> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// One entry in the balance breakdown, netted against a single counterparty.
class ApiBalanceEntry {
  const ApiBalanceEntry({
    required this.userId,
    required this.userName,
    this.groupId,
    this.groupName,
    required this.amountPaise,
    required this.currency,
  });

  /// Counterparty participant id (backend key `user_id`).
  final String userId;

  final String userName;
  final String? groupId;
  final String? groupName;

  /// Absolute amount in paise.
  final int amountPaise;

  final String currency;

  factory ApiBalanceEntry.fromJson(Map<String, dynamic> json) =>
      ApiBalanceEntry(
        userId: json['user_id'] as String,
        userName: json['user_name'] as String? ?? '',
        groupId: json['group_id'] as String?,
        groupName: json['group_name'] as String?,
        amountPaise: (json['amount_paise'] as num).toInt(),
        currency: json['currency'] as String? ?? 'INR',
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'group_id': groupId,
        'group_name': groupName,
        'amount_paise': amountPaise,
        'currency': currency,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiBalanceEntry &&
          other.userId == userId &&
          other.userName == userName &&
          other.groupId == groupId &&
          other.groupName == groupName &&
          other.amountPaise == amountPaise &&
          other.currency == currency;

  @override
  int get hashCode =>
      Object.hash(userId, userName, groupId, groupName, amountPaise, currency);

  @override
  String toString() => 'ApiBalanceEntry(userId: $userId, userName: $userName, '
      'amountPaise: $amountPaise, currency: $currency)';
}
