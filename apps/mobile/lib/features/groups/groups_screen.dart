import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/collection.dart';
import '../../providers.dart';
import 'group_members_screen.dart';

/// Groups the signed-in participant belongs to.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  int _refreshToken = 0;
  bool _isCreating = false;

  Future<void> _openCreateGroup() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _CreateGroupDialog(),
    );
    if (name == null || !mounted) return;

    final session = ref.read(authStateProvider).value;
    if (session == null) {
      _showMessage('Sign in to create a group.');
      return;
    }

    setState(() => _isCreating = true);
    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getProfileByUserId(session.userId);
      if (profile == null || profile.participantId.trim().isEmpty) {
        throw StateError('Your profile is not ready to create a group.');
      }

      await ref
          .read(collectionRepositoryProvider)
          .createCollectionForParticipant(
            name: name,
            participantId: profile.participantId,
          );
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _refreshToken++;
      });
      _showMessage('Group created and queued to sync.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _showMessage('Could not create group: ${_friendlyError(error)}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _friendlyError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'invalid name';
    }
    if (error is StateError) {
      return error.message;
    }
    return 'Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Your groups', style: theme.textTheme.titleLarge),
                ),
                OutlinedButton.icon(
                  onPressed: _isCreating ? null : _openCreateGroup,
                  icon: const Icon(Icons.add),
                  label: Text(_isCreating ? 'Creating…' : 'Create group'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _GroupsContent(key: ValueKey(_refreshToken)),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a group name.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Create group'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Group name',
            hintText: 'e.g. Goa trip',
            errorText: _error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(onPressed: _submit, child: const Text('Create')),
        ],
      );
}

class _GroupsContent extends ConsumerWidget {
  const _GroupsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _LoadingState(),
      error: (_, __) => const _ErrorState(),
      data: (session) {
        if (session == null) return const _SignedOutState();

        final profileRepository = ref.watch(profileRepositoryProvider);
        return FutureBuilder(
          future: profileRepository.getProfileByUserId(session.userId),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingState();
            }
            if (profileSnapshot.hasError) return const _ErrorState();

            final profile = profileSnapshot.data;
            if (profile == null || profile.participantId.trim().isEmpty) {
              return const _EmptyState();
            }

            final repository = ref.watch(collectionRepositoryProvider);
            return FutureBuilder<List<Collection>>(
              future: repository.getCollectionsByUser(profile.participantId),
              builder: (context, groupsSnapshot) {
                if (groupsSnapshot.connectionState != ConnectionState.done) {
                  return const _LoadingState();
                }
                if (groupsSnapshot.hasError) return const _ErrorState();

                final groups = groupsSnapshot.data ?? const <Collection>[];
                if (groups.isEmpty) return const _EmptyState();

                return Column(
                  children: [
                    for (final group in groups) _GroupCard(group: group),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final Collection group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          child: const Icon(Icons.groups_outlined),
        ),
        title: Text(group.name, style: textTheme.titleMedium),
        subtitle: Text('Account ${group.accountNumber}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => GroupMembersScreen(group: group),
          ));
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) => const _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Couldn’t load groups',
        message: 'Try again when your groups are available offline.',
      );
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) => const _MessageState(
        icon: Icons.lock_outline,
        title: 'Sign in to view groups',
        message: 'Your groups are private to your account.',
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const _MessageState(
        icon: Icons.groups_outlined,
        title: 'No groups yet',
        message: 'Groups you join will appear here.',
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
