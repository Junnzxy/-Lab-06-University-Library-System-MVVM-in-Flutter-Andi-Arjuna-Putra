import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/viewmodels/library_view_model.dart';

void main() {
  testWidgets('University Library App UI and MVVM interaction test', (WidgetTester tester) async {
    final viewModel = LibraryViewModel(seedDefaultData: true);

    await tester.pumpWidget(UniversityLibraryApp(viewModel: viewModel));
    await tester.pumpAndSettle();

    expect(find.text('University Library'), findsOneWidget);
    expect(find.text('Tipografi dalam Desain Komunikasi Visual'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    expect(find.text('Catalogue'), findsOneWidget);
    expect(find.text('Active Loans'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Fines & Summary'), findsOneWidget);

    await tester.tap(find.text('Active Loans'));
    await tester.pumpAndSettle();

    expect(find.text('DKV-2024-001'), findsOneWidget);

    await tester.tap(find.text('Fines & Summary'));
    await tester.pumpAndSettle();

    expect(find.text('University Fine Policy Schedule'), findsOneWidget);
    expect(find.text('TOTAL OUTSTANDING FINES'), findsOneWidget);
  });
}
