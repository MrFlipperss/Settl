import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../mock_data.dart';
import '../sheets/settings_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_sheet.dart';
import '../widgets/person_avatar.dart';

const List<({String id, String label, String icon})> _tabs = [
  (id: 'overview', label: 'Overview', icon: 'home'),
  (id: 'groups', label: 'Groups', icon: 'people'),
  (id: 'receipts', label: 'Receipts', icon: 'receipt'),
  (id: 'tickets', label: 'Tickets', icon: 'ticket'),
];

/// Design Profile: overview stats, groups, receipts and tickets.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _tab = 'overview';

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                color: tokens.headerBg,
                padding: const EdgeInsets.fromLTRB(20, 52, 20, 72),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'RS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rahul Sharma',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'rahul@okaxis · UPI active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net balance',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            const Text(
                              '+₹1,950',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Foreground card
              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.cardBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final tab in _tabs) ...[
                              _ProfileTab(
                                label: tab.label,
                                icon: tab.icon,
                                selected: _tab == tab.id,
                                onTap: () => setState(() => _tab = tab.id),
                              ),
                              if (tab.id != _tabs.last.id)
                                const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      switch (_tab) {
                        'groups' => _buildGroups(tokens),
                        'receipts' => _buildReceipts(tokens),
                        'tickets' => _buildTickets(tokens),
                        _ => _buildOverview(tokens),
                      },
                      // Compensates the -28 translate so the scroll view
                      // ends flush with the card's painted bottom edge.
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Gear button over the header
        Positioned(
          top: 14,
          right: 14,
          child: Material(
            color: Colors.white.withValues(alpha: 0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  DesignSheet.show(context, child: const SettingsSheet()),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: AppIcon('settings', size: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverview(DesignTokens tokens) {
    const stats = [
      (label: 'You owe', value: '₹1,450', color: Color(0xFFC0504A)),
      (label: 'Owed to you', value: '₹3,400', color: Color(0xFF4A9060)),
      (label: 'Groups', value: '4', color: null),
      (label: 'Transactions', value: '38', color: null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            for (var row = 0; row < 2; row++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: row == 0 ? 10 : 18,
                ),
                child: Row(
                  children: [
                    for (var col = 0; col < 2; col++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: col == 0 ? 10 : 0,
                          ),
                          child: _StatTile(
                            label: stats[row * 2 + col].label,
                            value: stats[row * 2 + col].value,
                            color: stats[row * 2 + col].color ??
                                tokens.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'RECENT ACTIVITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: tokens.primary,
            ),
          ),
        ),
        const SizedBox(height: 10),
        for (final person in people.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  PersonAvatar(person),
                  const SizedBox(width: 12),
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
                    '${person.amount > 0 ? '+' : ''}₹${formatInr(person.amount.abs())}',
                    style: TextStyle(
                      fontSize: 14,
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
      ],
    );
  }

  Widget _buildGroups(DesignTokens tokens) {
    return Column(
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tokens.container,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppIcon(
                      group.icon,
                      size: 20,
                      color: tokens.onContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tokens.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.members} members',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.onSurfaceVar,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    group.balance == 0
                        ? 'Settled'
                        : '${group.balance > 0 ? '+' : ''}₹${formatInr(group.balance.abs())}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: group.balance > 0
                          ? AppTheme.positive
                          : group.balance < 0
                              ? AppTheme.negative
                              : tokens.onSurfaceVar,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReceipts(DesignTokens tokens) {
    return Column(
      children: [
        for (final receipt in receipts)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tokens.container,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppIcon(
                      'receipt',
                      size: 16,
                      color: tokens.onContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.merchant,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: tokens.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${receipt.category} · ${receipt.date}',
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.onSurfaceVar,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${formatInr(receipt.amount)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: tokens.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTickets(DesignTokens tokens) {
    return Column(
      children: [
        for (final ticket in tickets)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: tokens.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tokens.headerBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.event,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ticket.venue,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.date,
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: ticket.status == 'confirmed'
                                ? const Color(0x184A9060)
                                : const Color(0x18B08820),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            ticket.status == 'confirmed'
                                ? 'Confirmed'
                                : 'Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ticket.status == 'confirmed'
                                  ? AppTheme.positive
                                  : const Color(0xFFB08820),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: tokens.onSurfaceVar,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
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
    return Material(
      color: selected ? tokens.container : tokens.surfaceVariant,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? tokens.onContainer : tokens.onSurfaceVar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
