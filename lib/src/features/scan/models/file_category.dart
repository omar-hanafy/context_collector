import 'package:flutter/material.dart';

/// Minimal FileCategory enum to support settings
/// In the simplified scan feature, we don't actually filter by extensions
enum FileCategory {
  programming('Programming Languages', Icons.code),
  web('Web Technologies', Icons.web),
  data('Data & Config', Icons.data_object),
  script('Scripts', Icons.terminal),
  documentation('Documentation', Icons.description),
  database('Database', Icons.storage),
  devops('DevOps & Build', Icons.build_circle),
  other('Other', Icons.insert_drive_file);

  const FileCategory(this.displayName, this.icon);

  final String displayName;
  final IconData icon;
}

