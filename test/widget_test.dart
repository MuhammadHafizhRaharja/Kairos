import 'package:flutter_test/flutter_test.dart';
import 'package:kairos/main.dart';

void main() {
  testWidgets('Kairos app shows welcome text', (WidgetTester tester) async {
    await tester.pumpWidget(const KairosApp());

    expect(find.text('Welcome to Kairos'), findsOneWidget);
  });
}
