import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'skill_category_screen.dart';
import 'resource_placeholder_screen.dart';
import 'progress_placeholder_screen.dart';

/// Shell utama aplikasi Kairos dengan Bottom Navigation Bar yang mengambang dan transparan (Glassmorphism).
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true, // Memungkinkan konten mengalir di belakang navbar yang mengambang
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : theme.colorScheme.primary).withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.hintColor.withValues(alpha: 0.4),
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontSize: 10),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.dashboard_rounded),
                    ),
                    activeIcon: Icon(Icons.dashboard_rounded),
                    label: 'Beranda',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.emoji_events_rounded),
                    ),
                    activeIcon: Icon(Icons.emoji_events_rounded),
                    label: 'Keahlian',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.auto_stories_rounded),
                    ),
                    activeIcon: Icon(Icons.auto_stories_rounded),
                    label: 'Referensi',
                  ),
                  BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Icon(Icons.trending_up_rounded),
                    ),
                    activeIcon: Icon(Icons.trending_up_rounded),
                    label: 'Jurnal',
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
