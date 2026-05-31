import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'skill_category_screen.dart';
import 'resource_placeholder_screen.dart';
import 'progress_placeholder_screen.dart';

/// Shell utama aplikasi Kairos.
/// Menyatukan modul-modul di bawah kendali Bottom Navigation Bar (Navbar) yang elegan.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      const SkillCategoryScreen(),
      const ResourcePlaceholderScreen(),
      const ProgressPlaceholderScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.hintColor.withValues(alpha: 0.5),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events_rounded),
              label: 'Keahlian',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_outlined),
              activeIcon: Icon(Icons.auto_stories_rounded),
              label: 'Referensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_outlined),
              activeIcon: Icon(Icons.trending_up_rounded),
              label: 'Jurnal',
            ),
          ],
        ),
      ),
    );
  }
}
