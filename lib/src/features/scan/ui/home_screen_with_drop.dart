import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_helper_utils/flutter_helper_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/consts.dart';
import '../../../shared/dialogs/name_prompt.dart';
import '../../editor/ui/widgets/prewarm_monaco.dart';
import '../../virtual_tree/ui/virtual_tree_view.dart';
import '../state/file_list_state.dart';

/// Desktop-only home with a clean hero and a horizontal action bar.
class HomeScreenWithDrop extends ConsumerStatefulWidget {
  const HomeScreenWithDrop({super.key});

  @override
  ConsumerState<HomeScreenWithDrop> createState() => _HomeScreenWithDropState();
}

class _HomeScreenWithDropState extends ConsumerState<HomeScreenWithDrop> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.read(selectionProvider.notifier);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DropTarget(
      // Only handle drops within this widget; do not catch app-wide Dock drops.
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (details) async {
        setState(() => _isDragging = false);

        final fileItems = <XFile>[];
        final textPayloads = <String>{};

        for (final item in details.files) {
          if (item.isMemoryBacked && item.isTextLike) {
            try {
              final text = await item.readAsText();
              final normalized = text?.trim();
              if (normalized != null && normalized.isNotEmpty) {
                textPayloads.add(normalized);
              }
            } catch (_) {}
            continue;
          }
          fileItems.add(item);
        }

        if (fileItems.isNotEmpty) {
          await selection.processDroppedItems(fileItems);
          // Ignore accompanying text flavors when files are present.
        } else {
          for (final text in textPayloads) {
            final name = await promptForNewFileName(
              context,
              initialName: 'pasted.txt',
            );
            if (name != null && name.trim().isNotEmpty) {
              selection.createVirtualFile(name.trim(), text);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const _HomeTitle(),
          centerTitle: true,
          actions: [
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
                      _HeroDropZone(
                        isDragging: _isDragging,
                        onTap: () => selection.pickFiles(context),
                      ),
                      const SizedBox(height: 20),

                      // HORIZONTAL ACTION BAR (consistent secondary buttons)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Prompt • New Virtual File • Paste • Paste Paths • Browse Files • Browse Folder
                          _PromptAccentButton(
                            onPressed: () =>
                                _openOrCreatePrompt(context, selection),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () =>
                                VirtualTreeView.showCreateVirtualFileFlow(
                                  context,
                                  ref,
                                ),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('New Virtual File'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _pasteClipboardAsContent(
                              context,
                              selection,
                            ),
                            icon: const Icon(Icons.content_paste_rounded),
                            label: const Text('Paste'),
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

            // Subtle drop overlay
            if (_isDragging)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: cs.primary.setOpacity(0.05),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pasteClipboardAsContent(
    BuildContext context,
    FileListNotifier selection,
  ) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Clipboard is empty.')));
      }
      return;
    }

    final name = await promptForNewFileName(context, initialName: 'pasted.txt');
    if (name == null || name.trim().isEmpty) return;
    selection.createVirtualFile(name.trim(), text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "$name" from clipboard text.')),
      );
    }
  }

  Future<void> _openOrCreatePrompt(
    BuildContext context,
    FileListNotifier selection,
  ) async {
    // Check if a Prompt virtual file already exists
    final files = ref.read(selectionProvider).fileMap;
    String? promptId;
    for (final f in files.values) {
      if (f.isVirtual && f.name == 'Prompt') {
        promptId = f.id;
        break;
      }
    }

    if (promptId != null) {
      // Open the existing Prompt file in the editor
      selection.setActiveFile(promptId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened existing "Prompt".')),
        );
      }
    } else {
      // Create an empty Prompt file and open it
      selection.createVirtualFile('Prompt', '');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Created "Prompt".')),
        );
      }
    }
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.content_paste_search_rounded, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          'Context Collector',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _HeroDropZone extends StatelessWidget {
  const _HeroDropZone({required this.isDragging, required this.onTap});

  final bool isDragging;
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
            color: isDragging ? cs.primary.setOpacity(0.05) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: isDragging ? 64 : 56,
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
                'Or click to browse. Use Paste or Paste Paths from the action bar.',
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

class _PromptAccentButton extends StatefulWidget {
  const _PromptAccentButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_PromptAccentButton> createState() => _PromptAccentButtonState();
}

class _PromptAccentButtonState extends State<_PromptAccentButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin; // 0..1
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  static const _buttonHeight = 40.0;
  static const _borderWidth = 1.25;

  @override
  void initState() {
    super.initState();
    // Linear, long period — no easing, no visible seam at 2π wrap.
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Target scales for hover/press. Keep it subtle.
    final double targetScale = _isPressed ? 0.985 : (_isHovered ? 1.03 : 1.0);

    // Background of the button (inside the animated border).
    final Color surface = cs.surface.setOpacity(
      _isPressed ? 0.92 : (_isHovered ? 0.97 : 1),
    );

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedBuilder(
          animation: _spin,
          builder: (context, child) {
            final double angle = _spin.value * 2 * math.pi;

            return Container(
              height: _buttonHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // Rotating sweep gradient; wrapping from 2π->0 is seamless.
                gradient: SweepGradient(
                  transform: GradientRotation(angle),
                  colors: <Color>[
                    cs.primary,
                    cs.tertiary,
                    cs.secondary,
                    cs.error,
                    cs.primary, // close the loop
                  ],
                  // Off-axis stops add a nicer cadence to the shimmer.
                  stops: const [0.0, 0.28, 0.55, 0.82, 1.0],
                  center: Alignment.center,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(_borderWidth),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20 - _borderWidth),
                  child: Material(
                    color: surface,
                    child: InkWell(
                      onTap: widget.onPressed,
                      onHighlightChanged: (v) => setState(() => _isPressed = v),
                      onHover: (v) => setState(() => _isHovered = v),
                      borderRadius: BorderRadius.circular(20 - _borderWidth),
                      splashColor: cs.primary.setOpacity(0.10),
                      highlightColor: Colors.transparent,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1, end: targetScale),
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: _ButtonBody(
                          isHovered: _isHovered,
                          isFocused: _isFocused,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ButtonBody extends StatelessWidget {
  const _ButtonBody({required this.isHovered, required this.isFocused});

  final bool isHovered;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      // Match OutlinedButton horizontal density.
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optional focus ring to match M3 accessibility.
          if (isFocused)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.setOpacity(0.28),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AnimatedPromptIcon(
                activeColor: cs.primary,
                subduedColor: cs.onSurfaceVariant,
                isHovered: isHovered,
              ),
              const SizedBox(width: 8),
              Text(
                'Prompt',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isHovered ? cs.primary : cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedPromptIcon extends StatelessWidget {
  const _AnimatedPromptIcon({
    required this.isHovered,
    required this.activeColor,
    required this.subduedColor,
  });

  final bool isHovered;
  final Color activeColor;
  final Color subduedColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      tween: Tween<double>(end: isHovered ? 1.0 : 0.0),
      builder: (context, t, _) {
        // t: 0..1 (hover amount). Subtle tilt + pulse.
        final double turns = 0.03 * t; // ~11° at peak
        final double scale = 1.0 + 0.08 * t;

        return Transform.rotate(
          angle: turns * 2 * math.pi,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.tips_and_updates_rounded,
              size: 18,
              color: Color.lerp(subduedColor, activeColor, 0.75 * t + 0.25),
            ),
          ),
        );
      },
    );
  }
}
