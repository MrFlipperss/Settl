import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/design_sheet.dart';

/// Appearance / notifications / account settings.
class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  bool _emailNotif = true;
  bool _pushNotif = true;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final mode = ref.watch(themeModeProvider);
    final accentIdx = ref.watch(accentIndexProvider);

    return DesignSheet(
      maxHeightFactor: 0.9,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: tokens.onSurface,
                    ),
                  ),
                ),
                _CloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const _SectionLabel('Appearance'),
          Container(
            width: double.infinity,
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
                  'Theme',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ModeButton(
                      label: 'Light',
                      icon: 'bills',
                      selected: mode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .state = ThemeMode.light,
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(
                      label: 'Dark',
                      icon: 'fun',
                      selected: mode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .state = ThemeMode.dark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
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
                  'Accent colour',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < accentPresets.length; i++)
                      _AccentSwatch(
                        preset: accentPresets[i],
                        selected: i == accentIdx,
                        onTap: () => ref
                            .read(accentIndexProvider.notifier)
                            .state = i,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  accentPresets[accentIdx].name,
                  style: TextStyle(fontSize: 12, color: tokens.onSurfaceVar),
                ),
              ],
            ),
          ),

          const _SectionLabel('Notifications'),
          _SettingRow(
            icon: 'receipt',
            label: 'Email notifications',
            sub: 'Reminders and due alerts',
            trailing: _Toggle(
              on: _emailNotif,
              onChanged: (v) => setState(() => _emailNotif = v),
            ),
          ),
          _SettingRow(
            icon: 'activity',
            label: 'Push notifications',
            sub: 'Real-time payment updates',
            trailing: _Toggle(
              on: _pushNotif,
              onChanged: (v) => setState(() => _pushNotif = v),
            ),
          ),

          const _SectionLabel('Account'),
          const _SettingRow(icon: 'receipt', label: 'Email', sub: 'rahul.sharma@gmail.com'),
          const _SettingRow(icon: 'people', label: 'Phone', sub: '+91 98765 43210'),
          const _SettingRow(icon: 'settings', label: 'Privacy & data'),

          const _SectionLabel('Session'),
          Material(
            color: const Color(0x16EF4444),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon('logout', size: 17, color: Color(0xFFD85050)),
                    SizedBox(width: 10),
                    Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD85050),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'SplitKaro v2.4.1 · Made with ♥',
              style: TextStyle(fontSize: 11, color: tokens.onSurfaceVar),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: tokens.primary,
        ),
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
          child: AppIcon('close', size: 16, color: tokens.onSurfaceVar),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
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
        color: selected ? tokens.container : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? tokens.primary : tokens.border,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(
                  icon,
                  size: 20,
                  color: selected ? tokens.onContainer : tokens.onSurfaceVar,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AccentPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: preset.hex,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? tokens.onSurface : Colors.transparent,
            width: 3,
          ),
        ),
        child: selected
            ? Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: preset.hex, width: 2),
                ),
              )
            : null,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.sub,
    this.trailing,
  });

  final String icon;
  final String label;
  final String? sub;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon(icon, size: 18, color: tokens.onSurfaceVar),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: tokens.onSurface,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    sub!,
                    style: TextStyle(fontSize: 12, color: tokens.onSurfaceVar),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              AppIcon('chevron', size: 16, color: tokens.onSurfaceVar),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onChanged});

  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    return GestureDetector(
      onTap: () => onChanged(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        decoration: BoxDecoration(
          color: on ? tokens.primary : tokens.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: on ? Colors.white : tokens.onSurfaceVar,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
