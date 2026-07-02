import 'package:flutter/material.dart';

import '../../../analysis/presentation/screens/scan_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import 'home_dashboard_screen.dart';

/// Contenedor principal con barra de navegación inferior de 5 destinos.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _progressKey = GlobalKey<ProgressScreenState>();

  void _select(int i) {
    setState(() => _index = i);
    // La pestaña Progreso recarga sus datos cada vez que se abre
    // (con IndexedStack el widget vive siempre y su initState corre una sola vez).
    if (i == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _progressKey.currentState?.reload();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboardScreen(onSelectTab: _select),
      const ScanScreen(),
      ChatScreen(onSelectTab: _select),
      ProgressScreen(key: _progressKey),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.center_focus_strong_outlined), selectedIcon: Icon(Icons.center_focus_strong), label: 'Escanear'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Asesor'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Progreso'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
