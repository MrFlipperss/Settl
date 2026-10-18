import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../models/collection_member.dart';
import '../../models/contact.dart';
import '../../providers.dart';

class GroupMembersScreen extends ConsumerStatefulWidget {
  const GroupMembersScreen({required this.group, super.key});

  final Collection group;

  @override
  ConsumerState<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends ConsumerState<GroupMembersScreen> {
  late Future<_MemberData> _membersFuture;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<_MemberData> _loadMembers() async {
    final session = ref.read(authStateProvider).value;
    if (session == null) throw StateError('Sign in to manage group members.');
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (profile == null || profile.participantId.trim().isEmpty) {
      throw StateError('Your profile is not ready.');
    }
    final groups = await ref
        .read(collectionRepositoryProvider)
        .getCollectionsByUser(profile.participantId);
    if (!groups.any((group) => group.id == widget.group.id)) {
      throw StateError('You do not have access to this group.');
    }
    final members = await ref
        .read(collectionRepositoryProvider)
        .getMembersOfCollection(widget.group.id);
    final contacts = await ref
        .read(contactRepositoryProvider)
        .getContactsByUser(profile.participantId);
    return _MemberData(
      profileParticipantId: profile.participantId,
      profileName: profile.displayName,
      members: members,
      contacts: contacts,
    );
  }

  Future<void> _addMember(_MemberData data) async {
    final choices = data.contacts
        .where((contact) => !data.members
            .any((member) => member.participantId == contact.participantId))
        .toList();
    if (choices.isEmpty) {
      _showMessage('No available contacts to add.');
      return;
    }
    final contact = await showModalBottomSheet<Contact>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Add a person')),
            for (final choice in choices)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(choice.displayName),
                subtitle: Text(choice.phoneNumber),
                onTap: () => Navigator.of(context).pop(choice),
              ),
          ],
        ),
      ),
    );
    if (contact == null || !mounted) return;
    setState(() => _isMutating = true);
    try {
      final member = CollectionMember(
        collectionId: widget.group.id,
        participantId: contact.participantId,
        addedAt: DateTime.now(),
      );
      await ref
          .read(collectionRepositoryProvider)
          .addMemberToCollection(member);
      if (!mounted) return;
      setState(() {
        data.members.add(member);
        _isMutating = false;
      });
      _showMessage('${contact.displayName} added.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isMutating = false);
      _showMessage('Could not add member: ${_friendlyError(error)}');
    }
  }

  Future<void> _removeMember(_MemberData data, CollectionMember member) async {
    final contact = data.contactFor(member.participantId);
    setState(() => _isMutating = true);
    try {
      await ref.read(collectionRepositoryProvider).removeMemberFromCollection(
            widget.group.id,
            member.participantId,
          );
      if (!mounted) return;
      setState(() {
        data.members
            .removeWhere((item) => item.participantId == member.participantId);
        _isMutating = false;
      });
      _showMessage('${contact?.displayName ?? member.participantId} removed.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isMutating = false);
      _showMessage('Could not remove member: ${_friendlyError(error)}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _friendlyError(Object error) => error is StateError
      ? error.message
      : error is ArgumentError
          ? error.message?.toString() ?? 'invalid member'
          : 'Please try again.';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.group.name)),
        body: FutureBuilder<_MemberData>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                    'Couldn’t load members: ${_friendlyError(snapshot.error!)}'),
              );
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Members',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    FilledButton.icon(
                      onPressed: _isMutating ? null : () => _addMember(data),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add person'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (data.members.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('No members in this group yet.')),
                  )
                else
                  for (final member in data.members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                      title: Text(data.displayNameFor(member.participantId)),
                      trailing: IconButton(
                        tooltip: 'Remove member',
                        onPressed: _isMutating
                            ? null
                            : () => _removeMember(data, member),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ),
              ],
            );
          },
        ),
      );
}

class _MemberData {
  _MemberData({
    required this.profileParticipantId,
    required this.profileName,
    required this.members,
    required this.contacts,
  });

  final String profileParticipantId;
  final String profileName;
  final List<CollectionMember> members;
  final List<Contact> contacts;

  Contact? contactFor(String participantId) {
    for (final contact in contacts) {
      if (contact.participantId == participantId) return contact;
    }
    return null;
  }

  String displayNameFor(String participantId) {
    if (participantId == profileParticipantId) return profileName;
    return contactFor(participantId)?.displayName ?? participantId;
  }
}
