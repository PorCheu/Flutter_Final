import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_alert_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';
import 'data/datasources/local_data_source.dart';
import 'data/repositories/alert_repository.dart';
import 'data/services/data_initialization_service.dart';

// Entry point for the app. Initializes notifications and sets up routes.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service early
  await NotificationService.init();

  // Initialize data layer with demo data on first run
  final localDataSource = LocalDataSource();
  final dataInitService = DataInitializationService(localDataSource);
  await dataInitService.initialize();

  // Create repositories for dependency injection
  final alertRepository = AlertRepository(localDataSource);

  // Lock orientation to portrait for simplicity (optional)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(HabitAlertApp(alertRepository: alertRepository));
}

class HabitAlertApp extends StatelessWidget {
  final AlertRepository alertRepository;

  const HabitAlertApp({super.key, required this.alertRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Alert',
      debugShowCheckedModeBanner: false,
      // Use a clean light theme for clearer UI and consistent Material widgets
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
        ).copyWith(secondary: Colors.tealAccent),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      // Start on Welcome screen, then navigate: Welcome -> Home -> Add/Calendar
      initialRoute: '/welcome',
      routes: {
        '/welcome': (c) => const WelcomeScreen(),
        '/home': (c) => HomeScreen(alertRepository: alertRepository),
        '/add': (c) => AddAlertScreen(alertRepository: alertRepository),
        '/calendar': (c) => CalendarScreen(alertRepository: alertRepository),
      },
    );
  }
}
