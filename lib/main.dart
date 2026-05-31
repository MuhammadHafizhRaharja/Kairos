import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/skill_provider.dart';
import 'models/skill_category.dart';

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
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      ),
      // Desain estetika mode gelap dengan Google Fonts
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const SkillTestScreen(),
    );
  }
}

/// Screen pengujian sementara untuk memvalidasi alur data (Data Flow) Modul Skill
class SkillTestScreen extends StatefulWidget {
  const SkillTestScreen({super.key});

  @override
  State<SkillTestScreen> createState() => _SkillTestScreenState();
}

class _SkillTestScreenState extends State<SkillTestScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mengakses data dari provider
    final provider = context.watch<SkillProvider>();
    final categories = provider.categories;
    final skills = provider.skills;

    // Set nilai text controller pertama kali agar sesuai dengan data preferences yang dimuat
    if (_nameController.text.isEmpty && provider.userName != 'Pengguna Kairos') {
      _nameController.text = provider.userName;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kairos - Modul Skill'),
        centerTitle: true,
        actions: [
          // Switch untuk menguji Shared Preferences (appTheme) secara real-time
          IconButton(
            icon: Icon(provider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              provider.toggleTheme(!provider.isDarkMode);
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD 1: UJI COBA SHARED PREFERENCES
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      key: const Key('prefs_card'),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Persistent Storage (Shared Preferences)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Nama Profil Saat Ini: ${provider.userName}'),
                          Text('Mode Gelap Aktif: ${provider.isDarkMode ? "Ya" : "Tidak"}'),
                          Text('Total Skill Dilacak: ${skills.length}'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ubah Nama Profil',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  if (_nameController.text.trim().isNotEmpty) {
                                    provider.updateUserName(_nameController.text.trim());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Nama berhasil disimpan secara persisten!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Simpan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CARD 2: UJI COBA DATABASE SQLITE (SEEDED CATEGORIES)
                  const Text(
                    '2. Database Local (Seeded Categories - sqflite)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (categories.isEmpty)
                    const Text('Belum ada kategori. Periksa inisiasi database helper.')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        // Mengambil list skill spesifik kategori ini (CRUD check)
                        final categorySkills = provider.getSkillsForCategory(category.id ?? -1);

                        return Card(
                          key: Key('category_${category.id}'),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: Color(category.colorValue).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
                              child: Icon(
                                _getIconData(category.icon),
                                color: Color(category.colorValue),
                              ),
                            ),
                            title: Text(
                              category.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('${categorySkills.length} skill dilacak'),
                            trailing: IconButton(
                              icon: const Icon(Icons.add, color: Colors.blue),
                              onPressed: () {
                                _showAddSkillDialog(context, provider, category);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  /// Helper sederhana untuk memetakan string nama ikon ke IconData Flutter
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'translate':
        return Icons.translate;
      case 'music_note':
        return Icons.music_note;
      default:
        return Icons.star;
    }
  }

  /// Dialog input untuk menambahkan skill ke kategori yang dipilih (CRUD Create & Read test)
  void _showAddSkillDialog(BuildContext context, SkillProvider provider, SkillCategory category) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Skill ke Kategori "${category.name}"'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Skill',
              hintText: 'misal: Belajar Flutter, Angkat Beban',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = nameController.text.trim();
                if (text.isNotEmpty) {
                  provider.addSkill(
                    categoryId: category.id!,
                    name: text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Skill "$text" berhasil ditambahkan!'),
                    ),
                  );
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}
