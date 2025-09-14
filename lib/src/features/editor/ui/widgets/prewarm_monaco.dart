import 'package:context_collector/context_collector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invisible helper that initializes Monaco on app start so the first
/// editor render is instant. Place it anywhere in the app tree.
class PrewarmMonaco extends ConsumerStatefulWidget {
  const PrewarmMonaco({super.key});

  @override
  ConsumerState<PrewarmMonaco> createState() => _PrewarmMonacoState();
}

class _PrewarmMonacoState extends ConsumerState<PrewarmMonaco> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Kick off initialization once.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _started) return;
      _started = true;
      await ref.read(monacoEditorStatusProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
