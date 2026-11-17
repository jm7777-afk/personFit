import 'package:flutter_test/flutter_test.dart';
import 'package:mi_personfit_mobile/main.dart';

void main() {
  testWidgets('App smoke test loads Kryon', (WidgetTester tester) async {
    await tester.pumpWidget(const KryonApp());
    expect(find.text('Kryon'), findsOneWidget);
  });
}
