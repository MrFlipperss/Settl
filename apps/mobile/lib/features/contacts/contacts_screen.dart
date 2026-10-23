import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/contact.dart';
import '../../providers.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Contact> _contacts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final session = ref.read(authStateProvider).value;
      if (session == null) {
        setState(() {
          _contacts = const [];
          _error = 'Sign in to view contacts.';
          _loading = false;
        });
        return;
      }
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfileByUserId(session.userId);
      if (profile == null) throw StateError('Your profile is not ready.');
      final contacts = await ref
          .read(contactRepositoryProvider)
          .getContactsByUser(profile.participantId);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load contacts. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _addContact() async {
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _AddContactDialog(),
    );
    if (values == null || _saving) return;
    final name = values.$1.trim();
    final phone = values.$2.trim();
    if (name.isEmpty || phone.isEmpty) return;
    setState(() => _saving = true);
    try {
      final session = ref.read(authStateProvider).value;
      final profile = session == null
          ? null
          : await ref
              .read(profileRepositoryProvider)
              .getProfileByUserId(session.userId);
      if (profile == null) throw StateError('Sign in to add a contact.');
      await ref.read(contactRepositoryProvider).createContact(Contact(
            participantId: const Uuid().v4(),
            phoneNumber: phone,
            displayName: name,
            createdBy: profile.participantId,
            createdAt: DateTime.now(),
          ));
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact saved and queued to sync.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add contact.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _addContact,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_outlined),
            tooltip: 'Add contact',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Message(icon: Icons.error_outline, text: _error!)
              : _contacts.isEmpty
                  ? const _Message(
                      icon: Icons.people_outline,
                      text: 'No contacts yet. Add someone to use them in an expense.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contacts.length,
                      itemBuilder: (_, index) {
                        final contact = _contacts[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(contact.displayName),
                          subtitle: Text(contact.phoneNumber),
                        );
                      },
                    ),
    );
  }
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();
  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _error;
  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }
  void _submit() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      setState(() => _error = 'Enter a name and phone number.');
      return;
    }
    Navigator.pop(context, (_name.text, _phone.text));
  }
  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add contact'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: 'Name', errorText: _error)),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48), const SizedBox(height: 12), Text(text, textAlign: TextAlign.center),
        ]),
      ));
}
