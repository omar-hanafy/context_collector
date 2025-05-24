import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'providers/file_collector_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  print('Nice but u removed the dropdown selector for language and themes, also removed the enable edit lets return them in more beatufil UI.');
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(600, 400),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Context Collector',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ContextCollectorApp());
}

class ContextCollectorApp extends StatelessWidget {
  const ContextCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('HELLO CLAUDE: NOT THAT THE HIGHLIGHTS ITS STILL NOT SHOWED IN THE EDITOR .. ITS NOT ABOUT LANGUAGE SELECTION, ITS ABOUT THE EDITOR IT SELF NOT LOADING THE HIGHLIGHTS');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => FileCollectorProvider()),
      ],
      child: MaterialApp(
        title: 'Context Collector',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
