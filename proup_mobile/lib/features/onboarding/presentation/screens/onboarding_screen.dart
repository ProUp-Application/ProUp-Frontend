import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/onboarding_page_view.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  static const List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Analizamos tu imagen profesional',
      description: 'Descrubre cómo te ven los demás y mejora tu impacto visual con nuestra tecnología de análisis de imagen.',
      visualType: OnboardingVisualType.imageAnalysis,
      ),
    OnboardingPageData(
      title: 'Simula entrevistas reales',
      description: 'Practica en un entorno seguro con nuestro simulador de entrevistas, diseñado para ayudarte a ganar confianza y mejorar tus habilidades de comunicación.',
      visualType:OnboardingVisualType.interview,
    ),
    OnboardingPageData(
      title: 'Recomendaciones personalizadas',
      description: 'Recibe sugerencias adaptadas a tu perfil profesional para mejorar tu presencia en línea y aumentar tus oportunidades de empleo.',
      visualType: OnboardingVisualType.recommendations,    
    ),
  ];

  @override
  void dispose(){
    _pageController.dispose();
    super.dispose();
  }

  void _goNext(BuildContext context, OnboardingState state) {
    if (state.isLastPage) {
      context.go(AppRoutes.login);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip(BuildContext context) {
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child:BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FF),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          'ProUp',
                          style:TextStyle(
                            color:Color(0xFF003EC7),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _skip(context),
                          child: const Text(
                            'Saltar',
                            style:TextStyle(
                              color:Color(0xFF434656),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged:
                      context.read<OnboardingCubit>().pageChanged,
                      itemBuilder:(context, index) {
                        return OnboardingPageView(page: _pages[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      children: [
                        _OnboardingIndicator(
                          currentPage: state.currentPage,
                          totalPages: _pages.length,
                        ),

                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: FilledButton.icon(
                            onPressed: () => _goNext(context, state),
                            iconAlignment: IconAlignment.end,
                            icon: state.isLastPage
                            ? const SizedBox.shrink()
                            : const Icon(Icons.arrow_forward),
                            label: Text(
                              state.isLastPage ? 'Comenzar' : 'siguiente',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnboardingIndicator extends StatelessWidget {
  const _OnboardingIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 36 : 12,
          height: 8,
          decoration: BoxDecoration(
            color:isActive
            ? const Color(0xFF003EC7)
            : const Color(0xFFD3E4FE),
            borderRadius:BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}