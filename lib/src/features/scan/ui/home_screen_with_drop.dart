import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/persistence/saved_session.dart';
import '../../../app/persistence/session_persistence_service.dart';
import '../../../shared/consts.dart';
import '../../../shared/dialogs/name_prompt.dart';
import '../../../shared/widgets/app_bar_title.dart';
import '../../editor/ui/widgets/info_bar/copy_feedback.dart';
import '../../editor/ui/widgets/prewarm_monaco.dart';
import '../../virtual_tree/widgets/collector_tree_view.dart';
import '../state/file_list_state.dart';

/// Desktop-only home with a clean hero and a horizontal action bar.
class HomeScreenWithDrop extends ConsumerStatefulWidget {
  const HomeScreenWithDrop({super.key});

  @override
  ConsumerState<HomeScreenWithDrop> createState() => _HomeScreenWithDropState();
}

class _HomeScreenWithDropState extends ConsumerState<HomeScreenWithDrop> {
  static final DateFormat _savedWorkspaceDateFormat = DateFormat(
    'MMM d, HH:mm',
  );

  final GlobalKey _savedWorkspacesButtonKey = GlobalKey(
    debugLabel: 'saved-workspaces-button',
  );

  CopyFeedback? _pasteFeedback;
  Timer? _pasteFeedbackReset;
  bool _pasteInFlight = false;

  @override
  void dispose() {
    _pasteFeedbackReset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.read(selectionProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 44,
        leading: IconButton(
          tooltip: 'Quick info',
          icon: const Icon(Icons.info_outline_rounded, size: 20),
          onPressed: () => _showQuickInfo(context),
        ),
        title: const AppBarTitle(),
        centerTitle: true,
        actions: [
          IconButton(
            key: _savedWorkspacesButtonKey,
            tooltip: 'Saved workspaces',
            icon: const Icon(Icons.history_rounded, size: 20),
            onPressed: () => _showSavedWorkspacesMenu(context),
          ),
          IconButton(
            onPressed: () async {
              final githubUrl = Uri.parse(
                'https://github.com/omar-hanafy/context_collector',
              );
              if (!await launchUrl(githubUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open GitHub')),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              theme.brightness == Brightness.dark
                  ? AppAssets.githubLight
                  : AppAssets.githubDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'View on GitHub',
          ),
          IconButton(
            onPressed: () async {
              final coffeeUrl = Uri.parse(
                'https://www.buymeacoffee.com/omar.hanafy',
              );
              if (!await launchUrl(coffeeUrl)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open Buy Me a Coffee'),
                    ),
                  );
                }
              }
            },
            icon: SvgPicture.asset(
              theme.brightness == Brightness.dark
                  ? AppAssets.logoLight
                  : AppAssets.logoDark,
              width: 20,
              height: 20,
            ),
            tooltip: 'Buy Me a Coffee',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const Offstage(offstage: true, child: PrewarmMonaco()),
          Center(
            child: SizedBox(
              width: 960,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // HERO (clickable drop zone)
                    _HeroDropZone(onTap: selection.openPrompt),
                    const SizedBox(height: 20),

                    // HORIZONTAL ACTION BAR (consistent secondary buttons)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              CollectorTreeView.showCreateVirtualFileFlow(
                                context,
                                ref,
                              ),
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('New Virtual File'),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: switch (_pasteFeedback) {
                            CopyFeedback.success => 'Pasted clipboard content',
                            CopyFeedback.empty => 'Clipboard was empty',
                            CopyFeedback.error => 'Paste failed',
                            null =>
                              'Paste clipboard text as a new virtual file',
                          },
                          child: OutlinedButton.icon(
                            onPressed: _pasteInFlight
                                ? null
                                : () => _triggerPasteClipboard(
                                    context,
                                    selection,
                                  ),
                            icon: Icon(
                              switch (_pasteFeedback) {
                                CopyFeedback.success => Icons.check_rounded,
                                CopyFeedback.empty =>
                                  Icons.do_not_disturb_on_outlined,
                                CopyFeedback.error => Icons.error_outline,
                                null => Icons.content_paste_rounded,
                              },
                              color: switch (_pasteFeedback) {
                                CopyFeedback.success => Theme.of(
                                  context,
                                ).colorScheme.primary,
                                CopyFeedback.empty => Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                CopyFeedback.error => Theme.of(
                                  context,
                                ).colorScheme.error,
                                null => null,
                              },
                            ),
                            label: const Text('Paste'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              selection.pastePathsFromClipboard(context),
                          icon: const Icon(Icons.content_paste_go_rounded),
                          label: const Text('Paste Paths'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => selection.pickFiles(context),
                          icon: const Icon(Icons.file_open_rounded),
                          label: const Text('Browse Files'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => selection.pickDirectory(context),
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Browse Folder'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    // Tiny helper row (no scrolling junk)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drop files or directories anywhere. Use Paste or Paste Paths above.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.setOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavedWorkspacesMenu(BuildContext context) async {
    final persistence = ref.read(sessionPersistenceProvider);

    List<SavedSessionIndexItem> entries;
    try {
      entries = await persistence.list(includeActive: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workspaces: $error')),
      );
      return;
    }

    if (!mounted) return;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved workspaces yet.')),
      );
      return;
    }

    final buttonContext = _savedWorkspacesButtonKey.currentContext;
    final overlay = Overlay.of(context);
    if (buttonContext == null) return;
    final buttonBox = buttonContext.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null || !buttonBox.hasSize) {
      return;
    }
    final offset = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final buttonRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      buttonBox.size.width,
      buttonBox.size.height,
    );
    final menuPosition = RelativeRect.fromRect(
      buttonRect,
      Offset.zero & overlayBox.size,
    );

    final selection = await showMenu<SavedSessionIndexItem>(
      context: context,
      position: menuPosition,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        for (final item in entries)
          PopupMenuItem<SavedSessionIndexItem>(
            value: item,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${item.fileCount} items — '
                '${_savedWorkspaceDateFormat.format(item.savedAt.toLocal())}',
              ),
            ),
          ),
      ],
    );

    if (selection == null || !mounted) {
      return;
    }

    SavedSession? snapshot;
    try {
      snapshot = await persistence.load(selection.sessionId);
    } catch (error) {
      await persistence.delete(selection.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to read workspace: $error')),
        );
      }
      return;
    }
    if (snapshot == null) {
      await persistence.delete(selection.sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workspace file missing.')),
        );
      }
      return;
    }

    try {
      await persistence.restoreIntoNewSession(ref, snapshot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored "${snapshot.title}"')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $error')),
      );
    }
  }

  Future<void> _triggerPasteClipboard(
    BuildContext context,
    FileListNotifier selection,
  ) async {
    _pasteFeedbackReset?.cancel();
    setState(() {
      _pasteInFlight = true;
      _pasteFeedback = null;
    });

    CopyFeedback? result;
    try {
      result = await _pasteClipboardAsContent(context, selection);
    } catch (error, stack) {
      debugPrint('[HomeScreen] Paste clipboard failed: $error');
      debugPrintStack(stackTrace: stack);
      result = CopyFeedback.error;
    }

    if (!mounted) return;

    setState(() {
      _pasteInFlight = false;
      _pasteFeedback = result;
    });

    if (result != null) {
      _pasteFeedbackReset = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _pasteFeedback = null);
      });
    }
  }

  Future<CopyFeedback?> _pasteClipboardAsContent(
    BuildContext context,
    FileListNotifier selection,
  ) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) {
      return CopyFeedback.empty;
    }

    final name = await promptForNewFileName(context, initialName: 'pasted.txt');
    if (name == null || name.trim().isEmpty) return null;
    selection.createVirtualFile(name.trim(), text);
    return CopyFeedback.success;
  }

  // Prompt action removed — Prompt file is auto-created when a session starts.

  void _showQuickInfo(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item(IconData icon, String title, String desc) => ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: cs.primary),
      title: Text(title, style: theme.textTheme.labelLarge),
      subtitle: Text(desc, style: theme.textTheme.bodySmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Context Collector — Quick Guide'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Context Collector is a safe, temporary workspace. It never edits your files on disk. '
                'Use it to gather and prepare content for AI prompts — also handy for bug reports, docs, and sharing snippets.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 8),
              item(
                Icons.tips_and_updates_rounded,
                'Prompt',
                'Write instructions for the AI. Exported verbatim at the very top. Not included in the Context section.',
              ),
              item(
                Icons.add_circle_outline_rounded,
                'New Virtual File',
                'Create a blank file in this workspace. Edits stay here and do not change files on disk.',
              ),
              item(
                Icons.content_paste_rounded,
                'Paste',
                'Paste clipboard text as a new virtual file.',
              ),
              item(
                Icons.content_paste_go_rounded,
                'Paste Paths',
                'Paste file/folder paths. We scan and load them into the workspace.',
              ),
              item(
                Icons.file_open_rounded,
                'Browse Files',
                'Pick one or more files to include.',
              ),
              item(
                Icons.folder_open_rounded,
                'Browse Folder',
                'Pick a directory; files are discovered recursively.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// _HomeTitle removed; using shared AppBarTitle instead

class _HeroDropZone extends StatelessWidget {
  const _HeroDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                size: 56,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Drop your files or directories here',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Click to start with a Prompt, or use Browse/Paste above.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.setOpacity(0.70),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
