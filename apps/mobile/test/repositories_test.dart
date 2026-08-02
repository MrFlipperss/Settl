import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:settl/api/api_client.dart';
import 'package:settl/api/contacts_api.dart';
import 'package:settl/api/profile_api.dart';
import 'package:settl/database/app_database.dart';
import 'package:settl/database/daos/contacts_dao.dart';
import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/database/daos/profiles_dao.dart';
import 'package:settl/models/balance.dart';
import 'package:settl/models/collection.dart';
import 'package:settl/models/collection_member.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/repositories/balance_repository_impl.dart';
import 'package:settl/repositories/collection_repository_impl.dart';
import 'package:settl/repositories/contact_repository_impl.dart';
import 'package:settl/repositories/expense_repository_impl.dart';
import 'package:settl/repositories/profile_repository_impl.dart';
import 'package:sqlite3/open.dart';

/// Never-invoked HTTP stub for the remote seams of repository impls; the
/// repository tests exercise local persistence only.
final _stubApiClient = ApiClient(
  client: MockClient((_) async => http.Response('not used', 500)),
  baseUrl: 'http://localhost:3000/api',
);

void main() {
  if (Platform.isWindows) {
    // Host tests can't use sqlite3_flutter_libs; winsqlite3 ships with Windows.
    open.overrideFor(OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late ExpenseRepositoryImpl expenseRepo;
  late ContactRepositoryImpl contactRepo;
  late CollectionRepositoryImpl collectionRepo;
  late BalanceRepositoryImpl balanceRepo;
  late ProfileRepositoryImpl profileRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    expenseRepo = ExpenseRepositoryImpl(ExpensesDao(db));
    contactRepo = ContactRepositoryImpl(
      ContactsDao(db),
      ContactsApi(_stubApiClient),
    );
    collectionRepo = CollectionRepositoryImpl(ListsDao(db));
    balanceRepo = BalanceRepositoryImpl(expenseRepo);
    profileRepo = ProfileRepositoryImpl(
      ProfilesDao(db),
      ProfileApi(_stubApiClient),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpenseRepositoryImpl', () {
    final expense = Expense(
      id: 'exp-1',
      amount: 1200.50,
      category: 'food',
      splitType: 'equal',
      payerId: 'user-1',
      listId: 'list-1',
      note: 'Dinner',
      idempotencyKey: 'idem-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('createExpense + getExpenseById roundtrips', () async {
      await expenseRepo.createExpense(expense);

      final fetched = await expenseRepo.getExpenseById('exp-1');
      expect(fetched, expense);
    });

    test('getExpensesByList filters by listId', () async {
      await expenseRepo.createExpense(expense);
      await expenseRepo.createExpense(expense.copyWith(
        id: 'exp-2',
        listId: 'list-2',
        note: 'Other list',
      ));

      final inList1 = await expenseRepo.getExpensesByList('list-1');
      final inList2 = await expenseRepo.getExpensesByList('list-2');

      expect(inList1.map((e) => e.id), ['exp-1']);
      expect(inList2.map((e) => e.id), ['exp-2']);
    });

    test('createExpenseSplit + getSplitsForExpense roundtrips', () async {
      await expenseRepo.createExpense(expense);
      await expenseRepo.createExpenseSplit(const ExpenseSplit(
        id: 'split-1',
        expenseId: 'exp-1',
        participantId: 'user-2',
        shareAmount: 600.25,
      ));

      final splits = await expenseRepo.getSplitsForExpense('exp-1');
      expect(splits, hasLength(1));
      expect(splits.first.participantId, 'user-2');
      expect(splits.first.shareAmount, 600.25);
    });

    test('deleteExpense removes the expense and its splits', () async {
      await expenseRepo.createExpense(expense);
      await expenseRepo.createExpenseSplit(const ExpenseSplit(
        id: 'split-1',
        expenseId: 'exp-1',
        participantId: 'user-2',
        shareAmount: 600.25,
      ));

      await expenseRepo.deleteExpense('exp-1');

      expect(await expenseRepo.getExpenseById('exp-1'), isNull);
      expect(await expenseRepo.getSplitsForExpense('exp-1'), isEmpty);
    });
  });

  group('ContactRepositoryImpl', () {
    final contact = Contact(
      participantId: 'part-1',
      phoneNumber: '+919000000001',
      displayName: 'Alice',
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + get + getAll roundtrip', () async {
      await contactRepo.createContact(contact);

      expect(await contactRepo.getContactById('part-1'), contact);
      expect((await contactRepo.getAllContacts()).map((c) => c.participantId),
          ['part-1']);
    });

    test('updateContact persists changes', () async {
      await contactRepo.createContact(contact);
      await contactRepo.updateContact(
          contact.copyWith(displayName: 'Alice Updated'));

      expect((await contactRepo.getContactById('part-1'))!.displayName,
          'Alice Updated');
    });

    test('deleteContact removes the row', () async {
      await contactRepo.createContact(contact);
      await contactRepo.deleteContact('part-1');

      expect(await contactRepo.getContactById('part-1'), isNull);
    });
  });

  group('CollectionRepositoryImpl', () {
    final collection = Collection(
      id: 'list-1',
      name: 'Trip to Goa',
      accountNumber: 'ABC-123',
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + get + getAll roundtrip', () async {
      await collectionRepo.createCollection(collection);

      expect(await collectionRepo.getCollectionById('list-1'), collection);
      expect((await collectionRepo.getAllCollections()).map((l) => l.id),
          ['list-1']);
    });

    test('members roundtrip and removal', () async {
      await collectionRepo.createCollection(collection);
      await collectionRepo.addMemberToCollection(CollectionMember(
        collectionId: 'list-1',
        participantId: 'part-1',
        addedAt: DateTime.utc(2026, 8, 1),
      ));

      expect((await collectionRepo.getMembersOfCollection('list-1'))
          .map((m) => m.participantId), ['part-1']);

      await collectionRepo.removeMemberFromCollection('list-1', 'part-1');
      expect(await collectionRepo.getMembersOfCollection('list-1'), isEmpty);
    });

    test('deleteCollection removes the collection and its members', () async {
      await collectionRepo.createCollection(collection);
      await collectionRepo.addMemberToCollection(CollectionMember(
        collectionId: 'list-1',
        participantId: 'part-1',
        addedAt: DateTime.utc(2026, 8, 1),
      ));

      await collectionRepo.deleteCollection('list-1');

      expect(await collectionRepo.getCollectionById('list-1'), isNull);
      expect(await collectionRepo.getMembersOfCollection('list-1'), isEmpty);
    });
  });

  group('ProfileRepositoryImpl', () {
    final profile = Profile(
      userId: 'user-1',
      participantId: 'part-1',
      displayName: 'Dhruv',
      phoneNumber: '+919000000000',
      upiId: 'dhruv@upi',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + get by userId + get by participantId', () async {
      await profileRepo.createProfile(profile);

      expect(await profileRepo.getProfileByUserId('user-1'), profile);
      expect(await profileRepo.getProfileByParticipantId('part-1'), profile);
    });

    test('updateProfile persists changes', () async {
      await profileRepo.createProfile(profile);
      await profileRepo.updateProfile(profile.copyWith(displayName: 'New Name'));

      expect((await profileRepo.getProfileByUserId('user-1'))!.displayName,
          'New Name');
    });

    test('deleteProfileByUserId removes the row', () async {
      await profileRepo.createProfile(profile);
      await profileRepo.deleteProfileByUserId('user-1');

      expect(await profileRepo.getProfileByUserId('user-1'), isNull);
    });
  });

  group('BalanceRepositoryImpl', () {
    Future<void> seedExpense({
      required String expenseId,
      required String payerId,
      required List<(String, double)> shares, // (participantId, shareAmount)
    }) async {
      await expenseRepo.createExpense(Expense(
        id: expenseId,
        amount: shares.fold(0.0, (sum, s) => sum + s.$2),
        category: 'food',
        splitType: 'custom',
        payerId: payerId,
        createdAt: DateTime.utc(2026, 8, 1),
      ));
      for (final (participantId, share) in shares) {
        await expenseRepo.createExpenseSplit(ExpenseSplit(
          id: '$expenseId-$participantId',
          expenseId: expenseId,
          participantId: participantId,
          shareAmount: share,
        ));
      }
    }

    test('simple: participant owes the payer their share', () async {
      // Alice pays 100; Bob's share is 40 -> Bob owes Alice 40.
      await seedExpense(
        expenseId: 'exp-1',
        payerId: 'alice',
        shares: [('alice', 60.0), ('bob', 40.0)],
      );

      final balances = await balanceRepo.getAllBalances();

      expect(balances, [
        const Balance(
          fromParticipantId: 'bob',
          toParticipantId: 'alice',
          amountOwed: 40.0,
        ),
      ]);
    });

    test('opposing edges net out', () async {
      // Alice pays 100, Bob's share 40 -> Bob owes Alice 40.
      await seedExpense(
        expenseId: 'exp-1',
        payerId: 'alice',
        shares: [('alice', 60.0), ('bob', 40.0)],
      );
      // Bob pays 100, Alice's share 25 -> Alice owes Bob 25.
      await seedExpense(
        expenseId: 'exp-2',
        payerId: 'bob',
        shares: [('bob', 75.0), ('alice', 25.0)],
      );

      final balances = await balanceRepo.getAllBalances();

      expect(balances, [
        const Balance(
          fromParticipantId: 'bob',
          toParticipantId: 'alice',
          amountOwed: 15.0,
        ),
      ]);
    });

    test('payer share does not create a self-balance', () async {
      await seedExpense(
        expenseId: 'exp-1',
        payerId: 'alice',
        shares: [('alice', 100.0)],
      );

      expect(await balanceRepo.getAllBalances(), isEmpty);
    });

    test('getBalancesForParticipant filters to the participant', () async {
      await seedExpense(
        expenseId: 'exp-1',
        payerId: 'alice',
        shares: [('alice', 60.0), ('bob', 40.0)],
      );
      await seedExpense(
        expenseId: 'exp-2',
        payerId: 'alice',
        shares: [('alice', 70.0), ('carol', 30.0)],
      );

      final bobBalances = await balanceRepo.getBalancesForParticipant('bob');
      final carolBalances =
          await balanceRepo.getBalancesForParticipant('carol');

      expect(bobBalances.map((b) => b.toParticipantId), ['alice']);
      expect(carolBalances.map((b) => b.toParticipantId), ['alice']);
    });

    test('multi-hop expenses produce multiple pairwise balances', () async {
      // Alice pays 300 split 3 ways -> Bob and Carol each owe Alice 100.
      await seedExpense(
        expenseId: 'exp-1',
        payerId: 'alice',
        shares: [('alice', 100.0), ('bob', 100.0), ('carol', 100.0)],
      );

      final balances = await balanceRepo.getAllBalances();

      expect(balances, hasLength(2));
      expect(balances.any((b) =>
          b.fromParticipantId == 'bob' &&
          b.toParticipantId == 'alice' &&
          b.amountOwed == 100.0), isTrue);
      expect(balances.any((b) =>
          b.fromParticipantId == 'carol' &&
          b.toParticipantId == 'alice' &&
          b.amountOwed == 100.0), isTrue);
    });
  });
}
