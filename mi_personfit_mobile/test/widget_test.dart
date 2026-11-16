import 'package:flutter_test/flutter_test.dart';
import 'package:mi_personfit_mobile/main.dart';

void main() {
  testWidgets('App smoke test loads Mi PersonFit', (WidgetTester tester) async {
    await tester.pumpWidget(const MiPersonFitApp());
    expect(find.text('Mi PersonFit'), findsOneWidget);
  });
}
