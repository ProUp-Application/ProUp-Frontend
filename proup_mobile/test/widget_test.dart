import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/app.dart';
import 'package:proup_mobile/core/di/injector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('la app arranca y, sin sesión, muestra la bienvenida', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await setupDependencies();

    await tester.pumpWidget(const ProUpApp());
    expect(find.text('ProUp'), findsWidgets);

    // El splash espera ~1 s y redirige a la bienvenida (onboarding)
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Analizamos tu imagen profesional'), findsOneWidget);
  });
}
