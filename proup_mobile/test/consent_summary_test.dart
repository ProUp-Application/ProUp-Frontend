import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/features/profile/presentation/screens/profile_screen.dart';

void main() {
  group('Resumen del consentimiento en "Ver mis datos" (CP013)', () {
    test('muestra el consentimiento DATA_PROCESSING aceptado con fecha y versión', () {
      final text = consentSummary([
        {'type': 'DATA_PROCESSING', 'granted': true, 'version': '1.0', 'grantedAt': '2026-11-06T15:00:00.000Z'},
      ]);
      expect(text, 'aceptado el 06/11/2026 (versión 1.0)');
    });

    test('usa el registro más reciente e ignora otros tipos de consentimiento', () {
      final text = consentSummary([
        {'type': 'DATA_PROCESSING', 'granted': true, 'version': '1.0', 'grantedAt': '2026-10-01T15:00:00.000Z'},
        {'type': 'MARKETING', 'granted': true, 'version': '1.0', 'grantedAt': '2026-11-20T15:00:00.000Z'},
        {'type': 'DATA_PROCESSING', 'granted': false, 'version': '1.0', 'grantedAt': '2026-11-05T15:00:00.000Z'},
      ]);
      expect(text, 'revocado el 05/11/2026 (versión 1.0)');
    });

    test('sin registros devuelve "sin registro"', () {
      expect(consentSummary(null), 'sin registro');
      expect(consentSummary([]), 'sin registro');
    });
  });
}
