/// Type of mutation recorded in the offline-first sync queue.
enum SyncOperation { insert, update, delete }

/// A single local mutation awaiting (or confirmed) sync to the backend.
///
/// [payload] holds the entity as a JSON string, keyed by the entity's
/// snake_case fields so it can be replayed to the backend API unchanged.
class PendingSyncOperation {
  final String operationId;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String payload;
  final DateTime createdAt;
  final DateTime? syncedAt;

  const PendingSyncOperation({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.syncedAt,
  });

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json) =>
      PendingSyncOperation(
        operationId: json['operation_id'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        operation: SyncOperation.values.byName(json['operation'] as String),
        payload: json['payload'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        syncedAt: json['synced_at'] != null
            ? DateTime.parse(json['synced_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'operation_id': operationId,
        'entity_type': entityType,
        'entity_id': entityId,
        'operation': operation.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt?.toIso8601String(),
      };
}
