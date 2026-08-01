import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settl/database/app_database.dart';
import 'package:settl/database/daos/contacts_dao.dart';
import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/database/daos/lists_dao.dart';
import 'package:settl/database/daos/pending_sync_dao.dart';
import 'package:settl/database/daos/profiles_dao.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/models/list_member.dart';
import 'package:settl/models/list_model.dart';
import 'package:settl/models/pending_sync_operation.dart';
import 'package:settl/models/profile.dart';
import 'package:sqlite3/open.dart';

void main() {
  if (Platform.isWindows) {
    // Host tests can't use sqlite3_flutter_libs; winsqlite3 ships with Windows.
    open.overrideFor(OperatingSystem.windows,
        () => DynamicLibrary.open('winsqlite3.dll'));
  }

  late AppDatabase db;
  late ExpensesDao expensesDao;
  late ContactsDao contactsDao;
  late ListsDao listsDao;
  late ProfilesDao profilesDao;
  late PendingSyncDao pendingSyncDao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    expensesDao = ExpensesDao(db);
    contactsDao = ContactsDao(db);
    listsDao = ListsDao(db);
    profilesDao = ProfilesDao(db);
    pendingSyncDao = PendingSyncDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExpensesDao', () {
    final expense = Expense(
      id: 'exp-1',
      amount: 1200.50,
      category: 'food',
      splitType: 'equal',
      payerId: 'user-1',
      listId: 'list-1',
      note: 'Dinner',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + getExpenseById roundtrips all fields', () async {
      await expensesDao.createExpense(expense);

      final fetched = await expensesDao.getExpenseById('exp-1');

      expect(fetched, isNotNull);
      expect(fetched!.id, 'exp-1');
      expect(fetched.amount, 1200.50);
      expect(fetched.category, 'food');
      expect(fetched.splitType, 'equal');
      expect(fetched.payerId, 'user-1');
      expect(fetched.listId, 'list-1');
      expect(fetched.note, 'Dinner');
      expect(fetched.version, 1);
      expect(fetched.createdAt, DateTime.utc(2026, 8, 1));
    });

    test('getExpensesByUser filters by payerId', () async {
      await expensesDao.createExpense(expense);
      await expensesDao.createExpense(Expense(
        id: 'exp-2',
        amount: 50,
        category: 'travel',
        splitType: 'equal',
        payerId: 'user-2',
        createdAt: DateTime.utc(2026, 8, 2),
      ));

      final mine = await expensesDao.getExpensesByUser('user-1');

      expect(mine, hasLength(1));
      expect(mine.single.id, 'exp-1');
    });

    test('updateExpense overwrites mutable fields', () async {
      await expensesDao.createExpense(expense);
      await expensesDao.updateExpense(Expense(
        id: 'exp-1',
        amount: 999,
        category: 'other',
        splitType: 'exact',
        payerId: 'user-1',
        listId: 'list-2',
        version: 2,
        createdAt: DateTime.utc(2026, 8, 1),
      ));

      final updated = await expensesDao.getExpenseById('exp-1');

      expect(updated!.amount, 999);
      expect(updated.category, 'other');
      expect(updated.listId, 'list-2');
      expect(updated.version, 2);
    });

    test('deleteExpense removes expense and its splits', () async {
      await expensesDao.createExpense(expense);
      await expensesDao.createExpenseSplit(const ExpenseSplit(
        id: 'split-1',
        expenseId: 'exp-1',
        participantId: 'user-1',
        shareAmount: 600.25,
      ));

      await expensesDao.deleteExpense('exp-1');

      expect(await expensesDao.getExpenseById('exp-1'), isNull);
      expect(await expensesDao.getSplitsForExpense('exp-1'), isEmpty);
    });

    test('splits roundtrip', () async {
      await expensesDao.createExpense(expense);
      await expensesDao.createExpenseSplit(const ExpenseSplit(
        id: 'split-1',
        expenseId: 'exp-1',
        participantId: 'user-1',
        shareAmount: 600.25,
        rawInput: 600,
      ));

      final splits = await expensesDao.getSplitsForExpense('exp-1');

      expect(splits, hasLength(1));
      expect(splits.single.participantId, 'user-1');
      expect(splits.single.shareAmount, 600.25);
      expect(splits.single.rawInput, 600);
    });
  });

  group('ContactsDao', () {
    final contact = Contact(
      participantId: 'p-1',
      phoneNumber: '+919876543210',
      displayName: 'Alice',
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + getContactById', () async {
      await contactsDao.createContact(contact);

      final fetched = await contactsDao.getContactById('p-1');

      expect(fetched, isNotNull);
      expect(fetched!.displayName, 'Alice');
      expect(fetched.createdBy, 'user-1');
    });

    test('getContactsByUser filters and sorts by displayName', () async {
      await contactsDao.createContact(contact);
      await contactsDao.createContact(Contact(
        participantId: 'p-2',
        phoneNumber: '+911234567890',
        displayName: 'Bob',
        createdBy: 'user-1',
        createdAt: DateTime.utc(2026, 8, 2),
      ));
      await contactsDao.createContact(Contact(
        participantId: 'p-3',
        phoneNumber: '+919999999999',
        displayName: 'Carol',
        createdBy: 'user-2',
        createdAt: DateTime.utc(2026, 8, 3),
      ));

      final mine = await contactsDao.getContactsByUser('user-1');

      expect(mine.map((c) => c.participantId), ['p-1', 'p-2']);
    });

    test('update + delete', () async {
      await contactsDao.createContact(contact);
      await contactsDao.updateContact(Contact(
        participantId: 'p-1',
        phoneNumber: '+911111111111',
        displayName: 'Alice Updated',
        createdBy: 'user-1',
        createdAt: DateTime.utc(2026, 8, 1),
      ));

      expect((await contactsDao.getContactById('p-1'))!.displayName,
          'Alice Updated');

      await contactsDao.deleteContact('p-1');
      expect(await contactsDao.getContactById('p-1'), isNull);
    });
  });

  group('ListsDao', () {
    final list = ListModel(
      id: 'list-1',
      name: 'Trip',
      accountNumber: 'ACC-1',
      createdBy: 'user-1',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + getListById + members', () async {
      await listsDao.createList(list);
      await listsDao.addMemberToList(ListMember(
        listId: 'list-1',
        participantId: 'p-1',
        addedAt: DateTime.utc(2026, 8, 1),
      ));

      final fetched = await listsDao.getListById('list-1');
      final members = await listsDao.getMembersOfList('list-1');

      expect(fetched!.name, 'Trip');
      expect(fetched.accountNumber, 'ACC-1');
      expect(members, hasLength(1));
      expect(members.single.participantId, 'p-1');
    });

    test('getListsByUser filters', () async {
      await listsDao.createList(list);
      await listsDao.createList(ListModel(
        id: 'list-2',
        name: 'Rent',
        accountNumber: 'ACC-2',
        createdBy: 'user-2',
        createdAt: DateTime.utc(2026, 8, 2),
      ));

      final mine = await listsDao.getListsByUser('user-1');

      expect(mine.map((l) => l.id), ['list-1']);
    });

    test('removeMemberFromList', () async {
      await listsDao.createList(list);
      await listsDao.addMemberToList(ListMember(
        listId: 'list-1',
        participantId: 'p-1',
        addedAt: DateTime.utc(2026, 8, 1),
      ));

      await listsDao.removeMemberFromList('list-1', 'p-1');

      expect(await listsDao.getMembersOfList('list-1'), isEmpty);
    });

    test('deleteList cascades to members', () async {
      await listsDao.createList(list);
      await listsDao.addMemberToList(ListMember(
        listId: 'list-1',
        participantId: 'p-1',
        addedAt: DateTime.utc(2026, 8, 1),
      ));

      await listsDao.deleteList('list-1');

      expect(await listsDao.getListById('list-1'), isNull);
      expect(await listsDao.getMembersOfList('list-1'), isEmpty);
    });
  });

  group('ProfilesDao', () {
    final profile = Profile(
      userId: 'user-1',
      participantId: 'p-1',
      displayName: 'Dhruv',
      phoneNumber: '+919876543210',
      upiId: 'dhruv@upi',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    test('create + lookup by userId and participantId', () async {
      await profilesDao.createProfile(profile);

      expect((await profilesDao.getProfileByUserId('user-1'))!.upiId,
          'dhruv@upi');
      expect(
          (await profilesDao.getProfileByParticipantId('p-1'))!.displayName,
          'Dhruv');
    });

    test('updateProfile', () async {
      await profilesDao.createProfile(profile);
      await profilesDao.updateProfile(Profile(
        userId: 'user-1',
        participantId: 'p-1',
        displayName: 'Dhruv R',
        phoneNumber: '+911234567890',
        createdAt: DateTime.utc(2026, 8, 1),
      ));

      final updated = await profilesDao.getProfileByUserId('user-1');

      expect(updated!.displayName, 'Dhruv R');
      expect(updated.phoneNumber, '+911234567890');
      expect(updated.upiId, isNull);
    });

    test('deleteProfileByUserId', () async {
      await profilesDao.createProfile(profile);
      await profilesDao.deleteProfileByUserId('user-1');

      expect(await profilesDao.getProfileByUserId('user-1'), isNull);
    });
  });

  group('PendingSyncDao', () {
    PendingSyncOperation op(SyncOperation operation, String id) =>
        PendingSyncOperation(
          operationId: id,
          entityType: 'expense',
          entityId: 'exp-1',
          operation: operation,
          payload: '{"id":"exp-1"}',
          createdAt: DateTime.utc(2026, 8, 1),
        );

    test('enqueue + getPending returns unsynced in order', () async {
      await pendingSyncDao.enqueue(op(SyncOperation.insert, 'op-1'));
      await pendingSyncDao.enqueue(op(SyncOperation.update, 'op-2'));

      final pending = await pendingSyncDao.getPending();

      expect(pending.map((o) => o.operationId), ['op-1', 'op-2']);
      expect(pending.first.operation, SyncOperation.insert);
      expect(pending.last.operation, SyncOperation.update);
      expect(await pendingSyncDao.pendingCount(), 2);
    });

    test('markSynced removes from pending queue', () async {
      await pendingSyncDao.enqueue(op(SyncOperation.insert, 'op-1'));
      await pendingSyncDao.markSynced('op-1', DateTime.utc(2026, 8, 2));

      expect(await pendingSyncDao.getPending(), isEmpty);
      expect(await pendingSyncDao.pendingCount(), 0);
      expect(await pendingSyncDao.getAll(), hasLength(1));
    });

    test('clearSynced keeps unsynced operations', () async {
      await pendingSyncDao.enqueue(op(SyncOperation.insert, 'op-1'));
      await pendingSyncDao.enqueue(op(SyncOperation.delete, 'op-2'));
      await pendingSyncDao.markSynced('op-1', DateTime.utc(2026, 8, 2));

      await pendingSyncDao.clearSynced();

      final remaining = await pendingSyncDao.getAll();
      expect(remaining.map((o) => o.operationId), ['op-2']);
      expect(remaining.single.operation, SyncOperation.delete);
    });

    test('deleteOperation removes a specific operation', () async {
      await pendingSyncDao.enqueue(op(SyncOperation.insert, 'op-1'));
      await pendingSyncDao.deleteOperation('op-1');

      expect(await pendingSyncDao.getAll(), isEmpty);
    });
  });
}
