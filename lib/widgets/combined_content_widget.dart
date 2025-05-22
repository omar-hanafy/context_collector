import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../extensions/theme_extensions.dart';
import '../providers/file_collector_provider.dart';

class CombinedContentWidget extends StatefulWidget {
  const CombinedContentWidget({super.key});

  @override
  State<CombinedContentWidget> createState() => _CombinedContentWidgetState();
}

class _CombinedContentWidgetState extends State<CombinedContentWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtTop = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtTop = _scrollController.offset <= 0;
    if (_isAtTop != isAtTop) {
      setState(() => _isAtTop = isAtTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FileCollectorProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsetsDirectional.all(16),
              decoration: BoxDecoration(
                color: context.surface,
                border: BorderDirectional(
                  bottom: BorderSide(
                    color: context.onSurface.addOpacity(0.1),
                  ),
                ),
                boxShadow: _isAtTop
                    ? null
                    : [
                        BoxShadow(
                          color: context.onSurface.addOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Text(
                    'Combined Content',
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (provider.combinedContent.isNotEmpty) ...[
                    IconButton(
                      onPressed: () =>
                          _copyToClipboard(context, provider.combinedContent),
                      icon: Icon(Icons.copy,
                          color: context.onSurface.addOpacity(0.8)),
                      tooltip: 'Copy to clipboard',
                    ),
                    IconButton(
                      onPressed: _scrollToTop,
                      icon: Icon(Icons.keyboard_arrow_up,
                          color: context.onSurface.addOpacity(0.8)),
                      tooltip: 'Scroll to top',
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, FileCollectorProvider provider) {
    if (provider.combinedContent.isEmpty) {
      return _buildEmptyState(context);
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsetsDirectional.all(16),
      child: SelectableText(
        provider.combinedContent,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
          color: context.onBackground,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.preview_outlined,
            size: 64,
            color: context.onSurface.addOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Combined Content Preview',
            style: context.titleLarge?.copyWith(
              color: context.onSurface.addOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select files and load their content to see the combined result here',
            textAlign: TextAlign.center,
            style: context.bodyMedium?.copyWith(
              color: context.onSurface.addOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.primary.addOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Quick Actions:',
                  style: context.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildQuickAction(
                  context,
                  Icons.refresh,
                  'Load Content',
                  'Load content from selected files',
                ),
                _buildQuickAction(
                  context,
                  Icons.copy,
                  'Copy All',
                  'Load and copy all content to clipboard',
                ),
                _buildQuickAction(
                  context,
                  Icons.save,
                  'Save File',
                  'Load and save combined content to a file',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: context.primary.addOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: context.labelSmall?.copyWith(
                    color: context.onSurface.addOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Content copied to clipboard!'),
            ],
          ),
          backgroundColor: context.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((dynamic error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying to clipboard: $error'),
          backgroundColor: context.error,
        ),
      );
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
