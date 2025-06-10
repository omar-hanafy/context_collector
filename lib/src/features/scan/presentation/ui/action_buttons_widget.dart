import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActionButtonsWidget extends ConsumerWidget {
  const ActionButtonsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: context.background,
        border: BorderDirectional(
          bottom: BorderSide(
            color: context.outline.addOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // File selection controls
          Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.outline.addOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_copy_rounded,
                      size: 20,
                      color: context.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Files',
                      style: context.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.primary.addOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${selectionState.selectedFilesCount} / ${selectionState.totalFilesCount}',
                        style: context.labelSmall?.copyWith(
                          color: context.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: context.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadiusDirectional.only(
                          topStart: Radius.circular(8),
                          bottomStart: Radius.circular(8),
                        ),
                        child: InkWell(
                          onTap: selectionState.totalFilesCount > 0
                              ? selectionNotifier.selectAll
                              : null,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: context.primary.addOpacity(0.04),
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 16,
                                  color: selectionState.totalFilesCount > 0
                                      ? context.primary
                                      : context.onSurface.addOpacity(0.3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'All',
                                  style: context.labelMedium?.copyWith(
                                    color: selectionState.totalFilesCount > 0
                                        ? context.primary
                                        : context.onSurface.addOpacity(0.3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: context.outline.addOpacity(0.2),
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: const BorderRadiusDirectional.only(
                          topEnd: Radius.circular(8),
                          bottomEnd: Radius.circular(8),
                        ),
                        child: InkWell(
                          onTap: selectionState.selectedFilesCount > 0
                              ? selectionNotifier.deselectAll
                              : null,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: context.onSurface.addOpacity(0.04),
                          child: Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.remove_done_rounded,
                                  size: 16,
                                  color: selectionState.selectedFilesCount > 0
                                      ? context.onSurface.addOpacity(0.6)
                                      : context.onSurface.addOpacity(0.3),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'None',
                                  style: context.labelMedium?.copyWith(
                                    color: selectionState.selectedFilesCount > 0
                                        ? context.onSurface.addOpacity(0.6)
                                        : context.onSurface.addOpacity(0.3),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator when processing files
          if (selectionState.isProcessing &&
              selectionState.processingProgress != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsetsDirectional.all(12),
              decoration: BoxDecoration(
                color: context.primary.addOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.primary.addOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectionState.processingProgress!.phase.message,
                          style: context.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        selectionState.processingProgress!.progressText,
                        style: context.labelSmall?.copyWith(
                          color: context.onSurface.addOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: selectionState.processingProgress!.progress,
                      backgroundColor: context.primary.addOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  if (selectionState.processingProgress!.currentItem !=
                      null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Processing: ${selectionState.processingProgress!.currentItem}',
                      style: context.labelSmall?.copyWith(
                        color: context.onSurface.addOpacity(0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Loading indicator for file content loading
          if (selectionState.pendingLoadCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: context.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.onSurface.addOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading content for ${selectionState.pendingLoadCount} files...',
                    style: context.labelMedium?.copyWith(
                      color: context.onSurface.addOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
