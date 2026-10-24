import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/expense.dart';
import '../../providers.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  static const _budgetPrefix = 'spotlight.budget.';

  List<Expense> _expenses = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgets = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (key.startsWith(_budgetPrefix)) {
          budgets[key.substring(_budgetPrefix.length)] = prefs.getInt(key) ?? 0;
        }
      }
      if (mounted) ref.read(budgetLimitsProvider.notifier).state = budgets;

      var expenses = <Expense>[];
      final session = ref.read(authStateProvider).value ??
          await ref.read(authStateProvider.future);
      if (session != null) {
        final profile = await ref
            .read(profileRepositoryProvider)
            .getProfileByUserId(session.userId);
        if (profile != null) {
          expenses = await ref
              .read(expenseRepositoryProvider)
              .getExpensesByUser(profile.participantId);
        }
      }
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _editBudget({String? oldKey}) async {
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (_) => _BudgetDialog(
        initialCategory: oldKey == null ? '' : _categoryName(oldKey),
        initialAmount:
            oldKey == null ? null : ref.read(budgetLimitsProvider)[oldKey],
      ),
    );
    if (result == null || !mounted) return;

    final key = _slug(result.$1);
    if (key.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    if (oldKey != null && oldKey != key) {
      await prefs.remove('$_budgetPrefix$oldKey');
    }
    await prefs.setInt('$_budgetPrefix$key', result.$2);
    ref.read(budgetLimitsProvider.notifier).state = {
      ...ref.read(budgetLimitsProvider),
      key: result.$2,
    };
    await _load();
    if (mounted) _message('${_categoryName(key)} budget saved.');
  }

  Future<void> _deleteBudget(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Remove the ${_categoryName(key)} budget limit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_budgetPrefix$key');
    final budgets = Map<String, int>.of(ref.read(budgetLimitsProvider))
      ..remove(key);
    ref.read(budgetLimitsProvider.notifier).state = budgets;
    await _load();
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  double _spentThisMonth(String key) {
    final now = DateTime.now();
    return _expenses
        .where((expense) =>
            expense.createdAt.year == now.year &&
            expense.createdAt.month == now.month &&
            _slug(expense.category) == key)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  static String _slug(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  static String _categoryName(String value) => value
      .split('-')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetLimitsProvider);
    final keys = budgets.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _editBudget(),
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : keys.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      Text(
                        'Monthly limits by category',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final key in keys)
                        _BudgetCard(
                          category: _categoryName(key),
                          budget: budgets[key] ?? 0,
                          spent: _spentThisMonth(key),
                          onEdit: () => _editBudget(oldKey: key),
                          onDelete: () => _deleteBudget(key),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.savings_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text('No budgets yet',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              const Text(
                'Create a monthly limit here, or set one from Spotlight with “set food budget 6000”.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _editBudget(),
                icon: const Icon(Icons.add),
                label: const Text('Create budget'),
              ),
            ],
          ),
        ),
      );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.category,
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final String category;
  final int budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = budget <= 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    final overBudget = spent > budget;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: overBudget ? colors.error : colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_money(spent)} spent of ₹$budget this month'
              '${overBudget ? ' • ₹${_money(spent - budget)} over' : ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: overBudget ? colors.error : colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({this.initialCategory = '', this.initialAmount});

  final String initialCategory;
  final int? initialAmount;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final TextEditingController _categoryController;
  late final TextEditingController _amountController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.initialCategory);
    _amountController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (category.isEmpty || amount == null || amount <= 0 || !amount.isFinite) {
      setState(() => _error = 'Enter a category and a positive monthly limit.');
      return;
    }
    Navigator.of(context).pop((category, amount.round()));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(
            widget.initialAmount == null ? 'Create budget' : 'Edit budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _categoryController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'Food',
                errorText: _error,
              ),
            ),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly limit',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Save')),
        ],
      );
}
