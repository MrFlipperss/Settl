import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/expense.dart';
import '../../models/profile.dart';
import '../../providers.dart';
import '../../sync/sync_service.dart';
import 'spotlight_parser.dart';

/// T9 — Home screen.
///
/// Not a dashboard: the primary interaction is a prominent search/spotlight
/// affordance for finding people and creating expenses. Below it sit a compact
/// row of quick actions and a short list of recent expenses. A subtle sync
/// indicator lives in the AppBar actions — never as a banner.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settl'),
        actions: [
          IconButton(
            tooltip: 'Add expense',
            onPressed: () => context.push('/expenses/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            const _SpotlightSearchBar(),
            const SizedBox(height: 20),
            const SizedBox(height: 4),
            Text('Recent', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const _RecentExpenses(),
          ],
        ),
      ),
    );
  }
}

/// T9.5 — Subtle sync indicator rendered inside the AppBar actions.
///
/// Watches [SyncService] status and connectivity, showing at most one small
/// (~16-18px) muted icon. Renders nothing when idle and online by design.
class _SyncIndicator extends ConsumerStatefulWidget {
  const _SyncIndicator();

  @override
  ConsumerState<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends ConsumerState<_SyncIndicator> {
  SyncStatus _status = SyncStatus.idle;
  bool _online = false;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    // Best-effort: the sync provider chain reaches the Drift database, which
    // throws [MissingPluginException] in the widget-test environment. Degrade
    // to an invisible indicator instead of crashing the build.
    try {
      final sync = ref.read(syncServiceProvider);
      _status = sync.status;
      _online = sync.isOnline;
    } catch (_) {
      _available = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();

    final SyncService sync;
    try {
      sync = ref.watch(syncServiceProvider);
    } catch (_) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<SyncStatus>(
      stream: sync.statusStream,
      initialData: _status,
      builder: (context, statusSnapshot) {
        return StreamBuilder<bool>(
          stream: sync.onlineStream,
          initialData: _online,
          builder: (context, onlineSnapshot) {
            final status = statusSnapshot.data ?? _status;
            final online = onlineSnapshot.data ?? _online;
            return _buildIndicator(context, ref, status, online);
          },
        );
      },
    );
  }

  Widget _buildIndicator(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
    bool online,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Idle + online → invisible by design.
    if (status == SyncStatus.idle && online) {
      return const SizedBox.shrink();
    }

    // Syncing → tiny progress indicator.
    if (status == SyncStatus.syncing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Error + online → muted amber warning, tap to retry.
    if (status == SyncStatus.error && online) {
      return Tooltip(
        message: 'Sync paused — tap to retry',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => ref.read(syncServiceProvider).requestSync(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: colorScheme.tertiary,
            ),
          ),
        ),
      );
    }

    // Offline (or error while offline) → muted cloud_off.
    return Tooltip(
      message: 'Offline — changes will sync later',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          Icons.cloud_off_outlined,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Spotlight parses natural-language commands into an editable draft. Every
/// write is made only after the user taps Confirm in the preview card.
class _SpotlightSearchBar extends ConsumerStatefulWidget {
  const _SpotlightSearchBar();

  @override
  ConsumerState<_SpotlightSearchBar> createState() =>
      _SpotlightSearchBarState();
}

class _SpotlightSearchBarState extends ConsumerState<_SpotlightSearchBar> {
  static const _parser = SpotlightParser();
  static const _budgetPrefix = 'spotlight.budget.';
  static const _subscriptionsKey = 'spotlight.subscriptions';

  final _queryController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _personController = TextEditingController();
  final _subscriptionController = TextEditingController();
  final _upiController = TextEditingController();
  late Future<_SpotlightData> _dataFuture;
  _SpotlightData? _data;
  SpotlightAction? _action;
  final Set<String> _selectedParticipants = {};
  List<String> _savedSubscriptions = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
    _loadSavedActions();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _personController.dispose();
    _subscriptionController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<_SpotlightData> _loadData() async {
    final session = ref.read(authStateProvider).value ??
        await ref.read(authStateProvider.future).catchError((_) => null);
    if (session == null) return const _SpotlightData();

    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (profile == null) return const _SpotlightData();

    var contacts = <SpotlightPerson>[];
    var groups = <SpotlightGroup>[];
    try {
      final storedContacts = await ref
          .read(contactRepositoryProvider)
          .getContactsByUser(profile.participantId);
      contacts = [
        SpotlightPerson(id: profile.participantId, name: profile.displayName),
        for (final contact in storedContacts)
          if (contact.participantId != profile.participantId)
            SpotlightPerson(
              id: contact.participantId,
              name: contact.displayName,
            ),
      ];
    } catch (_) {
      contacts = [
        SpotlightPerson(id: profile.participantId, name: profile.displayName),
      ];
    }
    try {
      final repository = ref.read(collectionRepositoryProvider);
      final collections =
          await repository.getCollectionsByUser(profile.participantId);
      groups = [
        for (final collection in collections)
          SpotlightGroup(
            id: collection.id,
            name: collection.name,
            memberIds: (await repository.getMembersOfCollection(collection.id))
                .map((member) => member.participantId)
                .toList(),
          ),
      ];
    } catch (_) {
      // Search remains useful with contacts if group membership is unavailable.
    }
    return _SpotlightData(
      profile: profile,
      people: contacts,
      groups: groups,
    );
  }

  Future<void> _loadSavedActions() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _savedSubscriptions = prefs.getStringList(_subscriptionsKey) ?? [];
    });
  }

  void _parse(String value) {
    final data = _data;
    if (data == null) return;
    final action = _parser.parse(
      value,
      currentParticipantId: data.profile?.participantId ?? '',
      people: data.people,
      groups: data.groups,
      currentUpiId: data.profile?.upiId ?? '',
    );
    setState(() {
      _action = action;
      _selectedParticipants
        ..clear()
        ..addAll(action?.participantIds ?? const []);
      _amountController.text =
          action == null ? '' : _formatEditableAmount(action.amount);
      _descriptionController.text = action?.description ?? '';
      _personController.text = action?.personName ?? '';
      _subscriptionController.text = action?.subscriptionName ?? '';
      _upiController.text = action?.upiId ?? '';
    });
  }

  Future<void> _confirm() async {
    final action = _action;
    if (action == null || _saving) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _message('Enter an amount greater than zero.');
      return;
    }

    setState(() => _saving = true);
    try {
      switch (action.type) {
        case SpotlightActionType.expense:
          final data = _data;
          final profile = data?.profile;
          if (profile == null) {
            throw StateError('Sign in to save an expense.');
          }
          final participantIds = _selectedParticipants.toList();
          if (!participantIds.contains(profile.participantId)) {
            participantIds.insert(0, profile.participantId);
          }
          await ref.read(expenseRepositoryProvider).createPeopleExpense(
                description: _descriptionController.text.trim(),
                amountPaise: (amount * 100).round(),
                payerId: profile.participantId,
                participantIds: participantIds,
                category: action.category,
                groupId: action.groupId,
              );
          final sync = ref.read(syncServiceProvider);
          unawaited(sync.requestSync());
          break;
        case SpotlightActionType.budget:
          final category = action.category.trim();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
              '$_budgetPrefix${_slug(category)}', amount.round());
          ref.read(budgetLimitsProvider.notifier).state = {
            ...ref.read(budgetLimitsProvider),
            _slug(category): amount.round(),
          };
          break;
        case SpotlightActionType.subscription:
          final name = _subscriptionController.text.trim();
          if (name.isEmpty) throw StateError('Enter a subscription name.');
          final cycle = action.billingCycle ?? 'Monthly';
          final value = '$name • ₹${amount.toStringAsFixed(0)} $cycle';
          final prefs = await SharedPreferences.getInstance();
          _savedSubscriptions = [
            ...?prefs.getStringList(_subscriptionsKey),
            value,
          ];
          await prefs.setStringList(_subscriptionsKey, _savedSubscriptions);
          break;
        case SpotlightActionType.request:
          final upiId = _upiController.text.trim();
          if (!_validUpiId(upiId)) {
            throw StateError('Add a valid UPI ID to generate the request QR.');
          }
          final data = _data;
          final person = _personController.text.trim();
          final qrData = Uri(
            scheme: 'upi',
            host: 'pay',
            queryParameters: {
              'pa': upiId,
              'pn': data?.profile?.displayName ?? 'Settl user',
              'am': amount.toStringAsFixed(2),
              'cu': 'INR',
              'tn': 'Request from ${person.isEmpty ? 'friend' : person}',
            },
          ).toString();
          if (!mounted) return;
          setState(() => _saving = false);
          await _showRequestQr(qrData, amount, person);
          return;
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _action = null;
        _queryController.clear();
      });
      await _loadSavedActions();
      _message(switch (action.type) {
        SpotlightActionType.expense => 'Expense saved and queued to sync.',
        SpotlightActionType.budget => '${action.category} budget updated.',
        SpotlightActionType.subscription => 'Subscription saved.',
        SpotlightActionType.request => 'Request QR generated.',
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _message(
          error is StateError ? error.message : 'Could not save. Try again.');
    }
  }

  Future<void> _showRequestQr(String data, double amount, String person) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Request ₹${amount.toStringAsFixed(0)}${person.isEmpty ? '' : ' from $person'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(data: data, size: 220),
            const SizedBox(height: 8),
            const Text('Ask them to scan this with any UPI app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _action = null;
      _queryController.clear();
    });
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FutureBuilder<_SpotlightData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && _data != snapshot.data) {
          _data = snapshot.data;
          if (_queryController.text.isNotEmpty && _action == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _parse(_queryController.text);
            });
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onChanged: _parse,
              decoration: InputDecoration(
                hintText: 'Try “₹100 dinner with Sarah”',
                prefixIcon: const Icon(Icons.auto_awesome_outlined, size: 22),
                suffixIcon: _queryController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _action = null);
                        },
                      )
                    : const Icon(Icons.keyboard_arrow_right, size: 22),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            if (_action != null) ...[
              const SizedBox(height: 12),
              _buildPreview(colorScheme),
            ],
            if (_savedSubscriptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final subscription in _savedSubscriptions)
                    Chip(
                      avatar: const Icon(Icons.repeat, size: 16),
                      label: Text(subscription),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    final action = _action!;
    final people = _data?.people ?? const <SpotlightPerson>[];
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(_actionIcon(action.type), size: 16),
                  label: Text('${_actionLabel(action.type)} draft'),
                ),
                if (action.personName?.isNotEmpty == true)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(action.personName!),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                isDense: true,
              ),
            ),
            if (action.type == SpotlightActionType.expense) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: action.category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  isDense: true,
                ),
                items: KeywordExpenseCategorizer.categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(
                        () => _action = action.copyWith(category: category));
                  }
                },
              ),
              const SizedBox(height: 12),
              Text('Split equally with',
                  style: Theme.of(context).textTheme.labelLarge),
              Wrap(
                spacing: 8,
                children: [
                  for (final person in people)
                    FilterChip(
                      label: Text(person.id == _data?.profile?.participantId
                          ? 'You'
                          : person.name),
                      selected: _selectedParticipants.contains(person.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedParticipants.add(person.id);
                        } else if (person.id != _data?.profile?.participantId) {
                          _selectedParticipants.remove(person.id);
                        }
                      }),
                    ),
                ],
              ),
              if (action.groupId != null)
                Text('Group expense: ${action.personName}',
                    style: Theme.of(context).textTheme.bodySmall),
            ],
            if (action.type == SpotlightActionType.budget) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: action.category,
                decoration: const InputDecoration(
                  labelText: 'Budget category',
                  isDense: true,
                ),
                items: {
                  ...KeywordExpenseCategorizer.categories,
                  if (!KeywordExpenseCategorizer.categories
                      .contains(action.category))
                    action.category,
                }
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (category) {
                  if (category != null) {
                    setState(
                        () => _action = action.copyWith(category: category));
                  }
                },
              ),
            ],
            if (action.type == SpotlightActionType.request) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _personController,
                decoration: const InputDecoration(
                  labelText: 'Request from',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _upiController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Your UPI ID (QR recipient)',
                  hintText: 'name@bank',
                  isDense: true,
                ),
              ),
            ],
            if (action.type == SpotlightActionType.subscription) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _subscriptionController,
                decoration: const InputDecoration(
                  labelText: 'Subscription',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: action.billingCycle,
                decoration: const InputDecoration(
                  labelText: 'Billing cycle',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                ],
                onChanged: (cycle) {
                  if (cycle != null) {
                    setState(
                        () => _action = action.copyWith(billingCycle: cycle));
                  }
                },
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _confirm,
                icon: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving…' : 'Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatEditableAmount(double amount) =>
      amount == amount.roundToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);

  static bool _validUpiId(String value) =>
      RegExp(r'^[A-Za-z0-9._-]+@[A-Za-z0-9.-]+$').hasMatch(value);

  static String _slug(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  static String _actionLabel(SpotlightActionType type) => switch (type) {
        SpotlightActionType.expense => 'Expense',
        SpotlightActionType.budget => 'Budget update',
        SpotlightActionType.request => 'UPI request',
        SpotlightActionType.subscription => 'Subscription',
      };

  static IconData _actionIcon(SpotlightActionType type) => switch (type) {
        SpotlightActionType.expense => Icons.receipt_long_outlined,
        SpotlightActionType.budget => Icons.savings_outlined,
        SpotlightActionType.request => Icons.qr_code_2_outlined,
        SpotlightActionType.subscription => Icons.repeat,
      };
}

class _SpotlightData {
  const _SpotlightData({
    this.profile,
    this.people = const [],
    this.groups = const [],
  });

  final Profile? profile;
  final List<SpotlightPerson> people;
  final List<SpotlightGroup> groups;
}

/// T9.4 — One compact row of four quick-action tiles.
///
/// Every tile navigates to a real destination — no dead buttons. Styled
/// quietly (tertiary container) so the search bar stays the focal point.
class _RecentExpenses extends ConsumerWidget {
  const _RecentExpenses();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const _EmptyState(),
      data: (session) {
        if (session == null) {
          return const _EmptyState();
        }

        final profileRepository = ref.watch(profileRepositoryProvider);

        return FutureBuilder(
          future: profileRepository.getProfileByUserId(session.userId),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            final profile = profileSnapshot.data;
            if (profile == null || profile.participantId.trim().isEmpty) {
              return const _EmptyState();
            }

            return _RecentExpensesForParticipant(
              participantId: profile.participantId,
            );
          },
        );
      },
    );
  }
}

class _RecentExpensesForParticipant extends ConsumerWidget {
  const _RecentExpensesForParticipant({
    required this.participantId,
  });

  final String participantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(expenseRepositoryProvider);

    return StreamBuilder<List<Expense>>(
      stream: repository.watchExpensesByUser(participantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final expenses = snapshot.data;
        if (expenses == null || expenses.isEmpty) {
          return const _EmptyState();
        }

        final recent = [...expenses]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(children: [
          for (final expense in recent.take(5)) _ExpenseRow(expense: expense),
        ]);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No expenses yet',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your first expense to get started.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _categoryIcon(expense.category),
          size: 20,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      title: Text(
        expense.note ?? expense.category,
        style: textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(expense.createdAt),
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _formatAmount(expense.amount),
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => context.push('/expenses/${expense.id}'),
    );
  }

  /// Maps a handful of known categories to icons; everything else falls back
  /// to a neutral category icon.
  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'travel':
      case 'cab':
      case 'fuel':
        return Icons.directions_car_outlined;
      case 'groceries':
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'rent':
      case 'housing':
      case 'utilities':
        return Icons.home_outlined;
      case 'entertainment':
      case 'movies':
        return Icons.movie_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  /// Relative-ish date label: 'Today', 'Yesterday', else `dd MMM`.
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thatDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(thatDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]}';
  }

  /// Amount as `₹` + 2 decimals — no currency package.
  static String _formatAmount(double amount) {
    return '\u20B9${amount.toStringAsFixed(2)}';
  }
}
