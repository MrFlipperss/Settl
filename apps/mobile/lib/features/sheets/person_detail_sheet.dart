import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../mock_data.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_qr_code.dart';
import '../widgets/design_sheet.dart';

/// Person detail sheet: balance, UPI request QR and settle actions.
class PersonDetailSheet extends StatefulWidget {
  const PersonDetailSheet({super.key, required this.person});

  final Person person;

  @override
  State<PersonDetailSheet> createState() => _PersonDetailSheetState();
}

class _PersonDetailSheetState extends State<PersonDetailSheet> {
  bool _showUpi = false;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final person = widget.person;
    final owedToMe = person.amount > 0;
    final amount = person.amount.abs();

    return DesignSheet(
      maxHeightFactor: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Coloured header
          Container(
            width: double.infinity,
            color: person.color,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        person.initials,
                        style: const TextStyle(
                          fontSize: 18,
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
                          Text(
                            person.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            person.upi,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  owedToMe ? '${person.name} owes you' : 'You owe ${person.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${formatInr(amount)}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (owedToMe && _showUpi)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'UPI Request · ₹${formatInr(amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: tokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const DesignQrCode(),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Note',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: tokens.onSurfaceVar,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"${person.name} owes ₹${formatInr(amount)} — settling via UPI"',
                            style: TextStyle(
                              fontSize: 13,
                              color: tokens.onSurface,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                if (owedToMe)
                  _ActionButton(
                    label: _showUpi ? 'Share QR Code' : 'Send UPI QR Code',
                    icon: _showUpi ? 'share' : 'qr',
                    onTap: () => setState(() => _showUpi = !_showUpi),
                  ),
                if (!owedToMe) const SizedBox(height: 10),
                _ActionButton(
                  label: 'Settle Up',
                  icon: 'check',
                  accent: owedToMe,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = true,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final bg = accent ? tokens.container : tokens.surfaceVariant;
    final fg = accent ? tokens.onContainer : tokens.onSurfaceVar;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
