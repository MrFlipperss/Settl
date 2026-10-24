import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/collection.dart';
import '../../api/api_exception.dart';
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
    final selection = await showModalBottomSheet<_MemberSelection>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Add a person')),
            if (choices.isEmpty)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('No saved contacts yet'),
              ),
            for (final choice in choices)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(choice.displayName),
                subtitle: Text(choice.phoneNumber),
                onTap: () => Navigator.of(context)
                    .pop(_MemberSelection.existing(choice)),
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined),
              title: const Text('Create contact and add'),
              onTap: () =>
                  Navigator.of(context).pop(const _MemberSelection.createNew()),
            ),
          ],
        ),
      ),
    );
    if (selection == null || !mounted) return;

    Contact? contact = selection.contact;
    if (selection.createNew) {
      final values = await showDialog<(String, String)>(
        context: context,
        builder: (_) => const _NewContactDialog(),
      );
      if (values == null || !mounted) return;
      contact = Contact(
        participantId: const Uuid().v4(),
        displayName: values.$1.trim(),
        phoneNumber: values.$2.trim(),
        createdBy: data.profileParticipantId,
        createdAt: DateTime.now(),
      );
    }
    if (contact == null) return;

    setState(() => _isMutating = true);
    var failureContext = 'add member';
    try {
      if (selection.createNew) {
        failureContext = 'save contact';
        await ref.read(contactRepositoryProvider).createContact(contact);
      }
      final member = CollectionMember(
        collectionId: widget.group.id,
        participantId: contact.participantId,
        addedAt: DateTime.now(),
      );
      failureContext = 'add member to group';
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
      _showMessage('Could not $failureContext: ${_friendlyError(error)}');
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
          : error is ApiException
              ? error.message
              : error.toString();

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
                if (_isMutating) const LinearProgressIndicator(),
                if (_isMutating) const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Members',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    FilledButton.icon(
                      onPressed: _isMutating ? null : () => _addMember(data),
                      icon: _isMutating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_outlined),
                      label: Text(_isMutating ? 'Saving…' : 'Add person'),
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

class _MemberSelection {
  const _MemberSelection.existing(this.contact) : createNew = false;
  const _MemberSelection.createNew()
      : contact = null,
        createNew = true;

  final Contact? contact;
  final bool createNew;
}

class _NewContactDialog extends StatefulWidget {
  const _NewContactDialog();

  @override
  State<_NewContactDialog> createState() => _NewContactDialogState();
}

class _NewContactDialogState extends State<_NewContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'Enter a name and phone number.');
      return;
    }
    Navigator.of(context).pop((name, phone));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add someone to the group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: 'Name', errorText: _error),
            ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      );
}
