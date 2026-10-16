import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../mock_data.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_sheet.dart';
import '../widgets/person_avatar.dart';

const List<String> _digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];

/// Two-step "Add Expense" flow: amount numpad, then details.
class AddExpenseSheet extends StatefulWidget {
  const AddExpenseSheet({super.key});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amount = '';
  String _description = '';
  String _category = categories.first.name;
  String _date = '';
  final Set<String> _splitWith = {};
  bool _detailsStep = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _togglePerson(String name) {
    setState(() {
      if (!_splitWith.remove(name)) _splitWith.add(name);
    });
  }

  void _handleDigit(String d) {
    setState(() {
      if (d == '.') {
        if (_amount.contains('.')) return;
        if (_amount.isEmpty) {
          _amount = '0.';
          return;
        }
      }
      if (_amount == '0') {
        _amount = d;
        return;
      }
      _amount += d;
    });
  }

  void _handleDelete() {
    setState(() {
      _amount = _amount.length <= 1 ? '' : _amount.substring(0, _amount.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final amountEntered = _amount.isNotEmpty;

    return DesignSheet(
      maxHeightFactor: 0.92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: tokens.onSurface,
                    ),
                  ),
                ),
                _CloseButton(onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          if (!_detailsStep)
            _buildAmountStep(tokens, amountEntered)
          else
            _buildDetailsStep(tokens, amountEntered),
        ],
      ),
    );
  }

  Widget _buildAmountStep(DesignTokens tokens, bool amountEntered) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            children: [
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: tokens.onSurfaceVar,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: Text(
                      '₹',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: tokens.onSurfaceVar,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _amount.isEmpty ? '0' : _amount,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2,
                      height: 1.0,
                      color: tokens.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: [
              for (final d in _digits)
                Material(
                  color: tokens.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => d == '⌫' ? _handleDelete() : _handleDigit(d),
                    child: Center(
                      child: d == '⌫'
                          ? AppIcon('backspace', size: 20, color: tokens.onSurfaceVar)
                          : Text(
                              d,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w400,
                                color: tokens.onSurface,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'Continue',
              enabled: amountEntered,
              onPressed: () => setState(() => _detailsStep = true),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep(DesignTokens tokens, bool amountEntered) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: () => setState(() => _detailsStep = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: tokens.container,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${formatInr(double.parse(amountEntered ? _amount : '0'))}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: tokens.onContainer,
                    ),
                  ),
                  AppIcon('chevron', size: 14, color: tokens.onContainer),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('Description'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _description),
            onChanged: (v) => setState(() => _description = v),
            style: TextStyle(fontSize: 14, color: tokens.onSurface),
            decoration: InputDecoration(
              hintText: 'e.g. Dinner at Smoke House',
              hintStyle: TextStyle(color: tokens.onSurfaceVar),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Category'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in categories)
                _ChoiceChip(
                  label: cat.name,
                  icon: cat.icon,
                  selected: _category == cat.name,
                  onTap: () => setState(() => _category = cat.name),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Date'),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: _date),
            onChanged: (v) => setState(() => _date = v),
            style: TextStyle(fontSize: 14, color: tokens.onSurface),
            decoration: InputDecoration(
              suffixIcon: AppIcon('calendar', size: 16, color: tokens.onSurfaceVar),
            ),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Split with'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in people)
                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => _togglePerson(p.name),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 7, 14, 7),
                    decoration: BoxDecoration(
                      color: _splitWith.contains(p.name)
                          ? tokens.container
                          : tokens.surfaceVariant,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: _splitWith.contains(p.name)
                            ? tokens.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PersonAvatar(p, size: 24, fontSize: 9),
                        const SizedBox(width: 7),
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _splitWith.contains(p.name)
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _splitWith.contains(p.name)
                                ? tokens.onContainer
                                : tokens.onSurfaceVar,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: 'Save Expense',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Material(
      color: tokens.surfaceVariant,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AppIcon('close', size: 15, color: tokens.onSurfaceVar),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Material(
      color: enabled ? tokens.primary : tokens.surfaceVariant,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : tokens.onSurfaceVar,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: tokens.onSurfaceVar,
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                icon,
                size: 13,
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
