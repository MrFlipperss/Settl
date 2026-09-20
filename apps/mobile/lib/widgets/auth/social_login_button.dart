import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.text,
  });

  final String provider;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define colors for different providers
    late final Color backgroundColor;
    late final Color foregroundColor;

    switch (provider.toLowerCase()) {
      case 'google':
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurface;
        break;
      case 'apple':
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurface;
        break;
      default:
        backgroundColor = colorScheme.surfaceContainerHighest;
        foregroundColor = colorScheme.onSurface;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Implement actual social login
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$provider sign-in coming soon!'),
                backgroundColor: colorScheme.primaryContainer,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForProvider(provider),
                  color: foregroundColor,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      default:
        return Icons.login;
    }
  }
}