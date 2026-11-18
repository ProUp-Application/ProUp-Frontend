// Política de contraseña del registro. Es la MISMA que valida el backend
// (ProUp-Backend/src/modules/auth/auth.schemas.ts), para que la app avise antes.

class PasswordRule {
  const PasswordRule(this.label, this.test);

  final String label;
  final bool Function(String) test;
}

final passwordRules = <PasswordRule>[
  PasswordRule('Al menos 8 caracteres', (p) => p.length >= 8),
  PasswordRule('Una letra mayúscula', (p) => RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(p)),
  PasswordRule('Una letra minúscula', (p) => RegExp(r'[a-záéíóúñ]').hasMatch(p)),
  PasswordRule('Un número', (p) => RegExp(r'\d').hasMatch(p)),
];

/// Requisitos que aún no cumple la contraseña (vacío = válida).
List<String> missingPasswordRules(String password) =>
    passwordRules.where((r) => !r.test(password)).map((r) => r.label).toList();

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateEmail(String? v) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Ingresa tu correo';
  if (!_emailRe.hasMatch(value)) return 'Ingresa un correo válido, por ejemplo nombre@correo.com';
  return null;
}

String? validateName(String? v, String field) {
  final value = (v ?? '').trim();
  if (value.isEmpty) return 'Ingresa tu $field';
  if (value.length > 60) return 'Tu $field es demasiado largo';
  if (RegExp(r'\d').hasMatch(value)) return 'Tu $field no debe tener números';
  return null;
}

String? validatePassword(String? v) {
  final missing = missingPasswordRules(v ?? '');
  if (missing.isEmpty) return null;
  return 'Falta: ${missing.map((m) => m.toLowerCase()).join(', ')}';
}
