import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:settl/api/api_client.dart';
import 'package:settl/api/api_exception.dart';
import 'package:settl/api/collections_api.dart';
import 'package:settl/api/contacts_api.dart';
import 'package:settl/api/expenses_api.dart';
import 'package:settl/api/models/api_requests.dart';
import 'package:settl/api/profile_api.dart';
import 'package:settl/database/app_database.dart';
import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/database/daos/pending_sync_dao.dart';
import 'package:settl/models/pending_sync_operation.dart';
import 'package:settl/sync/conflict_resolver.dart';
import 'package:settl/sync/connectivity_service.dart';
import 'package:settl/sync/retry_policy.dart';
import 'package:settl/sync/sync_queue.dart';
import 'package:settl/sync/sync_service.dart';
import 'package:settl/sync/sync_worker.dart';
import 'package:sqlite3/open.dart';

const _baseUrl = 'http://localhost:3000/api';
const _retryPolicy = RetryPolicy(
  maxAttempts: 3,
  baseDelay: Duration(milliseconds: 10),
  maxDelay: Duration(milliseconds: 100),
);

Map<String, dynamic> expenseJson({required String id, int amountPaise = 1250}) =>
    {
      'id': id,
      'group_id': 'g1',
      'payer_id': 'u1',
      'amount_paise': amountPaise,
      'category': 'food',
      'note': 'Dinner',
      'split_type': 'equal',
      'version': 1,
      'timestamp': '2026-08-01T10:00:00.000Z',
      'splits': [
        {'user_id': 'u1', 'share_amount_paise': amountPaise},
      ],
    };

Map<String, dynamic> collectionJson({required String id}) => {
      'id': id,
      'account_number': 'acc-$id',
      'name': 'Trip $id',
      'created_by': 'u1',
      'created_at': '2026-08-01T10:00:00.000Z',
      'version': 1,
      'member_count': 2,
    };

Map<String, dynamic> profileJson() => {
      'participant_id': 'part-1',
      'user_id': 'user-1',
      'display_name': 'Aarav',
      'phone_number': '+919876543210',
      'created_at': '2026-08-01T10:00:00.000Z',
      'version': 1,
    };

/// Test double for [ConnectivityGateway]; connectivity state is driven
/// manually via [setOnline].
class FakeConnectivityGateway implements ConnectivityGateway {
  FakeConnectivityGateway(this.online);

  bool online;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get onlineStream => _controller.stream;

  @override
  Future<bool> isOnline() async => online;

  void setOnline(bool value) {
    online = value;
    _controller.add(value);
  }

  Future<void> dispose() => _controller.close();
}

void main() {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late PendingSyncDao pendingSyncDao;
  late ExpensesDao expensesDao;
  late ListsDao listsDao;
  late ConflictResolver conflictResolver;
  late SyncQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    pendingSyncDao = PendingSyncDao(db);
    expensesDao = ExpensesDao(db);
    listsDao = ListsDao(db);
    conflictResolver = ConflictResolver();
    queue = SyncQueue(pendingSyncDao, idGenerator: () => 'op-1');
  });

  tearDown(() async {
    await db.close();
  });

  group('Queue payload round-trips', () {
    test('ApiCreateExpenseRequest fromJson round-trips', () {
      const request = ApiCreateExpenseRequest(
        id: 'exp-1',
        groupId: 'g1',
        payerId: 'u1',
        amount: 12.5,
        splitType: 'equal',
        category: 'food',
        note: 'Dinner',
        idempotencyKey: 'idem-1',
        timestamp: '2026-08-01T10:00:00.000Z',
        splits: [ApiCreateSplitItem(userId: 'u1', shareCount: 2)],
      );
      expect(ApiCreateExpenseRequest.fromJson(request.toJson()), request);
    });

    test('ApiCreateSplitItem fromJson round-trips each split flavor', () {
      const item = ApiCreateSplitItem(
        userId: 'u1',
        exactAmount: 4.5,
        percentage: 25,
        shareCount: 3,
      );
      expect(ApiCreateSplitItem.fromJson(item.toJson()), item);
    });

    test('ApiCreateContactRequest fromJson round-trips', () {
      const request =
          ApiCreateContactRequest(id: 'p1', displayName: 'Rahul', phoneNumber: '+919876543210');
      expect(ApiCreateContactRequest.fromJson(request.toJson()), request);
    });

    test('ApiCreateCollectionRequest fromJson round-trips', () {
      const request = ApiCreateCollectionRequest(
        id: 'g1',
        name: 'Goa Trip',
        currency: 'INR',
      );
      expect(ApiCreateCollectionRequest.fromJson(request.toJson()), request);
    });

    test('ApiCreateProfileRequest fromJson round-trips', () {
      const request = ApiCreateProfileRequest(
        displayName: 'Aarav',
        phoneNumber: '+919876543210',
        upiId: 'aarav@upi',
      );
      expect(ApiCreateProfileRequest.fromJson(request.toJson()), request);
    });
  });

  group('SyncQueue', () {
    test('enqueueExpense stores snake_case wire payload', () async {
      const request = ApiCreateExpenseRequest(
        id: 'exp-1',
        payerId: 'u1',
        amount: 120.0,
        splitType: 'equal',
        splits: [ApiCreateSplitItem(userId: 'u2')],
      );

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: request,
      );

      final rows = await pendingSyncDao.getAll();
      expect(rows, hasLength(1));
      final op = rows.single;
      expect(op.entityType, 'expense');
      expect(op.entityId, 'exp-1');
      expect(op.operation, SyncOperation.insert);
      final decoded = jsonDecode(op.payload) as Map<String, dynamic>;
      expect(decoded['id'], 'exp-1');
      expect(decoded['payer_id'], 'u1');
      expect(decoded['amount'], 120.0);
      expect(decoded['splits'], hasLength(1));
    });

    test('enqueueExpense bakes a generated id into the payload', () async {
      final request = ApiCreateExpenseRequest(
        payerId: 'u1',
        amount: 50.0,
        splitType: 'equal',
      );

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: request,
      );

      final op = (await pendingSyncDao.getAll()).single;
      final decoded = jsonDecode(op.payload) as Map<String, dynamic>;
      expect(decoded['id'], op.entityId);
      expect(decoded['id'], isNotEmpty);
    });

    test('enqueueProfile always inserts with the caller participant id',
        () async {
      const request = ApiCreateProfileRequest(
        displayName: 'Aarav',
        phoneNumber: '+919876543210',
      );

      await queue.enqueueProfile(entityId: 'part-1', request: request);

      final op = (await pendingSyncDao.getAll()).single;
      expect(op.entityType, 'profile');
      expect(op.entityId, 'part-1');
      expect(op.operation, SyncOperation.insert);
    });
  });

  group('RetryPolicy', () {
    const policy = RetryPolicy(
      maxAttempts: 3,
      baseDelay: Duration(seconds: 1),
      maxDelay: Duration(seconds: 8),
    );

    test('backoff doubles per attempt and caps at maxDelay', () {
      expect(policy.delayForAttempt(1), const Duration(seconds: 1));
      expect(policy.delayForAttempt(2), const Duration(seconds: 2));
      expect(policy.delayForAttempt(3), const Duration(seconds: 4));
      expect(policy.delayForAttempt(5), const Duration(seconds: 8));
    });

    test('classifies transient vs permanent failures', () {
      expect(policy.isTransient(const ApiException('x', 500)), isTrue);
      expect(policy.isTransient(const ApiException('x', 503)), isTrue);
      expect(policy.isTransient(const ApiException('x', 408)), isTrue);
      expect(policy.isTransient(const ApiException('x', 429)), isTrue);
      expect(policy.isTransient(SocketException('down')), isTrue);
      expect(policy.isTransient(TimeoutException('t')), isTrue);

      expect(policy.isTransient(const ApiException('x', 400)), isFalse);
      expect(policy.isTransient(const ApiException('x', 401)), isFalse);
      expect(policy.isTransient(const ApiException('x', 403)), isFalse);
      expect(policy.isTransient(const ApiException('x', 409)), isFalse);
    });
  });

  group('ConflictResolver', () {
    test('defaults to server-wins and emits resolutions', () async {
      final events = <ConflictResolutionEvent>[];
      final sub = conflictResolver.conflicts.listen(events.add);

      final resolution = conflictResolver.resolve(
        entityType: 'expense',
        entityId: 'exp-1',
        message: 'version mismatch',
      );

      // Broadcast-stream events are delivered asynchronously.
      await Future<void>.delayed(Duration.zero);

      expect(resolution, ConflictResolution.keepServer);
      expect(conflictResolver.policy, ConflictResolution.keepServer);
      expect(events, hasLength(1));
      expect(events.single.entityId, 'exp-1');
      expect(events.single.resolution, ConflictResolution.keepServer);

      await sub.cancel();
    });
  });

  group('SyncWorker', () {
    SyncWorker workerWith(http.Client client) => SyncWorker(
          dao: pendingSyncDao,
          expensesApi: ExpensesApi(
              ApiClient(client: client, baseUrl: _baseUrl)),
          contactsApi: ContactsApi(
              ApiClient(client: client, baseUrl: _baseUrl)),
          collectionsApi: CollectionsApi(
              ApiClient(client: client, baseUrl: _baseUrl)),
          profileApi:
              ProfileApi(ApiClient(client: client, baseUrl: _baseUrl)),
          expensesLocal: expensesDao,
          listsLocal: listsDao,
          retryPolicy: _retryPolicy,
          conflictResolver: conflictResolver,
        );

    test('marks a successful replay as synced', () async {
      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path == '/api/v1/expenses/') {
          return http.Response(
            jsonEncode(expenseJson(id: 'exp-1')),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      final synced = await workerWith(client).drainQueue();

      expect(synced, 1);
      expect(await pendingSyncDao.getPending(), isEmpty);
      final op = (await pendingSyncDao.getAll()).single;
      expect(op.syncedAt, isNotNull);
    });

    test('transient failure bumps the attempt count and stays retryable',
        () async {
      final client = MockClient(
          (request) async => http.Response('{"error": "boom"}', 503));

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      final synced = await workerWith(client).drainQueue();

      expect(synced, 0);
      final retryable = await pendingSyncDao.getPendingRetryable(3);
      expect(retryable, hasLength(1));
      expect(retryable.single.attemptCount, 1);
      expect(retryable.single.lastError, contains('503'));
      expect(await pendingSyncDao.getFailed(3), isEmpty);
    });

    test('permanent failure surfaces in getFailed and stops retrying',
        () async {
      final client = MockClient(
          (request) async => http.Response('{"error": "bad request"}', 400));

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      final synced = await workerWith(client).drainQueue();

      expect(synced, 0);
      expect(await pendingSyncDao.getPendingRetryable(3), isEmpty);
      final failed = await pendingSyncDao.getFailed(3);
      expect(failed, hasLength(1));
      expect(failed.single.attemptCount, 3);
      expect(failed.single.lastError, contains('400'));
    });

    test('409 with server-wins drops the queued mutation and emits conflict',
        () async {
      final events = <ConflictResolutionEvent>[];
      final sub = conflictResolver.conflicts.listen(events.add);
      final client = MockClient(
          (request) async => http.Response('{"error": "version mismatch"}', 409));

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      final synced = await workerWith(client).drainQueue();

      expect(synced, 0);
      expect(await pendingSyncDao.getAll(), isEmpty);
      expect(events, hasLength(1));
      expect(events.single.entityId, 'exp-1');
      expect(events.single.resolution, ConflictResolution.keepServer);

      await sub.cancel();
    });

    test('409 with keep-local preserves the operation as failed', () async {
      conflictResolver.policy = ConflictResolution.keepLocal;
      final client = MockClient(
          (request) async => http.Response('{"error": "version mismatch"}', 409));

      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      await workerWith(client).drainQueue();

      final failed = await pendingSyncDao.getFailed(3);
      expect(failed, hasLength(1));
      expect(failed.single.lastError, contains('conflict'));
    });

    test('drain replays in FIFO order', () async {
      final postedIds = <String>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        postedIds.add(body['id'] as String);
        return http.Response(
          jsonEncode(expenseJson(id: body['id'] as String)),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      await pendingSyncDao.enqueue(PendingSyncOperation(
        operationId: 'op-old',
        entityType: SyncQueue.entityExpense,
        entityId: 'exp-old',
        operation: SyncOperation.insert,
        payload: jsonEncode({
          'id': 'exp-old',
          'payer_id': 'u1',
          'amount': 10.0,
          'split_type': 'equal',
          'splits': <Object>[],
        }),
        createdAt: DateTime.utc(2026, 7, 1),
      ));
      await pendingSyncDao.enqueue(PendingSyncOperation(
        operationId: 'op-new',
        entityType: SyncQueue.entityExpense,
        entityId: 'exp-new',
        operation: SyncOperation.insert,
        payload: jsonEncode({
          'id': 'exp-new',
          'payer_id': 'u1',
          'amount': 20.0,
          'split_type': 'equal',
          'splits': <Object>[],
        }),
        createdAt: DateTime.utc(2026, 7, 2),
      ));

      await workerWith(client).drainQueue();

      expect(postedIds, ['exp-old', 'exp-new']);
    });

    test('refresh pulls expenses (with splits) and collections into DAOs',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/v1/expenses/' &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode([expenseJson(id: 'exp-1')]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/groups/' && request.method == 'GET') {
          return http.Response(
            jsonEncode([collectionJson(id: 'g1')]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      await workerWith(client).refresh();

      final expense = await expensesDao.getExpenseById('exp-1');
      expect(expense, isNotNull);
      expect(expense!.amount, 12.5);
      expect(expense.payerId, 'u1');
      expect(expense.version, 1);
      final splits = await expensesDao.getSplitsForExpense('exp-1');
      expect(splits, hasLength(1));
      expect(splits.single.shareAmount, 12.5);
      expect(splits.single.participantId, 'u1');

      final list = await listsDao.getListById('g1');
      expect(list, isNotNull);
      expect(list!.name, 'Trip g1');
      expect(list.accountNumber, 'acc-g1');
    });
  });

  group('SyncService', () {
    SyncService serviceWith(
      http.Client client,
      FakeConnectivityGateway connectivity,
    ) =>
        SyncService(
          worker: SyncWorker(
            dao: pendingSyncDao,
            expensesApi:
                ExpensesApi(ApiClient(client: client, baseUrl: _baseUrl)),
            contactsApi:
                ContactsApi(ApiClient(client: client, baseUrl: _baseUrl)),
            collectionsApi:
                CollectionsApi(ApiClient(client: client, baseUrl: _baseUrl)),
            profileApi:
                ProfileApi(ApiClient(client: client, baseUrl: _baseUrl)),
            expensesLocal: expensesDao,
            listsLocal: listsDao,
            retryPolicy: _retryPolicy,
            conflictResolver: conflictResolver,
          ),
          connectivity: connectivity,
          retryPolicy: _retryPolicy,
        );

    MockClient happyBackend() => MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.path == '/api/v1/expenses/') {
            return http.Response(
              jsonEncode(expenseJson(id: 'exp-1')),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' &&
              request.url.path == '/api/v1/expenses/') {
            return http.Response(
              jsonEncode([expenseJson(id: 'exp-1')]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' &&
              request.url.path == '/api/v1/groups/') {
            return http.Response('[]', 200,
                headers: {'content-type': 'application/json'});
          }
          return http.Response('not found', 404);
        });

    test('start online runs the initial sync', () async {
      final service = serviceWith(happyBackend(), FakeConnectivityGateway(true));
      final statuses = <SyncStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      await service.start();

      expect(service.isOnline, isTrue);
      expect(service.status, SyncStatus.idle);
      expect(statuses, contains(SyncStatus.syncing));
      expect(await expensesDao.getAllExpenses(), hasLength(1));

      await sub.cancel();
      await service.stop();
    });

    test('coming online triggers a drain of queued mutations', () async {
      final connectivity = FakeConnectivityGateway(false);
      final service = serviceWith(happyBackend(), connectivity);
      await queue.enqueueExpense(
        operation: SyncOperation.insert,
        request: const ApiCreateExpenseRequest(
          id: 'exp-1',
          payerId: 'u1',
          amount: 12.5,
          splitType: 'equal',
        ),
      );

      // Offline at start: no sync runs.
      await service.start();
      expect(await pendingSyncDao.getPending(), hasLength(1));

      // Connectivity restores: the listener drains the queue and refreshes.
      connectivity.setOnline(true);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(await pendingSyncDao.getPending(), isEmpty);
      expect(await expensesDao.getAllExpenses(), hasLength(1));

      await service.stop();
    });

    test('requestSync transitions idle → syncing → idle', () async {
      final service = serviceWith(happyBackend(), FakeConnectivityGateway(true));
      final statuses = <SyncStatus>[];
      final sub = service.statusStream.listen(statuses.add);

      await service.requestSync();

      // Broadcast-stream events are delivered asynchronously.
      await Future<void>.delayed(Duration.zero);

      expect(service.status, SyncStatus.idle);
      expect(statuses.first, SyncStatus.syncing);
      expect(statuses.last, SyncStatus.idle);

      await sub.cancel();
      await service.stop();
    });
  });
}
