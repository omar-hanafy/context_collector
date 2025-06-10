import 'package:context_collector/src/features/editor/ui/widgets/monaco_editor_integrated.dart';
import 'package:flutter/material.dart';

/// A simple, stateless container whose only job is to render the
/// self-contained [MonacoEditorIntegrated] widget.
///
/// All logic for listening to state changes has been moved up to the
/// [GlobalMonacoContainer] for better reliability.
class MonacoEditorContainer extends StatelessWidget {
  const MonacoEditorContainer({super.key});

  @override
  Widget build(BuildContext context) {
    // This widget now has only one responsibility: build the editor UI.
    return const MonacoEditorIntegrated();
  }
}
