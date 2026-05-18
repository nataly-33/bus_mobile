import 'package:flutter_test/flutter_test.dart';
import 'package:buses_sig/main.dart';

void main() {
  testWidgets('Role selector smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BusesSigApp());
    await tester.pump();
    expect(find.text('MicroBus SCZ'), findsWidgets);
  });
}
