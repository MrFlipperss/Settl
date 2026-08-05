import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bottom sheet shell matching the design: scrim + rounded top card that
/// slides up with a drag handle.
class DesignSheet extends StatelessWidget {
  const DesignSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.88,
    this.padding,
  });

  final Widget child;
  final double maxHeightFactor;
  final EdgeInsetsGeometry? padding;

  /// Shows [content] as a design-styled bottom sheet, returning the sheet's
  /// value when it closes.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double maxHeightFactor = 0.88,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      backgroundColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => DesignSheet(
        maxHeightFactor: maxHeightFactor,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        decoration: BoxDecoration(
          color: tokens.cardBg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: tokens.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
