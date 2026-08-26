import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../marketplace/presentation/marketplace_screen.dart';
import '../../marketplace/presentation/create_product_screen.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/presentation/favorites_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../core/localization/app_locale_provider.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String? _syncedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final userId = context.watch<AuthProvider>().user?.uid;
    if (_syncedUserId == userId) return;
    _syncedUserId = userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MarketplaceProvider>().setUser(userId);
    });
  }

  Widget _pageForIndex(int index) => switch (index) {
    1 => const MarketplaceScreen(),
    3 => const FavoritesScreen(),
    4 => const ProfileScreen(),
    _ => const HomeScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageForIndex(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateProductScreen()),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.tr('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.store_outlined),
            selectedIcon: const Icon(Icons.store),
            label: context.tr('market'),
          ),
          NavigationDestination(
            icon: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF20D1B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
            label: context.tr('publish'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: context.tr('favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}
