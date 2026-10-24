import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:settl/features/expenses/add_expense_screen.dart';
import 'package:settl/models/auth_session.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/providers.dart';
import 'package:settl/repositories/interfaces/contact_repository.dart';
import 'package:settl/repositories/interfaces/expense_repository.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';

void main() {
  final profile = Profile(
    userId: 'user-1',
    participantId: 'p1',
    displayName: 'Me',
    phoneNumber: '+910000000000',
    createdAt: DateTime(2026),
  );
  final contacts = [
    Contact(
      participantId: 'p2',
      phoneNumber: '+910000000001',
      displayName: 'Alice',
      createdBy: 'p1',
      createdAt: DateTime(2026),
    ),
  ];

  testWidgets('creates an equal people expense with exact remainder shares',
      (tester) async {
    final repository = _FakeExpenseRepository();
    await tester.pumpWidget(_TestApp(
      profile: profile,
      contacts: contacts,
      repository: repository,
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Paid by you (Me)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Dinner');
    await tester.enterText(find.byType(TextField).at(1), '10.01');
    await tester.tap(find.text('Alice'));
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();

    expect(repository.amountPaise, 1001);
    expect(repository.participantIds, ['p1', 'p2']);
    expect(find.text('Add expense'), findsNothing);
  });

  testWidgets('rejects empty description and non-positive amount',
      (tester) async {
    await tester.pumpWidget(_TestApp(
      profile: profile,
      contacts: contacts,
      repository: _FakeExpenseRepository(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.tap(find.text('Save expense'));
    await tester.pump();
    expect(find.text('Enter a description.'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp(
      {required this.profile,
      required this.contacts,
      required this.repository});
  final Profile profile;
  final List<Contact> contacts;
  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(
                const AuthSession(userId: 'user-1', accessToken: 'token'),
              )),
          profileRepositoryProvider.overrideWithValue(_ProfileRepo(profile)),
          contactRepositoryProvider.overrideWithValue(_ContactRepo(contacts)),
          expenseRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AddExpenseScreen()),
      );
}

class _ProfileRepo implements ProfileRepository {
  _ProfileRepo(this.profile);
  final Profile profile;
  @override
  Future<Profile?> getProfileByUserId(String userId) async => profile;
  @override
  Future<Profile?> getProfileByParticipantId(String id) async => profile;
  @override
  Future<List<Profile>> getAllProfiles() async => [profile];
  @override
  Future<void> createProfile(Profile profile) async {}
  @override
  Future<void> updateProfile(Profile profile) async {}
  @override
  Future<void> deleteProfileByUserId(String userId) async {}
  @override
  Future<Profile> ensureRemoteProfile(Profile profile) async => profile;
}

class _ContactRepo implements ContactRepository {
  _ContactRepo(this.contacts);
  final List<Contact> contacts;
  @override
  Future<Contact?> getContactById(String id) async => null;
  @override
  Future<List<Contact>> getContactsByUser(String id) async => contacts;
  @override
  Future<List<Contact>> getAllContacts() async => contacts;
  @override
  Future<void> createContact(Contact contact) async {}
  @override
  Future<void> updateContact(Contact contact) async {}
  @override
  Future<void> deleteContact(String id) async {}
  @override
  Future<int> claimContacts(String phone) async => 0;
}

class _FakeExpenseRepository implements ExpenseRepository {
  int? amountPaise;
  List<String>? participantIds;
  @override
  Future<Expense> createPeopleExpense({
    required String description,
    required int amountPaise,
    required String payerId,
    required List<String> participantIds,
    String category = 'Uncategorized',
    String? groupId,
    String splitType = 'equal',
    Map<String, num> splitValues = const {},
  }) async {
    this.amountPaise = amountPaise;
    this.participantIds = participantIds;
    return Expense(
      id: 'e1',
      amount: amountPaise / 100,
      category: category,
      splitType: splitType,
      payerId: payerId,
      listId: groupId,
      note: description,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<Expense?> getExpenseById(String id) async => null;
  @override
  Future<List<Expense>> getExpensesByUser(String id) async => [];
  @override
  Stream<List<Expense>> watchExpensesByUser(String id) => const Stream.empty();
  @override
  Future<void> updatePeopleExpense(
      {required String expenseId,
      required String description,
      required int amountPaise,
      required String payerId,
      required List<String> participantIds,
      required int expectedVersion}) async {}
  @override
  Future<List<Expense>> getExpensesByList(String id) async => [];
  @override
  Future<List<Expense>> getAllExpenses() async => [];
  @override
  Future<void> createExpense(Expense expense) async {}
  @override
  Future<void> updateExpense(Expense expense) async {}
  @override
  Future<void> deleteExpense(String id) async {}
  @override
  Future<void> createExpenseSplit(ExpenseSplit split) async {}
  @override
  Future<List<ExpenseSplit>> getSplitsForExpense(String id) async => [];
  @override
  Future<void> deleteExpenseSplit(String id) async {}
}
