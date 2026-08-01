import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'database.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables
//
// Column getters intentionally use camelCase (drift default). The DAO layer
// maps rows to the snake_case domain models in lib/models.
// @DataClassName keeps generated row classes from colliding with the
// domain model classes (e.g. Expense, Contact, Profile).
// ---------------------------------------------------------------------------

/// Identities that expenses and contacts refer to (id + kind).
@DataClassName('ParticipantRow')
class Participants extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get kind => text().withLength(min: 1, max: 32)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local copy of the current user's profile.
@DataClassName('ProfileRow')
class Profiles extends Table {
  TextColumn get userId => text().withLength(min: 1, max: 64)();
  TextColumn get participantId => text().withLength(min: 1, max: 64)();
  TextColumn get displayName => text().withLength(min: 1, max: 120)();
  TextColumn get phoneNumber => text().withLength(min: 1, max: 32)();
  TextColumn get upiId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}

/// A participant known to the user (from phone contacts).
@DataClassName('ContactRow')
class Contacts extends Table {
  TextColumn get participantId => text().withLength(min: 1, max: 64)();
  TextColumn get phoneNumber => text().withLength(min: 1, max: 32)();
  TextColumn get displayName => text().withLength(min: 1, max: 120)();
  TextColumn get createdBy => text().withLength(min: 1, max: 64)();
  TextColumn get claimedByParticipantId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {participantId};
}

/// A collection of participants that share expenses.
@DataClassName('ListRow')
class Lists extends Table {
  TextColumn get listId => text().withLength(min: 1, max: 64)();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get accountNumber => text().withLength(min: 1, max: 32)();
  TextColumn get createdBy => text().withLength(min: 1, max: 64)();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listId};
}

/// Membership of a participant in a list.
@DataClassName('ListMemberRow')
class ListMembers extends Table {
  TextColumn get listId => text().withLength(min: 1, max: 64)();
  TextColumn get participantId => text().withLength(min: 1, max: 64)();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {listId, participantId};
}

/// A single expense recorded in a list.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get expenseId => text().withLength(min: 1, max: 64)();
  RealColumn get amount => real()();
  TextColumn get category => text().withLength(min: 1, max: 64)();
  TextColumn get splitType => text().withLength(min: 1, max: 32)();
  TextColumn get payerId => text().withLength(min: 1, max: 64)();
  TextColumn get listId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get idempotencyKey => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {expenseId};
}

/// How a single participant's share of an expense was computed.
@DataClassName('ExpenseSplitRow')
class ExpenseSplits extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();
  TextColumn get expenseId => text().withLength(min: 1, max: 64)();
  TextColumn get participantId => text().withLength(min: 1, max: 64)();
  RealColumn get shareAmount => real()();
  RealColumn get rawInput => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Optional OCR / scan details attached to an expense.
@DataClassName('ReceiptDetailRow')
class ReceiptDetails extends Table {
  TextColumn get expenseId => text().withLength(min: 1, max: 64)();
  TextColumn get createdBy => text().withLength(min: 1, max: 64)();
  TextColumn get merchant => text().nullable()();
  RealColumn get ocrTotal => real().nullable()();
  TextColumn get ocrDate => text().nullable()();
  TextColumn get lineItems => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {expenseId};
}

/// Offline-first queue of mutations to replay to the backend once online.
@DataClassName('PendingSyncOperationRow')
class PendingSyncOperations extends Table {
  TextColumn get operationId => text().withLength(min: 1, max: 64)();
  TextColumn get entityType => text().withLength(min: 1, max: 32)();
  TextColumn get entityId => text().withLength(min: 1, max: 64)();
  TextColumn get operation => text().withLength(min: 1, max: 16)();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {operationId};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [
  Participants,
  Profiles,
  Contacts,
  Lists,
  ListMembers,
  Expenses,
  ExpenseSplits,
  ReceiptDetails,
  PendingSyncOperations,
])
class AppDatabase extends _$AppDatabase implements Database {
  AppDatabase(super.e);

  AppDatabase.open() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  @override
  Object get instance => this;

  @override
  Future<void> initialize() async {
    // Connection opens lazily on first query; nothing extra to do.
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}settl.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
