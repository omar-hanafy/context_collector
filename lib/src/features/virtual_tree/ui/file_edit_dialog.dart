import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';

import '../../scan/ui/file_display_helper.dart';

/// Dialog for editing file content
class FileEditDialog extends StatefulWidget {
  const FileEditDialog({
    required this.fileName,
    this.initialContent = '',
    super.key,
  });

  final String fileName;
  final String initialContent;

  @override
  State<FileEditDialog> createState() => _FileEditDialogState();
}

class _FileEditDialogState extends State<FileEditDialog> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isSaving = false;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
    _focusNode = FocusNode();
    _updateLineCount();
    _controller.addListener(_updateLineCount);

    // Auto-focus the editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateLineCount() {
    final lines = _controller.text.split('\n').length;
    if (lines != _lineCount) {
      setState(() {
        _lineCount = lines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extension = widget.fileName.split('.').lastOrNull ?? '';
    final language = FileDisplayHelper.getLanguageId(extension);

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.addOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FileDisplayHelper.getIconForExtension(extension),
                    size: 20,
                    color: FileDisplayHelper.getIconColor(extension, context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (language.isNotEmpty)
                          Text(
                            language[0].toUpperCase() + language.substring(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.addOpacity(
                                0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$_lineCount lines',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.addOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Editor
            Expanded(
              child: Container(
                color: theme.colorScheme.surface.darken(0.02),
                child: Row(
                  children: [
                    // Line numbers
                    Container(
                      width: 50,
                      padding: const EdgeInsets.only(right: 8, top: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.darken(0.04),
                        border: Border(
                          right: BorderSide(
                            color: theme.dividerColor.addOpacity(0.3),
                          ),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _lineCount,
                        itemBuilder: (context, index) => Container(
                          height: 24,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.addOpacity(
                                0.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Text field
                    Expanded(
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) {
                          // Handle Tab key
                          if (event is RawKeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.tab) {
                            final cursorPos = _controller.selection.start;
                            final text = _controller.text;
                            final newText =
                                text.substring(0, cursorPos) +
                                '  ' + // 2 spaces for tab
                                text.substring(cursorPos);
                            _controller.value = TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(
                                offset: cursorPos + 2,
                              ),
                            );
                          }
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.7,
                          ),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Enter file content...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.addOpacity(
                                0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.addOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isSaving
                        ? null
                        : () {
                            setState(() {
                              _isSaving = true;
                            });
                            Navigator.of(context).pop(_controller.text);
                          },
                    icon: _isSaving
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the file edit dialog and returns the edited content
Future<String?> showFileEditDialog(
  BuildContext context, {
  required String fileName,
  String initialContent = '',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => FileEditDialog(
      fileName: fileName,
      initialContent: initialContent,
    ),
  );
}
