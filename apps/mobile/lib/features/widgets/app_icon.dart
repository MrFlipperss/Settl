import 'package:flutter/material.dart';

/// Renders one of the design's line icons from a string id (mapped onto
/// Material icons). Falls back to a generic circle for unknown ids.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.id, {
    super.key,
    this.size = 18,
    this.color,
  });

  final String id;
  final double size;
  final Color? color;

  static const Map<String, IconData> _icons = {
    'food': Icons.restaurant_outlined,
    'travel': Icons.directions_car_outlined,
    'grocery': Icons.shopping_cart_outlined,
    'bills': Icons.bolt_outlined,
    'fun': Icons.movie_outlined,
    'income': Icons.currency_rupee_outlined,
    'home': Icons.home_outlined,
    'beach': Icons.beach_access_outlined,
    'people': Icons.groups_outlined,
    'activity': Icons.show_chart_outlined,
    'profile': Icons.person_outlined,
    'settings': Icons.settings_outlined,
    'logout': Icons.logout_outlined,
    'receipt': Icons.receipt_long_outlined,
    'ticket': Icons.confirmation_number_outlined,
    'close': Icons.close,
    'chevron': Icons.chevron_right,
    'plus': Icons.add,
    'qr': Icons.qr_code,
    'share': Icons.ios_share,
    'check': Icons.check,
    'calendar': Icons.calendar_today_outlined,
    'search': Icons.search,
    'backspace': Icons.backspace_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Icon(
      _icons[id] ?? Icons.circle_outlined,
      size: size,
      color: color,
    );
  }
}
