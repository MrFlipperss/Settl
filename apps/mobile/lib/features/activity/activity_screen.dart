import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../mock_data.dart';
import '../widgets/app_icon.dart';

/// Design Activity: Transactions and Budgets sub-tabs.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _showBudgets = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: tokens.headerBg,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 72),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'August 2024',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Activity',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SubTab(
                        label: 'Transactions',
                        icon: 'activity',
                        selected: !_showBudgets,
                        onTap: () => setState(() => _showBudgets = false),
                      ),
                      const SizedBox(width: 6),
                      _SubTab(
                        label: 'Budgets',
                        icon: 'income',
                        selected: _showBudgets,
                        onTap: () => setState(() => _showBudgets = true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_showBudgets)
                    ..._buildTransactionGroups(tokens)
                  else
                    ..._buildBudgetList(tokens),
                  // Compensates the -28 translate so the scroll view ends
                  // flush with the card's painted bottom edge.
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionGroups(DesignTokens tokens) {
    final byDate = <String, List<Transaction>>{};
    for (final tx in transactions) {
      byDate.putIfAbsent(tx.date, () => []).add(tx);
    }
    return [
      for (final entry in byDate.entries) ...[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            entry.key.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: tokens.onSurfaceVar,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: tokens.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < entry.value.length; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i < entry.value.length - 1
                        ? Border(bottom: BorderSide(color: tokens.border))
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: _TransactionRow(tx: entry.value[i]),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildBudgetList(DesignTokens tokens) {
    return [
      for (final cat in categories)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BudgetCard(category: cat),
        ),
    ];
  }
}

class _SubTab extends StatelessWidget {
  const _SubTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Expanded(
      child: Material(
        color: selected ? tokens.container : tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon,
                  size: 14,
                  color: selected ? tokens.onContainer : tokens.onSurfaceVar,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? tokens.onContainer : tokens.onSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});

  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final income = tx.amount > 0;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tokens.container,
            borderRadius: BorderRadius.circular(13),
          ),
          child: AppIcon(tx.icon, size: 18, color: tokens.onContainer),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tx.merchant,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: tokens.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tx.category,
                style: TextStyle(fontSize: 11, color: tokens.onSurfaceVar),
              ),
            ],
          ),
        ),
        Text(
          '${income ? '+' : '−'}₹${formatInr(tx.amount.abs())}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: income ? AppTheme.positive : tokens.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final pct = (category.spent / category.budget).clamp(0.0, 1.0);
    final over = category.spent > category.budget;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AppIcon(category.icon, size: 20, color: category.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '₹${formatInr(category.spent)} of ₹${formatInr(category.budget)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                over
                    ? 'Over'
                    : '${(100 - pct * 100).round()}% left',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: over ? AppTheme.negative : AppTheme.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 7,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(100),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: over ? AppTheme.negative : category.color,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
