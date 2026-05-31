import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'skill_category_screen.dart';
import 'resource_placeholder_screen.dart';
import 'progress_placeholder_screen.dart';

/// Shell utama aplikasi Kairos dengan Bottom Navigation Bar Kustom yang sangat elegan dan interaktif.
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
      extendBody:
          true, // Konten layar mengalir indah di bawah navbar yang melayang
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16, top: 10),
        height: 72,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.75)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isDark ? Colors.white : theme.colorScheme.primary)
                .withValues(alpha: 0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : theme.colorScheme.primary)
                  .withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Beranda'),
                _buildNavItem(1, Icons.emoji_events_rounded, 'Keahlian'),
                _buildNavItem(2, Icons.auto_stories_rounded, 'Referensi'),
                _buildNavItem(3, Icons.trending_up_rounded, 'Jurnal'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Membuat item menu navigasi kustom dengan efek animasi pill.
  Widget _buildNavItem(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.hintColor.withValues(alpha: 0.4);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
