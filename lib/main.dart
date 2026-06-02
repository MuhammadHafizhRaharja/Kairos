import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/skill_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';

void main() async {
  // Wajib dipanggil untuk memastikan binding engine Flutter siap sebelum inisiasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisiasi SkillProvider & memuat data awal
  final skillProvider = SkillProvider();
  await skillProvider.loadInitialData();

  // Inisiasi AuthProvider & memuat status sesi aktif
  final authProvider = AuthProvider();
  await authProvider.checkLoginStatus();

  // Inisiasi ProgressProvider & memuat data awal
  final progressProvider = ProgressProvider();
  await progressProvider.loadInitialData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan status mode gelap dari SkillProvider secara reaktif
    final isDarkMode = context.watch<SkillProvider>().isDarkMode;
    // Memantau status login secara reaktif
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final currentUser = authProvider.currentUser;

    // Sinkronisasi data user aktif ke SkillProvider secara reaktif dan aman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final skillProvider = context.read<SkillProvider>();
        if (skillProvider.currentUserId != currentUser?.id) {
          skillProvider.setUserId(currentUser?.id);
        }
        final progressProvider = context.read<ProgressProvider>();
        if (progressProvider.currentUserId != currentUser?.id) {
          progressProvider.setUserId(currentUser?.id);
        }
      }
    });

    // Memantau perubahan mode tata letak dan ukuran font global
    final progressProvider = context.watch<ProgressProvider>();
    final double textScale = progressProvider.fontSize / 14.0; // Baseline 14.0

    return MaterialApp(
      title: 'Kairos - Personal Growth Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      // Desain estetika mode terang dengan Google Fonts
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      // Desain estetika mode gelap dengan Google Fonts
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      // Jika sudah masuk, arahkan ke MainShell, jika belum, ke WelcomeScreen
      home: isLoggedIn ? const MainShell() : const WelcomeScreen(),
    );
  }
}
