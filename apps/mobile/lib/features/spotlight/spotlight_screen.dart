import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpotlightScreen extends ConsumerWidget {
  const SpotlightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotlight')),
      body: const Center(child: Text('Text-to-action input')),
    );
  }
}
