import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contact.dart';
import '../../models/expense.dart';
import '../../models/expense_split.dart';
import '../../models/pending_sync_operation.dart';
import '../../providers.dart';
import '../../sync/sync_service.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});
  final String expenseId;
  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  late Future<_ExpenseData> _future;
  StreamSubscription<SyncStatus>? _syncStatusSub;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _syncStatusSub =
        ref.read(syncServiceProvider).statusStream.listen((status) {
      if (status == SyncStatus.idle || status == SyncStatus.error) {
        _refresh();
      }
    });
  }

  void _refresh() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  @override
  void dispose() {
    _syncStatusSub?.cancel();
    super.dispose();
  }

  Future<_ExpenseData> _load() async {
    final session = ref.read(authStateProvider).value;
    if (session == null) throw StateError('Sign in to view this expense.');
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (profile == null) throw StateError('Your profile is not ready.');
    final expenses = await ref
        .read(expenseRepositoryProvider)
        .getExpensesByUser(profile.participantId);
    final matches = expenses.where((item) => item.id == widget.expenseId);
    final expense = matches.isEmpty ? null : matches.first;
    if (expense == null) {
      throw StateError('Expense not found or access was denied.');
    }
    final splits = await ref
        .read(expenseRepositoryProvider)
        .getSplitsForExpense(expense.id);
    final contacts = await ref
        .read(contactRepositoryProvider)
        .getContactsByUser(profile.participantId);
    PendingSyncOperation? pendingOperation;
    for (final operation
        in await ref.read(pendingSyncDaoProvider).getPending()) {
      if (operation.entityId == expense.id && operation.syncedAt == null) {
        pendingOperation = operation;
        break;
      }
    }
    return _ExpenseData(expense, splits, profile.participantId,
        profile.displayName, contacts, pendingOperation);
  }

  Future<void> _edit(_ExpenseData data) async {
    if (data.expense.payerId != data.profileParticipantId) return;
    final result = await showModalBottomSheet<_EditValues>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditExpenseSheet(data: data),
    );
    if (result == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(expenseRepositoryProvider).updatePeopleExpense(
            expenseId: data.expense.id,
            description: result.description,
            amountPaise: result.amountPaise,
            payerId: data.expense.payerId,
            participantIds: result.participantIds,
            expectedVersion: data.expense.version,
          );
      final sync = ref.read(syncServiceProvider);
      unawaited(sync.requestSync());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _future = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Expense updated locally and queued to sync.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Could not update expense: ${error is ArgumentError ? error.message : 'Please try again.'}')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Expense details')),
        body: FutureBuilder<_ExpenseData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(snapshot.error.toString())));
            }
            final data = snapshot.data!;
            final canEdit = data.expense.payerId == data.profileParticipantId;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (_saving) const LinearProgressIndicator(),
              ListTile(
                  title: Text(data.expense.note ?? data.expense.category,
                      style: Theme.of(context).textTheme.headlineSmall),
                  subtitle: Text(_date(data.expense.createdAt)),
                  trailing: Text('₹${data.expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge)),
              const SizedBox(height: 12),
              Text(
                  data.syncError != null
                      ? 'Sync failed: ${data.syncError}'
                      : data.pending
                          ? 'Pending sync'
                          : 'Synced',
                  style: TextStyle(
                      color: data.syncError != null
                          ? Theme.of(context).colorScheme.error
                          : data.pending
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.primary)),
              if (data.pending)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      await ref.read(syncServiceProvider).requestSync();
                      _refresh();
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Retry sync now'),
                  ),
                ),
              const Divider(),
              Text(
                  'Paid by: ${canEdit ? data.profileName : data.expense.payerId}'),
              const SizedBox(height: 12),
              Text('Participants',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final split in data.splits)
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data.nameFor(split.participantId)),
                    trailing: Text('₹${split.shareAmount.toStringAsFixed(2)}')),
              if (canEdit)
                FilledButton.icon(
                    onPressed: _saving ? null : () => _edit(data),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(_saving ? 'Saving…' : 'Edit expense')),
            ]);
          },
        ),
      );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ExpenseData {
  _ExpenseData(this.expense, this.splits, this.profileParticipantId,
      this.profileName, this.contacts, this.pendingOperation);
  final Expense expense;
  final List<ExpenseSplit> splits;
  final String profileParticipantId;
  final String profileName;
  final List<Contact> contacts;
  final PendingSyncOperation? pendingOperation;
  bool get pending => pendingOperation != null;
  String? get syncError => pendingOperation?.lastError;
  String nameFor(String id) {
    for (final contact in contacts) {
      if (contact.participantId == id) return contact.displayName;
    }
    return id;
  }
}

class _EditValues {
  const _EditValues(this.description, this.amountPaise, this.participantIds);
  final String description;
  final int amountPaise;
  final List<String> participantIds;
}

class _EditExpenseSheet extends StatefulWidget {
  const _EditExpenseSheet({required this.data});
  final _ExpenseData data;
  @override
  State<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<_EditExpenseSheet> {
  late final TextEditingController _description =
      TextEditingController(text: widget.data.expense.note ?? '');
  late final TextEditingController _amount = TextEditingController(
      text: widget.data.expense.amount.toStringAsFixed(2));
  late final Set<String> _selected =
      widget.data.splits.map((s) => s.participantId).toSet();
  int? _paise(String value) {
    final text = value.trim();
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text)) return null;
    final p = text.split('.');
    return int.parse(p.first) * 100 +
        int.parse((p.length == 1 ? '' : p[1]).padRight(2, '0').isEmpty
            ? '0'
            : (p.length == 1 ? '' : p[1]).padRight(2, '0'));
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Wrap(children: [
        Text('Edit expense', style: Theme.of(context).textTheme.titleLarge),
        TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description')),
        TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Amount', prefixText: '₹ ')),
        const SizedBox(height: 8),
        Text(
            'Paid by: ${widget.data.profileName} (only the original payer can edit)'),
        const SizedBox(height: 12),
        const Text('Split equally between'),
        for (final contact in widget.data.contacts)
          CheckboxListTile(
              value: _selected.contains(contact.participantId),
              title: Text(contact.displayName),
              onChanged: (v) => setState(() => v == true
                  ? _selected.add(contact.participantId)
                  : _selected.remove(contact.participantId)),
              contentPadding: EdgeInsets.zero),
        CheckboxListTile(
            value: _selected.contains(widget.data.expense.payerId),
            title: Text(widget.data.profileName),
            onChanged: (v) => setState(() => v == true
                ? _selected.add(widget.data.expense.payerId)
                : _selected.remove(widget.data.expense.payerId)),
            contentPadding: EdgeInsets.zero),
        FilledButton(
            onPressed: () {
              final amount = _paise(_amount.text);
              if (_description.text.trim().isEmpty ||
                  amount == null ||
                  amount <= 0 ||
                  _selected.isEmpty ||
                  !_selected.contains(widget.data.expense.payerId)) {
                return;
              }
              Navigator.pop(
                  context,
                  _EditValues(
                      _description.text.trim(), amount, _selected.toList()));
            },
            child: const Text('Save changes')),
      ]));
}
