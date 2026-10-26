import 'package:flutter/material.dart';

import 'main_shell.dart';
import 'settings/app_settings.dart';
import 'tabs/home_tab.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appSettings.load(); // loads the saved settings before the app appears
  runApp(const CreekTogether());
}

/// Colors and styles live in theme/app_theme.dart.
class CreekTogether extends StatelessWidget {
  const CreekTogether({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app whenever a setting changes
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'CreekTogether', // the app's name 
          debugShowCheckedModeBanner: false,
          theme: buildTheme(appSettings),
          // Applies the text size setting in the app
          builder: (context, child) {
            final phoneScale = MediaQuery.textScalerOf(context).scale(1.0);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(phoneScale * appSettings.textScale),
              ),
              child: child!,
            );
          },
          home: const MainShell(type: GridListDemoType.footer),
        );
      },
    );
  }
}
