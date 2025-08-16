import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

/// A widget that displays a Monaco Editor instance
class MonacoEditorView extends StatefulWidget {
  const MonacoEditorView({
    this.controller,
    this.onReady,
    super.key,
  });

  /// The controller for this editor instance
  /// If null, a default controller will be created automatically
  final MonacoController? controller;

  /// Callback when the editor is ready
  final VoidCallback? onReady;

  @override
  State<MonacoEditorView> createState() => _MonacoEditorViewState();
}

class _MonacoEditorViewState extends State<MonacoEditorView> {
  bool _isReady = false;
  MonacoController? _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() async {
    if (widget.controller != null) {
      _controller = widget.controller;
      _ownsController = false;
    } else {
      // Create a default controller with common options
      _controller = await MonacoController.create(
        options: const EditorOptions(
          language: MonacoLanguage.markdown,
          theme: MonacoTheme.vsDark,
          fontSize: 14,
          wordWrap: true,
          automaticLayout: true,
        ),
      );
      _ownsController = true;
    }
    _waitForReady();
  }

  void _waitForReady() async {
    await _controller?.onReady;
    if (mounted) {
      setState(() {
        _isReady = true;
      });
      widget.onReady?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Monaco Editor...'),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: _controller?.webViewWidget ?? const SizedBox(),
    );
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it
    if (_ownsController && _controller != null) {
      _controller!.dispose();
    }
    super.dispose();
  }
}
