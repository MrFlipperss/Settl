import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:settl/features/groups/groups_screen.dart';
import 'package:settl/models/auth_session.dart';
import 'package:settl/models/collection.dart';
import 'package:settl/models/collection_member.dart';
import 'package:settl/models/contact.dart';
import 'package:settl/models/profile.dart';
import 'package:settl/providers.dart';
import 'package:settl/repositories/interfaces/collection_repository.dart';
import 'package:settl/repositories/interfaces/profile_repository.dart';
import 'package:settl/repositories/interfaces/contact_repository.dart';

void main() {
  const session = AuthSession(userId: 'auth-1', accessToken: 'token');
  final profile = Profile(
    userId: 'auth-1',
    participantId: 'participant-1',
    displayName: 'Test User',
    phoneNumber: '+911234567890',
    createdAt: DateTime(2026),
  );

  testWidgets('shows groups belonging to the current user only',
      (tester) async {
    final groups = [
      Collection(
        id: 'group-1',
        name: 'Goa Trip',
        accountNumber: 'ACC-1',
        createdBy: 'participant-2',
        createdAt: DateTime(2026, 1, 2),
      ),
    ];

    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository(groups),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Goa Trip'), findsOneWidget);
    expect(find.text('Account ACC-1'), findsOneWidget);
  });

  testWidgets('opens a group and manages its members', (tester) async {
    final group = Collection(
      id: 'group-1',
      name: 'Goa Trip',
      accountNumber: 'ACC-1',
      createdBy: 'participant-1',
      createdAt: DateTime(2026),
    );
    final repository = _FakeCollectionRepository([group]);
    repository.members.add(CollectionMember(
      collectionId: group.id,
      participantId: 'participant-2',
      addedAt: DateTime(2026),
    ));
    final contacts = _FakeContactRepository([
      Contact(
        participantId: 'participant-2',
        phoneNumber: '+910000000001',
        displayName: 'Alice',
        createdBy: 'participant-1',
        createdAt: DateTime(2026),
      ),
      Contact(
        participantId: 'participant-3',
        phoneNumber: '+910000000002',
        displayName: 'Bob',
        createdBy: 'participant-1',
        createdAt: DateTime(2026),
      ),
    ]);
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: repository,
      contacts: contacts,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goa Trip'));
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.text('Add person'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove member').last);
    await tester.pumpAndSettle();
    expect(repository.removedParticipantIds, contains('participant-3'));
  });

  testWidgets('creates a trimmed group and refreshes the list', (tester) async {
    final repository = _FakeCollectionRepository(const []);
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Weekend trip  ');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(repository.createdNames, ['Weekend trip']);
    expect(repository.createdParticipantIds, ['participant-1']);
    expect(find.text('Weekend trip'), findsOneWidget);
  });

  testWidgets('rejects an empty or whitespace-only group name', (tester) async {
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository(const []),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.text('Enter a group name.'), findsOneWidget);
    expect(find.text('No groups yet'), findsOneWidget);
  });

  testWidgets('disables duplicate submission while creation is pending',
      (tester) async {
    final completer = Completer<Collection>();
    final repository = _FakeCollectionRepository.pendingCreate(completer);
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: repository,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Pending group');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();

    expect(find.text('Creating…'), findsOneWidget);
    expect(repository.createCalls, 1);

    completer.complete(repository.addCreated('Pending group', 'participant-1'));
    await tester.pumpAndSettle();
    expect(find.text('Pending group'), findsOneWidget);
  });

  testWidgets('shows an understandable creation error', (tester) async {
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository.failing(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create group'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Broken group');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Could not create group:'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Create group'), findsOneWidget);
  });

  testWidgets('excludes groups belonging only to another user', (tester) async {
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository(const []),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Other user group'), findsNothing);
  });

  testWidgets('shows an empty state when the user has no groups',
      (tester) async {
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository(const []),
    ));
    await tester.pumpAndSettle();

    expect(find.text('No groups yet'), findsOneWidget);
    expect(find.text('Groups you join will appear here.'), findsOneWidget);
    expect(find.text('Create group'), findsOneWidget);
  });

  testWidgets('signed-out users do not see account-specific groups',
      (tester) async {
    await tester.pumpWidget(_TestApp(
      session: null,
      profile: profile,
      repository: _FakeCollectionRepository([
        Collection(
          id: 'private',
          name: 'Private group',
          accountNumber: 'ACC-9',
          createdBy: 'participant-1',
          createdAt: DateTime(2026),
        ),
      ]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to view groups'), findsOneWidget);
    expect(find.text('Private group'), findsNothing);
  });

  testWidgets('shows loading and error states', (tester) async {
    final completer = Completer<List<Collection>>();
    await tester.pumpWidget(_TestApp(
      session: session,
      profile: profile,
      repository: _FakeCollectionRepository.pending(completer.future),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t load groups'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.session,
    required this.profile,
    required this.repository,
    this.contacts,
  });

  final AuthSession? session;
  final Profile profile;
  final CollectionRepository repository;
  final ContactRepository? contacts;

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(session)),
          profileRepositoryProvider
              .overrideWithValue(_FakeProfileRepository(profile)),
          collectionRepositoryProvider.overrideWithValue(repository),
          contactRepositoryProvider.overrideWithValue(
            contacts ?? _FakeContactRepository(const []),
          ),
        ],
        child: const MaterialApp(home: GroupsScreen()),
      );
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);
  final Profile profile;

  @override
  Future<Profile?> getProfileByUserId(String userId) async =>
      userId == profile.userId ? profile : null;
  @override
  Future<Profile?> getProfileByParticipantId(String participantId) async =>
      null;
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

class _FakeCollectionRepository implements CollectionRepository {
  _FakeCollectionRepository(List<Collection> groups)
      : groups = List.of(groups),
        _future = null,
        _createCompleter = null,
        _creationError = null;
  _FakeCollectionRepository.pending(Future<List<Collection>> future)
      : groups = [],
        _future = future,
        _createCompleter = null,
        _creationError = null;
  _FakeCollectionRepository.pendingCreate(this._createCompleter)
      : groups = [],
        _future = null,
        _creationError = null;
  _FakeCollectionRepository.failing()
      : groups = [],
        _future = null,
        _createCompleter = null,
        _creationError = StateError('backend unavailable');

  final List<Collection> groups;
  final members = <CollectionMember>[];
  final removedParticipantIds = <String>[];
  final Future<List<Collection>>? _future;
  final Completer<Collection>? _createCompleter;
  final Object? _creationError;
  final createdNames = <String>[];
  final createdParticipantIds = <String>[];
  int createCalls = 0;

  Collection addCreated(String name, String participantId) {
    final collection = Collection(
      id: 'created-${createdNames.length}',
      name: name,
      accountNumber: 'PENDING',
      createdBy: participantId,
      createdAt: DateTime(2026),
    );
    groups.add(collection);
    return collection;
  }

  @override
  Future<List<Collection>> getCollectionsByUser(String userId) =>
      _future ?? Future.value(groups);
  @override
  Future<Collection?> getCollectionById(String collectionId) async => null;
  @override
  Future<List<Collection>> getAllCollections() async => groups;
  @override
  Future<void> createCollection(Collection collection) async {}
  @override
  Future<Collection> createCollectionForParticipant({
    required String name,
    required String participantId,
  }) async {
    createCalls++;
    if (_creationError != null) throw _creationError;
    createdNames.add(name.trim());
    createdParticipantIds.add(participantId);
    if (_createCompleter != null) return _createCompleter.future;
    return addCreated(name.trim(), participantId);
  }

  @override
  Future<void> updateCollection(Collection collection) async {}
  @override
  Future<void> deleteCollection(String collectionId) async {}
  @override
  Future<void> addMemberToCollection(CollectionMember collectionMember) async {
    members.add(collectionMember);
  }

  @override
  Future<List<CollectionMember>> getMembersOfCollection(
          String collectionId) async =>
      members.where((member) => member.collectionId == collectionId).toList();
  @override
  Future<void> removeMemberFromCollection(
      String collectionId, String participantId) async {
    removedParticipantIds.add(participantId);
    members.removeWhere((member) =>
        member.collectionId == collectionId &&
        member.participantId == participantId);
  }
}

class _FakeContactRepository implements ContactRepository {
  _FakeContactRepository(this.contacts);
  final List<Contact> contacts;

  @override
  Future<List<Contact>> getContactsByUser(String userId) async => contacts;
  @override
  Future<List<Contact>> getAllContacts() async => contacts;
  @override
  Future<Contact?> getContactById(String participantId) async {
    for (final contact in contacts) {
      if (contact.participantId == participantId) return contact;
    }
    return null;
  }

  @override
  Future<void> createContact(Contact contact) async {}
  @override
  Future<void> updateContact(Contact contact) async {}
  @override
  Future<void> deleteContact(String participantId) async {}
  @override
  Future<int> claimContacts(String phoneNumber) async => 0;
}
