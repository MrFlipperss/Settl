import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/expense.dart';
import '../../providers.dart';

/// Activity tab. Kept intentionally simple until transaction history is wired
/// to the repository-backed presentation layer.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: auth.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load activity.')),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Sign in to view activity.'));
          }
          return FutureBuilder(
            future: ref
                .read(profileRepositoryProvider)
                .getProfileByUserId(session.userId),
            builder: (context, profile) {
              if (profile.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final participantId = profile.data?.participantId;
              if (participantId == null || participantId.isEmpty) {
                return const Center(child: Text('Your profile is not ready.'));
              }
              return StreamBuilder<List<Expense>>(
                stream: ref
                    .read(expenseRepositoryProvider)
                    .watchExpensesByUser(participantId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final expenses = snapshot.data ?? const <Expense>[];
                  if (expenses.isEmpty) {
                    return const Center(child: Text('No expenses yet.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: expenses.length,
                    itemBuilder: (_, index) {
                      final expense = expenses[index];
                      return ListTile(
                        title: Text(expense.note ?? expense.category),
                        subtitle: Text(
                            '${expense.createdAt.day}/${expense.createdAt.month}/${expense.createdAt.year}'),
                        trailing: Text('₹${expense.amount.toStringAsFixed(2)}'),
                        onTap: () => context.push('/expenses/${expense.id}'),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
