import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/config/config_provider.dart';
import 'package:settl/theme/app_theme.dart';
import 'providers.dart';
import 'routing/app_router.dart';

class SettlApp extends ConsumerStatefulWidget {
  const SettlApp({super.key});

  @override
  ConsumerState<SettlApp> createState() => _SettlAppState();
}

class _SettlAppState extends ConsumerState<SettlApp> {
  bool _syncStarted = false;

  @override
  void initState() {
    super.initState();
    // T8.5 — reconcile whenever a session appears (fresh sign-in / session
    // restore). Best-effort: where the auth stack is unavailable (e.g. widget
    // tests), registration no-ops instead of crashing the app shell.
    try {
      ref.listenManual(authStateProvider, (previous, next) {
        if (next.value != null) unawaited(_reconcileRemote());
      });
    } catch (error) {
      debugPrint('SettlApp: session listener unavailable ($error)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = accentPresets[ref.watch(accentIndexProvider)];

    // T8.5 — start the sync layer once, after the first frame: reconcile the
    // remote profile + claims, then run the initial drain and pull.
    if (!_syncStarted) {
      _syncStarted = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => unawaited(_startSync()));
    }

    final isDark = themeMode == ThemeMode.dark;
    final theme = AppTheme.build(accent: accent, isDark: isDark);
    final darkTheme = AppTheme.build(accent: accent, isDark: true);

    return MaterialApp.router(
      title: appConfig.appName,
      debugShowCheckedModeBanner: !appConfig.enableDebug, // Hide debug banner in production
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }

  /// T8.5 — bootstraps the sync layer once the first frame has rendered:
  /// reconciles the remote profile + claims, then starts the sync service.
  ///
  /// Best-effort by design: when the auth stack or the connectivity plugin is
  /// unavailable (e.g. widget tests), the bootstrap degrades to a no-op
  /// instead of crashing the app shell.
  Future<void> _startSync() async {
    if (!mounted) return;
    try {
      await _reconcileRemote();
      await ref.read(syncServiceProvider).start();
    } catch (error) {
      debugPrint('SettlApp: sync bootstrap skipped ($error)');
    }
  }

  /// T8.5 — reconciles the signed-in user with the backend: ensures the remote
  /// profile exists (idempotent `POST /v1/profile`), claims unclaimed contacts
  /// matching the phone number, then drains + refreshes. All remote calls are
  /// best-effort — offline failures simply defer to the next sync pass.
  Future<void> _reconcileRemote() async {
    if (!mounted) return;
    final session = ref.read(authServiceProvider).currentSession;
    if (session == null) return;

    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfileByUserId(session.userId);
    if (!mounted || profile == null) return;

    try {
      await ref.read(profileRepositoryProvider).ensureRemoteProfile(profile);
    } catch (_) {
      // Offline / backend unreachable — retried on the next sync pass.
    }
    try {
      await ref
          .read(contactRepositoryProvider)
          .claimContacts(profile.phoneNumber);
    } catch (_) {
      // Same — claim is retried on the next sync pass.
    }

    if (!mounted) return;
    final sync = ref.read(syncServiceProvider);
    if (sync.isOnline) await sync.requestSync();
  }
}
