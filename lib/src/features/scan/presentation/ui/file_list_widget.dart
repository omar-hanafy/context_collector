import 'package:context_collector/context_collector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FileListWidget extends StatelessWidget {
  const FileListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SelectionCubit, PreferencesCubit>(
      builder: (context, selectionCubit, preferencesCubit, child) {
        if (selectionCubit.allFiles.isEmpty) {
          return const Center(
            child: Text('No files added yet'),
          );
        }

        return ListView.builder(
          itemCount: selectionCubit.allFiles.length,
          itemBuilder: (context, index) {
            final file = selectionCubit.allFiles[index];
            return _FileListItem(
              file: file,
              isSelected: selectionCubit.isFileSelected(file),
              activeExtensions: preferencesCubit.activeExtensions,
              onToggle: () => selectionCubit.toggleFileSelection(file),
              onRemove: () => selectionCubit.removeFile(file),
            );
          },
        );
      },
    );
  }
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({
    required this.file,
    required this.isSelected,
    required this.activeExtensions,
    required this.onToggle,
    required this.onRemove,
  });

  final ScannedFile file;
  final bool isSelected;
  final Map<String, FileCategory> activeExtensions;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsetsDirectional.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected ? context.primary.addOpacity(0.05) : context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? context.primary.addOpacity(0.3)
              : context.outline.addOpacity(0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(16),
            child: Row(
              children: [
                _buildLeading(context),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildContent(context),
                ),
                const SizedBox(width: 12),
                _buildTrailing(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? context.primary : context.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? context.primary
                  : context.outline.addOpacity(0.5),
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        _buildFileIcon(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          file.name,
          style: context.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          file.fullPath,
          style: context.bodySmall?.copyWith(
            color: context.onSurface.addOpacity(0.5),
            fontFamily: 'monospace',
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusChip(context),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: context.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  file.sizeFormatted,
                  style: context.labelSmall?.copyWith(
                    fontSize: 11,
                    color: context.onSurface.addOpacity(0.6),
                  ),
                ),
              ),
              if (file.getCategory(activeExtensions) != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: context.primary.addOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    file.extension,
                    style: context.labelSmall?.copyWith(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: context.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (file.error != null)
          IconButton(
            icon: Icon(
              Icons.error_outline_rounded,
              color: context.error,
            ),
            onPressed: () => _showErrorDialog(context),
            tooltip: 'Show error',
            style: IconButton.styleFrom(
              backgroundColor: context.error.addOpacity(0.1),
            ),
          )
        else if (file.content != null)
          Container(
            padding: const EdgeInsetsDirectional.all(6),
            decoration: BoxDecoration(
              color: context.primary.addOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_rounded,
              color: context.primary,
              size: 20,
            ),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onRemove,
          tooltip: 'Remove file',
          style: IconButton.styleFrom(
            foregroundColor: context.error,
            backgroundColor: context.error.addOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildFileIcon(BuildContext context) {
    final category = file.getCategory(activeExtensions);
    final isSupported = file.supportsText(activeExtensions);

    if (!isSupported || category == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.insert_drive_file_outlined,
          color: context.onSurface.addOpacity(0.5),
          size: 20,
        ),
      );
    }

    // Default values from category
    IconData iconData = category.icon;
    Color iconColor = context.primary;
    Color bgColor = context.primary.addOpacity(0.1);

    // Enhanced file type detection with proper branding
    final extension = file.extension.toLowerCase();
    final fileName = file.name.toLowerCase();

    // Special filename cases first
    if (_getSpecialFilenameIcon(fileName) case final result?) {
      iconData = result.icon;
      iconColor = result.color;
      bgColor = result.backgroundColor ?? result.color.addOpacity(0.1);
    } else {
      // Extension-based detection
      switch (extension) {
        // Dart & Flutter (your favorite!)
        case '.dart':
          iconData = Icons.flutter_dash;
          iconColor = const Color(0xFF0175C2);
          bgColor = iconColor.addOpacity(0.1);
        case '.g.dart':
        case '.freezed.dart':
        case '.chopper.dart':
          iconData = Icons.auto_fix_high_rounded;
          iconColor = const Color(0xFF0175C2);
          bgColor = iconColor.addOpacity(0.1);

        // Scripting Languages (your other favorites!)
        case '.py':
        case '.pyw':
        case '.pyx':
        case '.pyi':
          iconData = Icons.psychology_rounded;
          iconColor = const Color(0xFF3776AB);
          bgColor = iconColor.addOpacity(0.1);
        case '.sh':
        case '.bash':
        case '.zsh':
        case '.fish':
          iconData = Icons.terminal_rounded;
          iconColor = const Color(0xFF4EAA25);
          bgColor = iconColor.addOpacity(0.1);
        case '.ps1':
        case '.psm1':
        case '.psd1':
          iconData = Icons.terminal_rounded;
          iconColor = const Color(0xFF012456);
          bgColor = iconColor.addOpacity(0.1);

        // JavaScript Ecosystem
        case '.js':
        case '.mjs':
        case '.cjs':
          iconData = Icons.javascript_rounded;
          iconColor = const Color(0xFFF7DF1E);
          bgColor = const Color(0xFF323330);
        case '.ts':
        case '.tsx':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF3178C6);
          bgColor = iconColor.addOpacity(0.1);

        // Web Technologies
        case '.html':
        case '.htm':
        case '.xhtml':
          iconData = Icons.html_rounded;
          iconColor = const Color(0xFFE34F26);
          bgColor = iconColor.addOpacity(0.1);
        case '.css':
          iconData = Icons.css_rounded;
          iconColor = const Color(0xFF1572B6);
          bgColor = iconColor.addOpacity(0.1);
        case '.scss':
        case '.sass':
          iconData = Icons.css_rounded;
          iconColor = const Color(0xFFCF649A);
          bgColor = iconColor.addOpacity(0.1);
        case '.less':
          iconData = Icons.css_rounded;
          iconColor = const Color(0xFF1D365D);
          bgColor = iconColor.addOpacity(0.1);
        case '.vue':
          iconData = Icons.web_rounded;
          iconColor = const Color(0xFF4FC08D);
          bgColor = iconColor.addOpacity(0.1);
        case '.svelte':
          iconData = Icons.web_rounded;
          iconColor = const Color(0xFFFF3E00);
          bgColor = iconColor.addOpacity(0.1);

        // Systems Programming
        case '.c':
        case '.h':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF00599C);
          bgColor = iconColor.addOpacity(0.1);
        case '.cpp':
        case '.cc':
        case '.cxx':
        case '.hpp':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF00599C);
          bgColor = iconColor.addOpacity(0.1);
        case '.rs':
          iconData = Icons.settings_rounded;
          iconColor = const Color(0xFFCE422B);
          bgColor = iconColor.addOpacity(0.1);
        case '.go':
          iconData = Icons.speed_rounded;
          iconColor = const Color(0xFF00ADD8);
          bgColor = iconColor.addOpacity(0.1);
        case '.swift':
          iconData = Icons.speed_rounded;
          iconColor = const Color(0xFFFA7343);
          bgColor = iconColor.addOpacity(0.1);

        // JVM Languages
        case '.java':
          iconData = Icons.coffee_rounded;
          iconColor = const Color(0xFFED8B00);
          bgColor = iconColor.addOpacity(0.1);
        case '.kt':
        case '.kts':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF7F52FF);
          bgColor = iconColor.addOpacity(0.1);
        case '.scala':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFFDC322F);
          bgColor = iconColor.addOpacity(0.1);
        case '.groovy':
        case '.gradle':
          iconData = Icons.build_rounded;
          iconColor = const Color(0xFF4298B8);
          bgColor = iconColor.addOpacity(0.1);

        // Other Scripting & Dynamic Languages
        case '.rb':
        case '.erb':
        case '.gemspec':
          iconData = Icons.diamond_rounded;
          iconColor = const Color(0xFFCC342D);
          bgColor = iconColor.addOpacity(0.1);
        case '.php':
        case '.phtml':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF777BB4);
          bgColor = iconColor.addOpacity(0.1);
        case '.pl':
        case '.pm':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF39457E);
          bgColor = iconColor.addOpacity(0.1);
        case '.lua':
          iconData = Icons.nights_stay_rounded;
          iconColor = const Color(0xFF000080);
          bgColor = iconColor.addOpacity(0.1);

        // Data & Configuration
        case '.json':
        case '.jsonl':
        case '.json5':
          iconData = Icons.data_object_rounded;
          iconColor = const Color(0xFF000000);
          bgColor = const Color(0xFFF5F5F5);
        case '.yaml':
        case '.yml':
          iconData = Icons.settings_rounded;
          iconColor = const Color(0xFFCB171E);
          bgColor = iconColor.addOpacity(0.1);
        case '.xml':
        case '.xsl':
        case '.xslt':
          iconData = Icons.code_rounded;
          iconColor = const Color(0xFF0060AC);
          bgColor = iconColor.addOpacity(0.1);
        case '.toml':
          iconData = Icons.settings_rounded;
          iconColor = const Color(0xFF9C4221);
          bgColor = iconColor.addOpacity(0.1);
        case '.ini':
        case '.cfg':
        case '.conf':
          iconData = Icons.tune_rounded;
          iconColor = context.onSurface.addOpacity(0.7);
          bgColor = context.surfaceContainerHighest;
        case '.env':
        case '.dotenv':
          iconData = Icons.lock_rounded;
          iconColor = const Color(0xFFECD53F);
          bgColor = iconColor.addOpacity(0.1);

        // Documentation
        case '.md':
        case '.markdown':
          iconData = Icons.article_rounded;
          iconColor = const Color(0xFF083FA1);
          bgColor = iconColor.addOpacity(0.1);
        case '.rst':
          iconData = Icons.article_rounded;
          iconColor = const Color(0xFF3776AB);
          bgColor = iconColor.addOpacity(0.1);
        case '.tex':
        case '.latex':
          iconData = Icons.article_rounded;
          iconColor = const Color(0xFF008080);
          bgColor = iconColor.addOpacity(0.1);

        // Database
        case '.sql':
        case '.mysql':
        case '.pgsql':
          iconData = Icons.storage_rounded;
          iconColor = const Color(0xFF336791);
          bgColor = iconColor.addOpacity(0.1);

        // Container & DevOps
        case '.dockerfile':
          iconData = Icons.directions_boat_rounded;
          iconColor = const Color(0xFF2496ED);
          bgColor = iconColor.addOpacity(0.1);
        case '.tf':
        case '.tfvars':
          iconData = Icons.cloud_rounded;
          iconColor = const Color(0xFF623CE4);
          bgColor = iconColor.addOpacity(0.1);

        // Build & Package Management
        case '.make':
        case '.makefile':
          iconData = Icons.build_rounded;
          iconColor = const Color(0xFF427819);
          bgColor = iconColor.addOpacity(0.1);
        case '.cmake':
          iconData = Icons.build_rounded;
          iconColor = const Color(0xFF064F8C);
          bgColor = iconColor.addOpacity(0.1);

        // Mobile Development
        case '.m':
        case '.mm':
          iconData = Icons.phone_iphone_rounded;
          iconColor = const Color(0xFF000000);
          bgColor = iconColor.addOpacity(0.1);

        // Functional Languages
        case '.hs':
        case '.lhs':
          iconData = Icons.functions_rounded;
          iconColor = const Color(0xFF5D4F85);
          bgColor = iconColor.addOpacity(0.1);
        case '.clj':
        case '.cljs':
          iconData = Icons.functions_rounded;
          iconColor = const Color(0xFF5881D8);
          bgColor = iconColor.addOpacity(0.1);
        case '.ex':
        case '.exs':
          iconData = Icons.bolt_rounded;
          iconColor = const Color(0xFF4B275F);
          bgColor = iconColor.addOpacity(0.1);
        case '.erl':
          iconData = Icons.memory_rounded;
          iconColor = const Color(0xFFA90533);
          bgColor = iconColor.addOpacity(0.1);

        // Game Development & Graphics
        case '.cs':
          iconData = Icons.videogame_asset_rounded;
          iconColor = const Color(0xFF239120);
          bgColor = iconColor.addOpacity(0.1);
        case '.glsl':
        case '.vert':
        case '.frag':
          iconData = Icons.gradient_rounded;
          iconColor = const Color(0xFF5586A4);
          bgColor = iconColor.addOpacity(0.1);

        // Productivity Tools Extensions (since you love productive tools!)
        case '.applescript':
        case '.scpt':
          iconData = Icons.apple_rounded;
          iconColor = const Color(0xFF000000);
          bgColor = iconColor.addOpacity(0.1);
        case '.awk':
          iconData = Icons.text_snippet_rounded;
          iconColor = const Color(0xFF4EAA25);
          bgColor = iconColor.addOpacity(0.1);
        case '.sed':
          iconData = Icons.find_replace_rounded;
          iconColor = const Color(0xFF4EAA25);
          bgColor = iconColor.addOpacity(0.1);
        case '.jq':
          iconData = Icons.filter_list_rounded;
          iconColor = const Color(0xFF000000);
          bgColor = iconColor.addOpacity(0.1);

        // Default case - use category defaults
        default:
          // Keep the defaults from category
          break;
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: iconColor.addOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 22,
      ),
    );
  }

// Helper method for special filename detection
  ({IconData icon, Color color, Color? backgroundColor})?
      _getSpecialFilenameIcon(String fileName) {
    return switch (fileName) {
      // Dart/Flutter specific
      'pubspec.yaml' || 'pubspec.yml' => (
          icon: Icons.flutter_dash,
          color: const Color(0xFF0175C2),
          backgroundColor: null,
        ),
      'analysis_options.yaml' => (
          icon: Icons.analytics_rounded,
          color: const Color(0xFF0175C2),
          backgroundColor: null,
        ),

      // Build files
      'dockerfile' => (
          icon: Icons.directions_boat_rounded,
          color: const Color(0xFF2496ED),
          backgroundColor: null,
        ),
      'makefile' || 'gnumakefile' => (
          icon: Icons.build_rounded,
          color: const Color(0xFF427819),
          backgroundColor: null,
        ),
      'cmakelists.txt' => (
          icon: Icons.build_rounded,
          color: const Color(0xFF064F8C),
          backgroundColor: null,
        ),

      // Package management
      'package.json' => (
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFFCB3837),
          backgroundColor: null,
        ),
      'package-lock.json' => (
          icon: Icons.lock_rounded,
          color: const Color(0xFFCB3837),
          backgroundColor: null,
        ),
      'cargo.toml' => (
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFFCE422B),
          backgroundColor: null,
        ),
      'go.mod' => (
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF00ADD8),
          backgroundColor: null,
        ),
      'requirements.txt' => (
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF3776AB),
          backgroundColor: null,
        ),
      'pipfile' => (
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF3776AB),
          backgroundColor: null,
        ),

      // Configuration files
      '.gitignore' => (
          icon: Icons.visibility_off_rounded,
          color: const Color(0xFFF05032),
          backgroundColor: null,
        ),
      '.gitattributes' => (
          icon: Icons.settings_rounded,
          color: const Color(0xFFF05032),
          backgroundColor: null,
        ),
      '.editorconfig' => (
          icon: Icons.edit_rounded,
          color: const Color(0xFF000000),
          backgroundColor: null,
        ),
      '.eslintrc' || '.eslintrc.json' => (
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF4B32C3),
          backgroundColor: null,
        ),
      '.prettierrc' || '.prettierrc.json' => (
          icon: Icons.auto_fix_high_rounded,
          color: const Color(0xFFF7B93E),
          backgroundColor: null,
        ),

      // CI/CD
      '.travis.yml' => (
          icon: Icons.build_circle_rounded,
          color: const Color(0xFF3EAAAF),
          backgroundColor: null,
        ),
      'docker-compose.yml' || 'docker-compose.yaml' => (
          icon: Icons.view_module_rounded,
          color: const Color(0xFF2496ED),
          backgroundColor: null,
        ),
      _ => null,
    };
  }

  Widget _buildStatusChip(BuildContext context) {
    if (file.error != null) {
      return Chip(
        label: const Text('Error'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.error,
        ),
        backgroundColor: context.error.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    if (file.content != null) {
      return Chip(
        label: const Text('Loaded'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.primary,
        ),
        backgroundColor: context.primary.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    if (!file.supportsText(activeExtensions)) {
      return Chip(
        label: const Text('Not Supported'),
        labelStyle: context.labelSmall?.copyWith(
          color: context.onSurface.addOpacity(0.6),
        ),
        backgroundColor: context.onSurface.addOpacity(0.1),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
    }

    return Chip(
      label: const Text('Ready'),
      labelStyle: context.labelSmall,
      backgroundColor: context.surface,
      side: BorderSide(
        color: context.onSurface.addOpacity(0.2),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _showErrorDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: context.error),
            const SizedBox(width: 8),
            const Text('File Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File: ${file.name}',
              style: context.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${file.error}',
              style: context.bodyMedium,
            ),
          ],
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
