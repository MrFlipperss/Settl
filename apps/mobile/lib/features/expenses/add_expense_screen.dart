import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile.dart';
import '../../providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  late Future<_PeopleData> _peopleFuture;
  String? _payerId;
  final _selectedIds = <String>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _peopleFuture = _loadPeople();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<_PeopleData> _loadPeople() async {
    final session = ref.read(authStateProvider).value ??
        await ref.read(authStateProvider.future);
    if (session == null) throw StateError('Sign in to add an expense.');
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (profile == null || profile.participantId.trim().isEmpty) {
      throw StateError('Your profile is not ready.');
    }
    final contacts = await ref
        .read(contactRepositoryProvider)
        .getContactsByUser(profile.participantId);
    final people = [
      _Person(id: profile.participantId, name: profile.displayName),
      for (final contact in contacts)
        if (contact.participantId != profile.participantId)
          _Person(id: contact.participantId, name: contact.displayName),
    ];
    _payerId ??= profile.participantId;
    _selectedIds.add(profile.participantId);
    return _PeopleData(profile: profile, people: people);
  }

  Future<void> _submit(_PeopleData data) async {
    final description = _descriptionController.text.trim();
    final amountPaise = _parsePaise(_amountController.text);
    if (description.isEmpty) {
      _showMessage('Enter a description.');
      return;
    }
    if (amountPaise == null || amountPaise <= 0) {
      _showMessage('Enter a positive amount with up to two decimals.');
      return;
    }
    if (_payerId == null || !_selectedIds.contains(_payerId)) {
      _showMessage('Select the payer and include them in the split.');
      return;
    }
    if (_selectedIds.isEmpty) {
      _showMessage('Select at least one person.');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(expenseRepositoryProvider).createPeopleExpense(
            description: description,
            amountPaise: amountPaise,
            payerId: _payerId!,
            participantIds: _selectedIds.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Expense saved locally and queued to sync.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Could not save expense: ${_friendlyError(error)}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static int? _parsePaise(String value) {
    final text = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;
    final decimals = parts.length == 1 ? '' : parts[1].padRight(2, '0');
    return rupees * 100 + int.parse(decimals.isEmpty ? '0' : decimals);
  }

  static String _friendlyError(Object error) => error is StateError
      ? error.message
      : error is ArgumentError
          ? error.message?.toString() ?? 'invalid expense'
          : 'Please try again.';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add expense')),
        body: FutureBuilder<_PeopleData>(
          future: _peopleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(_friendlyError(snapshot.error!)));
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Dinner, taxi, groceries…',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    hintText: '0.00',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _payerId,
                  decoration: const InputDecoration(labelText: 'Paid by'),
                  items: [
                    for (final person in data.people)
                      DropdownMenuItem(
                          value: person.id, child: Text(person.name)),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) => setState(() => _payerId = value),
                ),
                const SizedBox(height: 20),
                Text('Split equally between',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final person in data.people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedIds.contains(person.id),
                    title: Text(person.name),
                    onChanged: _isSubmitting
                        ? null
                        : (selected) => setState(() {
                              if (selected == true) {
                                _selectedIds.add(person.id);
                              } else {
                                _selectedIds.remove(person.id);
                              }
                            }),
                  ),
                if (_selectedIds.isNotEmpty &&
                    _parsePaise(_amountController.text) != null)
                  for (var i = 0; i < data.people.length; i++)
                    if (_selectedIds.contains(data.people[i].id))
                      Text(
                        '${data.people[i].name}: ₹${_sharePaise(_parsePaise(_amountController.text)!, _selectedIds.length, _selectedIds.toList().indexOf(data.people[i].id)) / 100.0}',
                      ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : () => _submit(data),
                  child: Text(_isSubmitting ? 'Saving…' : 'Save expense'),
                ),
              ],
            );
          },
        ),
      );

  static int _sharePaise(int total, int count, int index) {
    final base = total ~/ count;
    return base + (index < total % count ? 1 : 0);
  }
}

class _PeopleData {
  const _PeopleData({required this.profile, required this.people});
  final Profile profile;
  final List<_Person> people;
}

class _Person {
  const _Person({required this.id, required this.name});
  final String id;
  final String name;
}
