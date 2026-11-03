import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newapp/app/app.dart';
import 'package:newapp/data/repositories/cars_repository.dart';
import 'package:newapp/features/authentication/screens/admin_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home screen shows the Arabic app title and local catalog', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repository = CarsRepository(
      companies: const [],
      initialCars: const [],
    );
    await tester.pumpWidget(CarsApp(repository: repository));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('السيارات المشتركة بالمشروع'), findsOneWidget);
    expect(find.text('0 سيارة مسجلة لدى الشركات'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.table_rows_rounded));
    await tester.pumpAndSettle();
    expect(find.text('رقم السيارة'), findsOneWidget);
    expect(find.text('الحروف'), findsOneWidget);
    expect(find.text('الشركة'), findsOneWidget);
  });

  testWidgets('admin password visibility toggles correctly', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));

    final passwordField = find.byType(TextField).last;
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

    await tester.tap(find.byTooltip('إظهار كلمة المرور'));
    await tester.pump();
    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);

    await tester.tap(find.byTooltip('إخفاء كلمة المرور'));
    await tester.pump();
    expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
  });
}
