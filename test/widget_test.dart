// Widget tests for Ghi Chú Việt app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:my_flutter_app/features/notes/domain/note_service.dart';
import 'package:my_flutter_app/main.dart';

void main() {
  late NoteService noteService;

  setUpAll(() async {
    // Initialize Vietnamese locale for date formatting
    await initializeDateFormatting('vi_VN', null);
  });

  setUp(() async {
    // Create a fresh NoteService for each test
    noteService = NoteService();
    await noteService.initialize();
  });

  testWidgets('Ghi Chú Việt app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(GhiChuVietApp(noteService: noteService));
    await tester.pumpAndSettle();

    // Verify that the home screen loads with greeting
    expect(find.textContaining('Chào'), findsOneWidget);

    // Verify that search bar placeholder exists
    expect(find.text('Tìm kiếm ghi chú...'), findsOneWidget);
  });

  testWidgets('Empty state is shown when no notes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(GhiChuVietApp(noteService: noteService));
    await tester.pumpAndSettle();

    // Verify that empty state message is displayed
    expect(find.textContaining('Chưa có ghi chú nào'), findsOneWidget);
  });
}
