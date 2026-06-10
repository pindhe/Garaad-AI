import 'package:flutter_test/flutter_test.dart';
import 'package:macallinai/main.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MacallinApp());
    await tester.pump();
    expect(find.byType(MacallinApp), findsOneWidget);
  });
}
