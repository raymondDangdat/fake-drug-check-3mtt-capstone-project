import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/drug_check_result.dart';
import 'screens/drug_check_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/results_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_service.dart';
import 'services/history_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const FakeDrugCheckerApp());
}

class FakeDrugCheckerApp extends StatelessWidget {
  const FakeDrugCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<HistoryService>(
          create: (_) => HistoryService(),
        ),
      ],
      child: MaterialApp(
        title: 'FakeDrugChecker — Nigeria Medication Authenticity Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const MainNavigationShell(),
          '/check': (context) => const DrugCheckScreen(),
          '/history': (context) => const MainNavigationShell(initialIndex: 1),
          '/about': (context) => const MainNavigationShell(initialIndex: 2),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/results') {
            final args = settings.arguments;
            if (args is DrugCheckResult) {
              return MaterialPageRoute(
                builder: (context) => ResultsScreen(result: args),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
