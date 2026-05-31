import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/skill_provider.dart';
import 'screens/main_shell.dart';

void main() async {
  // Wajib dipanggil untuk memastikan binding engine Flutter siap sebelum inisiasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Membuat instance provider secara independen untuk memuat data awal terlebih dahulu
  final skillProvider = SkillProvider();
  await skillProvider.loadInitialData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SkillProvider>.value(value: skillProvider),
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

    return MaterialApp(
      title: 'Kairos - Personal Growth Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
      home: const MainShell(),
    );
  }
}

