/// Wire-format health check response from `GET /health`.
class ApiHealth {
  const ApiHealth({required this.status, required this.service});

  /// e.g. `"ok"`.
  final String status;

  /// e.g. `"settl-api"`.
  final String service;

  factory ApiHealth.fromJson(Map<String, dynamic> json) => ApiHealth(
        status: json['status'] as String,
        service: json['service'] as String,
      );

  Map<String, dynamic> toJson() => {'status': status, 'service': service};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiHealth && other.status == status && other.service == service;

  @override
  int get hashCode => Object.hash(status, service);

  @override
  String toString() => 'ApiHealth(status: $status, service: $service)';
}
