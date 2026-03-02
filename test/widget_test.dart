import 'package:flutter_test/flutter_test.dart';
import 'package:badr/main.dart';

void main() {
  testWidgets('Badr app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BadrApp());
  });
}
