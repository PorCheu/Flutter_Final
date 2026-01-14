// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:habit_alert/main.dart';
import 'package:habit_alert/data/datasources/local_data_source.dart';
import 'package:habit_alert/data/repositories/alert_repository.dart';

void main() {
  testWidgets('App shows title', (WidgetTester tester) async {
    // Create a test repository
    final alertRepository = AlertRepository(LocalDataSource());
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(HabitAlertApp(alertRepository: alertRepository));

    // Verify that the title is present on the home screen.
    expect(find.text('Habit Alert'), findsWidgets);
  });
}
