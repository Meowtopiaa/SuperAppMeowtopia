import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppConstants.primaryColor,
          unselectedItemColor: AppConstants.textSecondary,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dinner_dining_outlined),
              activeIcon: Icon(Icons.dinner_dining),
              label: 'Feeding',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.catching_pokemon_outlined),
              activeIcon: Icon(Icons.catching_pokemon),
              label: 'Cat Dex',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.saved_search_rounded),
              label: 'Identifikasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Adopsi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emergency_outlined),
              activeIcon: Icon(Icons.emergency),
              label: 'Insiden',
            ),
          ],
        ),
      ),
    );
  }
}
