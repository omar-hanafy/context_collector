import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart' as ww;

/// Minimal Windows WebView2 test to debug communication issues
class WindowsWebViewTest extends StatefulWidget {
  const WindowsWebViewTest({super.key});

  @override
  State<WindowsWebViewTest> createState() => _WindowsWebViewTestState();
}

class _WindowsWebViewTestState extends State<WindowsWebViewTest> {
  late ww.WebviewController _controller;
  final List<String> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _log(String message) {
    debugPrint('[WindowsWebViewTest] $message');
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
  }

  Future<void> _initWebView() async {
    try {
      _log('Creating WebviewController...');
      _controller = ww.WebviewController();

      _log('Initializing WebView2...');
      await _controller.initialize();

      _log('Setting up message listener...');
      _controller.webMessage.listen((dynamic message) {
        _log('Received message: $message (${message.runtimeType})');
      });

      _log('Loading test HTML...');
      await _loadTestHtml();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _log('Error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTestHtml() async {
    const html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Minimal Test</title>
    <style>
        body { 
            background: #222; 
            color: #fff; 
            font-family: monospace; 
            padding: 20px;
        }
        button {
            background: #4CAF50;
            color: white;
            border: none;
            padding: 10px 20px;
            margin: 5px;
            cursor: pointer;
        }
        button:hover {
            background: #45a049;
        }
        #output {
            background: #333;
            padding: 10px;
            margin: 10px 0;
            border: 1px solid #555;
            min-height: 100px;
        }
    </style>
</head>
<body>
    <h1>WebView2 Communication Test</h1>
    
    <div>
        <button onclick="testDirect()">Test Direct postMessage</button>
        <button onclick="testWrapped()">Test Wrapped postMessage</button>
        <button onclick="testChannel()">Test Flutter Channel</button>
    </div>
    
    <div id="output"></div>
    
    <script>
        const output = document.getElementById('output');
        
        function log(msg) {
            console.log(msg);
            output.innerHTML += msg + '<br>';
        }
        
        log('Page loaded');
        
        // Check WebView2 API
        if (window.chrome && window.chrome.webview) {
            log('✓ WebView2 API is available');
        } else {
            log('✗ WebView2 API NOT available');
        }
        
        // Test 1: Direct postMessage
        function testDirect() {
            try {
                const msg = 'Direct message at ' + new Date().toISOString();
                window.chrome.webview.postMessage(msg);
                log('Sent direct: ' + msg);
            } catch (e) {
                log('Error direct: ' + e.message);
            }
        }
        
        // Test 2: Wrapped JSON
        function testWrapped() {
            try {
                const data = {
                    event: 'test',
                    timestamp: Date.now(),
                    message: 'Wrapped message'
                };
                window.chrome.webview.postMessage(JSON.stringify(data));
                log('Sent wrapped: ' + JSON.stringify(data));
            } catch (e) {
                log('Error wrapped: ' + e.message);
            }
        }
        
        // Test 3: Flutter channel (if it exists)
        function testChannel() {
            if (window.flutterChannel && window.flutterChannel.postMessage) {
                try {
                    const data = {
                        event: 'onEditorReady',
                        detail: 'Test ready'
                    };
                    window.flutterChannel.postMessage(JSON.stringify(data));
                    log('Sent via channel: ' + JSON.stringify(data));
                } catch (e) {
                    log('Error channel: ' + e.message);
                }
            } else {
                log('Flutter channel not found');
                
                // Try to create it manually
                log('Creating channel manually...');
                window.flutterChannel = {
                    postMessage: function(msg) {
                        window.chrome.webview.postMessage(msg);
                    }
                };
                
                // Retry
                testChannel();
            }
        }
        
        // Auto-test after load
        setTimeout(() => {
            log('=== Running auto-tests ===');
            testDirect();
            setTimeout(testWrapped, 100);
            setTimeout(testChannel, 200);
        }, 500);
    </script>
</body>
</html>
''';

    await _controller.loadStringContent(html);
  }

  Future<void> _testJavaScript() async {
    try {
      _log('Testing JavaScript execution...');
      await _controller.executeScript('console.log("Hello from Dart!")');
      _log('JavaScript executed successfully');
    } catch (e) {
      _log('JavaScript error: $e');
    }
  }

  Future<void> _addFlutterChannel() async {
    try {
      _log('Adding flutterChannel...');
      await _controller.executeScript('''
        window.flutterChannel = {
          postMessage: function(msg) {
            console.log('[flutterChannel] Posting:', msg);
            window.chrome.webview.postMessage(msg);
          }
        };
        console.log('flutterChannel added');
      ''');
      _log('flutterChannel added successfully');
    } catch (e) {
      _log('Error adding channel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Windows WebView2 Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logs.clear();
                _isLoading = true;
                _error = null;
              });
              _initWebView();
            },
          ),
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: _testJavaScript,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle),
            onPressed: _addFlutterChannel,
          ),
          IconButton(
            icon: const Icon(Icons.developer_mode),
            onPressed: () async {
              try {
                await _controller.openDevTools();
              } catch (e) {
                _log('Error opening DevTools: $e');
              }
            },
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initWebView();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_isLoading)
                  const LinearProgressIndicator()
                else
                  Expanded(
                    flex: 2,
                    child: ww.Webview(_controller),
                  ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.black87,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const Text(
                                'Console Output',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white),
                                onPressed: () => setState(() => _logs.clear()),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              return Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
