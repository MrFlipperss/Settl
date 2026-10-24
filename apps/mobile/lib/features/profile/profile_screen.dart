import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/auth_session.dart';
import '../../models/profile.dart';
import '../../providers.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  Profile? _profile;
  String? _loadedProfileUserId;
  String? _loadingProfileUserId;
  bool _savingDisplayName = false;

  @override
  void dispose() {
    _searchController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final profile =
          await ref.read(profileRepositoryProvider).getProfileByUserId(userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loadedProfileUserId = userId;
        _loadingProfileUserId = null;
        _displayNameController.text = profile?.displayName ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfileUserId = null);
    }
  }

  Future<void> _saveDisplayName() async {
    final profile = _profile;
    final displayName = _displayNameController.text.trim();
    if (profile == null || _savingDisplayName) return;
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a display name.')),
      );
      return;
    }

    setState(() => _savingDisplayName = true);
    try {
      final updated = profile.copyWith(displayName: displayName);
      await ref.read(profileRepositoryProvider).updateProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _savingDisplayName = false;
      });
      unawaited(ref.read(syncServiceProvider).requestSync());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name saved and queued to sync.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _savingDisplayName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save display name.')),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(authServiceProvider).signOut();
      } catch (_) {
        // Fallback for offline / test environments
      }
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;
    AuthSession? session;
    try {
      session = ref.watch(authStateProvider).value;
    } catch (_) {
      session = null;
    }
    if (session != null &&
        _loadedProfileUserId != session.userId &&
        _loadingProfileUserId != session.userId) {
      _loadingProfileUserId = session.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_loadProfile(session!.userId));
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person_outline), text: 'Profile & Settings'),
              Tab(icon: Icon(Icons.widgets_outlined), text: 'Manage'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search Bar at Top of Screen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search profile, settings or groups...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Profile & Settings
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      // User Info Card
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.person,
                                  size: 32,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      session != null &&
                                              session.userId.isNotEmpty
                                          ? _profile?.displayName ??
                                              'Your profile'
                                          : 'Guest User',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      session != null &&
                                              session.userId.isNotEmpty
                                          ? 'ID: ${session.userId.substring(0, session.userId.length > 8 ? 8 : session.userId.length)}...'
                                          : 'Sign in to sync your data',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (session != null && _profile != null) ...[
                        TextField(
                          controller: _displayNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveDisplayName(),
                          decoration: const InputDecoration(
                            labelText: 'Display name',
                            hintText: 'How should people see you?',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed:
                                _savingDisplayName ? null : _saveDisplayName,
                            icon: _savingDisplayName
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                                _savingDisplayName ? 'Saving…' : 'Save name'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text('Appearance',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_outlined),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {themeMode},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          ref.read(themeModeProvider.notifier).state =
                              selection.first;
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('Accent colour',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (var index = 0;
                              index < accentPresets.length;
                              index++)
                            Tooltip(
                              message: accentPresets[index].name,
                              child: InkResponse(
                                onTap: () => ref
                                    .read(accentIndexProvider.notifier)
                                    .state = index,
                                radius: 26,
                                child: Semantics(
                                  button: true,
                                  selected: index == accentIndex,
                                  label: '${accentPresets[index].name} accent',
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: accentPresets[index].hex,
                                    child: index == accentIndex
                                        ? const Icon(Icons.check,
                                            color: Colors.white, size: 20)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${accentPresets[accentIndex].name} palette',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  )),
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Account Actions (Log Out / Log In)
                      if (session != null && session.userId.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Log out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            side: BorderSide(color: colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.login),
                          label: const Text('Log in / Sign up'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                    ],
                  ),
                  const _ProfileManageView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileManageView extends StatelessWidget {
  const _ProfileManageView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
      children: [
        Text('Manage Settl', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('People, groups and budgets',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
        const SizedBox(height: 16),
        _ManageDestinationTile(
          icon: Icons.groups_outlined,
          title: 'Groups',
          subtitle: 'Create groups and manage members',
          onTap: () => context.push('/groups'),
        ),
        _ManageDestinationTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budgets',
          subtitle: 'Set and review monthly limits',
          onTap: () => context.go('/budgets'),
        ),
        _ManageDestinationTile(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Contacts',
          subtitle: 'Add and manage people you split with',
          onTap: () => context.push('/contacts'),
        ),
      ],
    );
  }
}

class _ManageDestinationTile extends StatelessWidget {
  const _ManageDestinationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: ListTile(
        leading: Icon(icon, color: colors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
