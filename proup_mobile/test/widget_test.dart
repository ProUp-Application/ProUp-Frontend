import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/app.dart';

void main() {
  testWidgets('ProUp app renders splash screen', (tester) async {
    await tester.pumpWidget(const ProUpApp());

    expect(find.text('Splash'), findsNWidgets(2));
  });
}