import 'package:flutter_test/flutter_test.dart';
import 'package:gcet_tracker/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const GCETTrackerApp());
    expect(find.text('GCET'), findsOneWidget);
  });
}
