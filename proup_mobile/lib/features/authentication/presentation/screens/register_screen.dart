import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../auth_cubit_factory.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<AuthCubit>().register(
          fullName: _fullNameController.text.trim(),
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
                    TextButton.icon(
                      onPressed: () => context.go(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Crea tu cuenta',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Empieza a construir una presencia profesional más sólida con ProUp.',
                      style: TextStyle(
                        color: Color(0xFF434656),
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    AuthTextField(
                      controller: _fullNameController,
                      label: 'Nombre completo',
                      keyboardType: TextInputType.name,
                    ),
                    const SizedBox(height: 16),
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
                            : const Text('Registrarme'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Ya tengo una cuenta'),
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