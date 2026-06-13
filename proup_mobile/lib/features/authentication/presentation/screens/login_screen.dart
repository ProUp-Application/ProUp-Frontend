import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../auth_cubit_factory.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<AuthCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubitFactory.create(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            context.go(AppRoutes.dashboard);
          }

          if (state.status == AuthStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error')),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'ProUp',
                      style: TextStyle(
                        color: Color(0xFF003EC7),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 56),
                    Text(
                      'Bienvenido de nuevo',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ingresa a tu cuenta para continuar mejorando tu perfil profesional.',
                      style: TextStyle(
                        color: Color(0xFF434656),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed:
                            state.isLoading ? null : () => _submit(context),
                        child: state.isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Crear una cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}