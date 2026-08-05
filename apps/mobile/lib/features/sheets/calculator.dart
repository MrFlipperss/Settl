import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const List<String> _calcKeys = [
  'C', '±', '%', '÷',
  '7', '8', '9', '×',
  '4', '5', '6', '−',
  '1', '2', '3', '+',
  '0', '.', '⌫', '=',
];

/// Simple 4x5 calculator used inside the Home search card.
class Calculator extends StatefulWidget {
  const Calculator({super.key});

  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  String _display = '0';
  double? _prev;
  String? _op;
  bool _fresh = false;

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _prev = null;
        _op = null;
        _fresh = false;
      } else if (key == '⌫') {
        _display =
            _display.length > 1 ? _display.substring(0, _display.length - 1) : '0';
      } else if (key == '±') {
        _display = _display.startsWith('-')
            ? _display.substring(1)
            : '-$_display';
      } else if (key == '%') {
        _display = _formatNumber(double.parse(_display) / 100);
      } else if (['÷', '×', '−', '+'].contains(key)) {
        _prev = double.parse(_display);
        _op = key;
        _fresh = true;
      } else if (key == '=') {
        if (_prev == null || _op == null) return;
        final cur = double.parse(_display);
        final result = switch (_op!) {
          '÷' => _prev! / cur,
          '×' => _prev! * cur,
          '−' => _prev! - cur,
          _ => _prev! + cur,
        };
        _display = _formatNumber(result);
        _prev = null;
        _op = null;
        _fresh = false;
      } else if (key == '.') {
        if (_display.contains('.') && !_fresh) return;
        _display = _fresh ? '0.' : '$_display.';
        _fresh = false;
      } else {
        _display = _fresh
            ? key
            : _display == '0'
                ? key
                : '$_display$key';
        _fresh = false;
      }
    });
  }

  String _formatNumber(double value) {
    var s = value.toStringAsFixed(8);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    bool isOpKey(String k) => ['÷', '×', '−', '+'].contains(k);
    bool isClearKey(String k) => ['C', '±', '%', '⌫'].contains(k);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
              child: Text(
                _display,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  color: tokens.onSurface,
                ),
              ),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final key in _calcKeys)
                _CalcButton(
                  label: key,
                  isOp: isOpKey(key),
                  isEqual: key == '=',
                  isClear: isClearKey(key),
                  onPressed: () => _press(key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.isOp,
    required this.isEqual,
    required this.isClear,
    required this.onPressed,
  });

  final String label;
  final bool isOp;
  final bool isEqual;
  final bool isClear;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final accent = isOp || isEqual;
    final color = accent
        ? tokens.onContainer
        : isClear
            ? tokens.onSurfaceVar
            : tokens.onSurface;
    return Material(
      color: accent ? tokens.container : tokens.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: accent ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
