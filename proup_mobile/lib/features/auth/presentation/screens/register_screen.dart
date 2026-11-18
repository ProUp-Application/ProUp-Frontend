import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../password_policy.dart';
import '../../../profile/data/user_repository.dart';
import '../../data/models/user_model.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _accepted = false;
  bool _showPassword = false;
  bool _submitted = false;
  List<ProfessionOption> _professions = UserRepository.fallbackProfessions;
  String? _profession;

  @override
  void initState() {
    super.initState();
    _loadProfessions();
  }

  Future<void> _loadProfessions() async {
    try {
      final list = await getIt<UserRepository>().getProfessions();
      if (mounted) setState(() => _professions = list);
    } catch (_) {}
  }

  /// Qué datos recopila ProUp y para qué (Ley N.° 29733).
  void _showDataInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qué datos usamos y para qué'),
        content: const SingleChildScrollView(
          child: Text(
            '• Cuenta: nombre, apellido, correo y contraseña (cifrada). Para identificarte.\n\n'
            '• Perfil: profesión, nivel y metas. Para adaptar recomendaciones y entrevistas.\n\n'
            '• Fotos: se analizan en tu teléfono y NUNCA se suben. Solo guardamos los puntajes y la explicación del resultado.\n\n'
            '• Entrevistas: tus respuestas y su evaluación quedan en tu historial. Si respondes hablando, el audio se envía solo para transcribirlo y no se guarda.\n\n'
            '• CV: en "Mejorar mi CV" se procesa para responderte y no se guarda. Si lo compartes en el chat, el texto queda en esa conversación.\n\n'
            '• IA externa: para generar consejos, evaluar entrevistas, transcribir audio y revisar tu CV enviamos texto o audio al proveedor de IA Groq. No enviamos tus fotos, tu correo ni tu contraseña.\n\n'
            '• Tus derechos: en Perfil > "Ver mis datos" puedes consultar tu información y también eliminar tu cuenta con todos sus datos.',
            style: TextStyle(fontSize: 13, height: 1.35),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // Primero los campos obligatorios (muestran su error debajo de cada uno) y,
    // solo con el formulario válido, el consentimiento de tratamiento de datos.
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar el tratamiento de datos personales')),
      );
      return;
    }
    context.read<AuthCubit>().register(
          email: _email.text.trim(),
          password: _password.text,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          profession: _profession,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.error ?? 'Error')));
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              // Tras el primer intento, cada campo se revalida al escribir (el error desaparece al corregirlo)
              autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _firstName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => validateName(v, 'nombre'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Apellido'),
                    validator: (v) => validateName(v, 'apellido'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo electrónico', hintText: 'nombre@correo.com', errorMaxLines: 3),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      errorMaxLines: 3,
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 8),
                  // Requisitos en tiempo real (REG-02)
                  ...passwordRules.map((r) {
                    final ok = r.test(_password.text);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 16, color: ok ? AppColors.tertiary : AppColors.outline),
                          const SizedBox(width: 8),
                          Text(r.label,
                              style: TextStyle(
                                  fontSize: 13, color: ok ? AppColors.tertiary : AppColors.onSurfaceVariant)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _profession,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: '¿Cuál es tu profesión?',
                      prefixIcon: Icon(Icons.work_outline, size: 20),
                    ),
                    items: _professions
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.label, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _profession = v),
                    validator: (v) => v == null ? 'Selecciona tu profesión' : null,
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _accepted,
                    onChanged: (v) => setState(() => _accepted = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Acepto el tratamiento de mis datos personales conforme a la Ley N.° 29733.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showDataInfo,
                      icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                      label: const Text('¿Qué datos usamos y para qué?'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) => FilledButton(
                      onPressed: state.isLoading ? null : _submit,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Registrarme'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Ya tengo cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
