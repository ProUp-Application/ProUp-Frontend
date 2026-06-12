import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/app.dart';

void main() {
  testWidgets('ProUp app renders onboarding screen', (tester) async {
    await tester.pumpWidget(const ProUpApp());

    expect(find.text('ProUp'), findsOneWidget);
    expect(find.text('Analizamos tu imagen profesional'), findsOneWidget);
  });
}