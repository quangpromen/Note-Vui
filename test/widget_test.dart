// Widget tests for Ghi Chú Việt app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:my_flutter_app/main.dart';

void main() {
  setUpAll(() async {
    // Initialize Vietnamese locale for date formatting
    await initializeDateFormatting('vi_VN', null);
  });

  testWidgets('Ghi Chú Việt app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GhiChuVietApp());
    await tester.pumpAndSettle();

    // Verify that the home screen loads with greeting
    expect(find.textContaining('Chào'), findsOneWidget);

    // Verify that search bar placeholder exists
    expect(find.text('Tìm kiếm ghi chú...'), findsOneWidget);

    // Verify that at least one note card is displayed
    expect(find.text('Đi chợ mua rau'), findsOneWidget);
  });

  testWidgets('Search filters notes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const GhiChuVietApp());
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Marketing');
    await tester.pumpAndSettle();

    // Verify that matching note is displayed
    expect(find.text('Ý tưởng Marketing'), findsOneWidget);

    // Verify that non-matching notes are hidden
    expect(find.text('Đi chợ mua rau'), findsNothing);
  });
}
