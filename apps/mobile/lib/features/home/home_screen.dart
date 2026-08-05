import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../mock_data.dart';
import '../sheets/calculator.dart';
import '../sheets/person_detail_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_sheet.dart';
import '../widgets/person_avatar.dart';
import '../widgets/spending_ring.dart';

const int _spent = 14280;
const int _budget = 20000;

/// Design Home: budget header, spending by category, search + calculator,
/// and dues.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openPerson(BuildContext context, Person person) {
    DesignSheet.show(context, child: PersonDetailSheet(person: person));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final pct = (_spent / _budget).clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Coloured header
          Container(
            color: tokens.headerBg,
            padding: const EdgeInsets.fromLTRB(22, 52, 22, 72),
            child: Stack(
              children: [
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: -20,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'August 2024',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${formatInr(_spent)}',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'of ₹${formatInr(_budget)} budget',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: 180,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: pct,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${formatInr(_budget - _spent)} remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const SpendingRing(spent: _spent, budget: _budget),
                  ],
                ),
              ],
            ),
          ),

          // Foreground card — rounded top corners overlap the header.
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
                  _buildCategoriesCard(tokens),
                  const SizedBox(height: 14),
                  _buildSearchCard(tokens),
                  const SizedBox(height: 14),
                  _buildDuesCard(tokens, context),
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

  Widget _buildCategoriesCard(DesignTokens tokens) {
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
              Expanded(
                child: Text(
                  'Spending by category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.onSurface,
                  ),
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final cat in categories) _CategoryRow(category: cat),
        ],
      ),
    );
  }

  Widget _buildSearchCard(DesignTokens tokens) {
    return _SearchCard(tokens: tokens);
  }

  Widget _buildDuesCard(DesignTokens tokens, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dues',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.onSurface,
                  ),
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: tokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final person in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: tokens.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openPerson(context, person),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        PersonAvatar(person),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: tokens.onSurface,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                person.upi,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.onSurfaceVar,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${person.amount > 0 ? '+' : '−'}₹${formatInr(person.amount.abs())}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: person.amount > 0
                                ? AppTheme.positive
                                : AppTheme.negative,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final pct = (category.spent / category.budget).clamp(0.0, 1.0);
    final over = category.spent > category.budget;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: AppIcon(
                  category.icon,
                  size: 14,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurface,
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '₹${formatInr(category.spent)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: over ? AppTheme.negative : tokens.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: ' / ₹${formatInr(category.budget)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: tokens.onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            height: 5,
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

class _SearchCard extends StatefulWidget {
  const _SearchCard({required this.tokens});

  final DesignTokens tokens;

  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  bool _showCalc = false;

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppIcon('search', size: 16, color: tokens.onSurfaceVar),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search expenses…',
                  style: TextStyle(fontSize: 14, color: tokens.onSurfaceVar),
                ),
              ),
              Material(
                color: _showCalc ? tokens.container : tokens.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _showCalc = !_showCalc),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: AppIcon(
                      'bills',
                      size: 16,
                      color: _showCalc
                          ? tokens.onContainer
                          : tokens.onSurfaceVar,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showCalc) ...[
            const SizedBox(height: 12),
            const Calculator(),
          ],
        ],
      ),
    );
  }
}
