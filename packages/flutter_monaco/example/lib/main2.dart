import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Monaco Quick Start',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monaco Editor - Quick Start'),
        ),
        body: const MonacoEditorView(),
      ),
    ),
  );
}
