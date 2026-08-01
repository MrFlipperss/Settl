import 'dart:async';

/// How a version conflict (HTTP 409) is settled when replaying a queued
/// mutation (T8.7).
enum ConflictResolution { keepServer, keepLocal }

/// A single conflict resolution, emitted for UI surfacing / diagnostics.
class ConflictResolutionEvent {
  const ConflictResolutionEvent({
    required this.entityType,
    required this.entityId,
    required this.resolution,
    required this.message,
  });

  final String entityType;
  final String entityId;
  final ConflictResolution resolution;
  final String message;

  @override
  String toString() =>
      'Conflict($entityType $entityId → ${resolution.name}: $message)';
}

/// Resolves 409 conflicts between local mutations and server state.
///
/// The default policy is [ConflictResolution.keepServer]: the server wins, the
/// queued mutation is dropped and the next refresh re-pulls the entity. Under
/// [ConflictResolution.keepLocal] the mutation is preserved and surfaced via
/// the permanently-failed queue view for manual resolution.
class ConflictResolver {
  ConflictResolver({this.policy = ConflictResolution.keepServer});

  /// Current resolution policy; mutable at runtime.
  ConflictResolution policy;

  final StreamController<ConflictResolutionEvent> _controller =
      StreamController<ConflictResolutionEvent>.broadcast();

  /// Emits every resolution.
  Stream<ConflictResolutionEvent> get conflicts => _controller.stream;

  ConflictResolution resolve({
    required String entityType,
    required String entityId,
    required String message,
  }) {
    final resolution = policy;
    _controller.add(ConflictResolutionEvent(
      entityType: entityType,
      entityId: entityId,
      resolution: resolution,
      message: message,
    ));
    return resolution;
  }

  void dispose() => _controller.close();
}
