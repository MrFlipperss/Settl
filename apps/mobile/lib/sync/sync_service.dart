import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, RealtimeChannel;
import '../database/database.dart';

enum SyncStatus { idle, syncing, error }

class SyncService {
  final Database _db;
  SyncStatus _status = SyncStatus.idle;
  RealtimeChannel? _channel;

  SyncService(this._db);

  SyncStatus get status => _status;

  Stream<SyncStatus> get statusStream => _statusStream.stream;
  final _statusStream = StreamController<SyncStatus>.broadcast();

  void _setStatus(SyncStatus s) {
    _status = s;
    _statusStream.add(s);
  }

  Future<void> startRealtimeSync() async {
    _channel = _db.client.channel('schema-changes');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      callback: (_) => _sync(),
    );
    _channel!.subscribe();
  }

  Future<void> _sync() async {
    _setStatus(SyncStatus.syncing);
    try {
      _setStatus(SyncStatus.idle);
    } catch (_) {
      _setStatus(SyncStatus.error);
    }
  }

  Future<void> stopSync() async {
    await _channel?.unsubscribe();
    await _statusStream.close();
  }
}
