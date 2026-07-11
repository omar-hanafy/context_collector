import 'package:context_collector/context_collector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_monaco/flutter_monaco.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invisible helper that warms Monaco on app start so the first editor
/// render is fast. Place it anywhere in the app tree.
///
/// On native platforms this runs the full initialization: WebViews load
/// while detached, so the editor can boot completely offscreen. On web an
/// editor page only loads while its platform view is painted in the tree,
/// which a surfaceless helper never is - booting here would burn the whole
/// ready timeout and park the session in an error state. Web therefore
/// only warms the browser's HTTP cache with the Monaco bundle
/// ([MonacoAssets.precache]); EditorScreen starts the real boot when an
/// editor surface exists.
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
      if (kIsWeb) {
        await MonacoAssets.precache();
      } else {
        await ref.read(monacoEditorStatusProvider.notifier).initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
