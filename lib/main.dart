import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/add_alert_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/notification_service.dart';

// Entry point for the app. Initializes notifications and sets up routes.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service early
  await NotificationService.init();

  // Lock orientation to portrait for simplicity (optional)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const HabitAlertApp());
}

class HabitAlertApp extends StatelessWidget {
  const HabitAlertApp({Key? key}) : super(key: key);

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
      // Start directly on Home screen (no welcome page on boot)
      initialRoute: '/home',
      routes: {
        '/home': (c) => const HomeScreen(),
        '/add': (c) => const AddAlertScreen(),
        '/calendar': (c) => const CalendarScreen(),
      },
    );
  }
}
