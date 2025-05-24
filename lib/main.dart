import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'src/features/scan/presentation/state/selection_cubit.dart';
import 'src/features/scan/presentation/ui/home_screen.dart';
import 'src/features/settings/presentation/state/preferences_cubit.dart';
import 'src/shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for desktop
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1000, 700),
    minimumSize: Size(1400, 400),
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => PreferencesCubit()),
        ChangeNotifierProvider(create: (context) => SelectionCubit()),
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
