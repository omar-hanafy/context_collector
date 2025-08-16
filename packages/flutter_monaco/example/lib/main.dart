import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Monaco',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Monaco Editor'),
        ),
        body: const MonacoEditor(
          showStatusBar: true,
        ),
      ),
    ),
  );
}
