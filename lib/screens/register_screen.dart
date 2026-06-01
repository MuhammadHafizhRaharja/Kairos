import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/database_helper.dart';
import '../models/skill_category.dart';
import '../models/skill.dart';

/// Halaman Register dengan desain premium, modern, dan sangat estetis (Glassmorphism).
/// Menerapkan penyederhanaan Onboarding: fase intro interaktif diikuti formulir tunggal (Single Screen)
/// dengan Roadmap Bubble Itinerary interaktif terintegrasi Scroll Spy.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _showIntro =
      true; // true: Tampilan Komitmen Awal, false: Formulir Onboarding Tunggal

  final _formKey = GlobalKey<FormState>();

  // Keys untuk section (Bubble Itinerary Scroll Spy)
  final _akunKey = GlobalKey();
  final _kategoriKey = GlobalKey();
  final _keahlianKey = GlobalKey();

  // Scroll Controller & active index
  final _scrollController = ScrollController();
  int _activeSectionIndex = 0;

  // Controllers Section 1 (Kredensial Akun)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // State Section 2 (Kategori Pertama)
  String _selectedCategoryType =
      'Pemrograman'; // 'Pemrograman', 'Kebugaran', 'Bahasa', 'Musik & Seni', 'Kustom'
  final _customCategoryNameController = TextEditingController();
  String _selectedCustomIcon = 'code';
  int _selectedCustomColor = 0xFF2196F3;

  // Pilihan Ikon dan Warna untuk Kategori Kustom
  final _iconsList = [
    'code',
    'fitness_center',
    'translate',
    'music_note',
    'book',
    'brush',
    'sports_basketball',
  ];
  final _colorsList = [
    {'name': 'Biru', 'value': 0xFF2196F3},
    {'name': 'Hijau', 'value': 0xFF4CAF50},
    {'name': 'Jingga', 'value': 0xFFFF9800},
    {'name': 'Ungu', 'value': 0xFF9C27B0},
    {'name': 'Merah', 'value': 0xFFE91E63},
    {'name': 'Toska', 'value': 0xFF009688},
    {'name': 'Indigo', 'value': 0xFF3F51B5},
  ];

  // State Section 3 (Keahlian Pertama)
  final _skillNameController = TextEditingController();
  final _skillDescController = TextEditingController();
  int _initialSkillLevel = 1;
  double _initialSkillProgress = 0.0; // 0.0 sampai 100.0

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customCategoryNameController.dispose();
    _skillNameController.dispose();
    _skillDescController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || _showIntro) return;

    final akunY = _getYOffset(_akunKey);
    final kategoriY = _getYOffset(_kategoriKey);
    final keahlianY = _getYOffset(_keahlianKey);

    int newIdx = 0;
    // Deteksi section yang paling dekat dengan batas atas viewport (misal Y < 240)
    if (keahlianY != null && keahlianY < 240) {
      newIdx = 2;
    } else if (kategoriY != null && kategoriY < 240) {
      newIdx = 1;
    } else if (akunY != null) {
      newIdx = 0;
    }

    if (newIdx != _activeSectionIndex) {
      setState(() {
        _activeSectionIndex = newIdx;
      });
    }
  }

  double? _getYOffset(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      final box = context.findRenderObject() as RenderBox?;
      if (box != null) {
        return box.localToGlobal(Offset.zero).dy;
      }
    }
    return null;
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      // Validasi khusus untuk kategori kustom
      if (_selectedCategoryType == 'Kustom' &&
          _customCategoryNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nama kategori kustom tidak boleh kosong!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Panggil registrasi user ke provider
      final errorMessage = await authProvider.register(name, email, password);

      if (!mounted) return;

      if (errorMessage == null) {
        // Registrasi sukses, ambil user ID
        final newUserId = authProvider.currentUser?.id;

        if (newUserId != null) {
          try {
            final dbHelper = DatabaseHelper.instance;

            // 1. Tentukan Nilai Kategori yang Akan Disimpan
            String catName = _selectedCategoryType;
            String catIcon = 'code';
            int catColor = 0xFF2196F3;

            if (_selectedCategoryType == 'Pemrograman') {
              catName = 'Pemrograman';
              catIcon = 'code';
              catColor = 0xFF2196F3;
            } else if (_selectedCategoryType == 'Kebugaran') {
              catName = 'Kebugaran';
              catIcon = 'fitness_center';
              catColor = 0xFF4CAF50;
            } else if (_selectedCategoryType == 'Bahasa') {
              catName = 'Bahasa';
              catIcon = 'translate';
              catColor = 0xFFFF9800;
            } else if (_selectedCategoryType == 'Musik & Seni') {
              catName = 'Musik & Seni';
              catIcon = 'music_note';
              catColor = 0xFF9C27B0;
            } else {
              // Mode Kustom
              catName = _customCategoryNameController.text.trim().isNotEmpty
                  ? _customCategoryNameController.text.trim()
                  : 'Kategori Kustom';
              catIcon = _selectedCustomIcon;
              catColor = _selectedCustomColor;
            }

            final newCat = SkillCategory(
              userId: newUserId,
              name: catName,
              icon: catIcon,
              colorValue: catColor,
            );
            final catId = await dbHelper.insertCategory(newCat);

            // 2. Simpan Keahlian Pertama
            final newSkill = Skill(
              userId: newUserId,
              categoryId: catId,
              name: _skillNameController.text.trim(),
              description: _skillDescController.text.trim(),
              level: _initialSkillLevel,
              progress: _initialSkillProgress / 100.0,
              createdAt: DateTime.now(),
            );
            await dbHelper.insertSkill(newSkill);
          } catch (e) {
            debugPrint('Error memproses onboarding pendaftaran: $e');
          }
        }

        if (!mounted) return;

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil! Selamat datang, $name! 🎉'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Pop seluruh screen auth agar kembali ke root (MainApp akan otomatis render MainShell)
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    Color getThemeAccentColor() {
      if (_showIntro) return theme.colorScheme.primary;
      if (_selectedCategoryType == 'Pemrograman') return Colors.blue;
      if (_selectedCategoryType == 'Kebugaran') return Colors.green;
      if (_selectedCategoryType == 'Bahasa') return Colors.orange;
      if (_selectedCategoryType == 'Musik & Seni') return Colors.purple;
      return Color(_selectedCustomColor);
    }

    final accentColor = getThemeAccentColor();

    return Scaffold(
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Dinamis dengan Efek Lingkaran Cahaya
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1B4B), // Indigo gelap
                        const Color(0xFF0F172A), // Slate gelap
                        const Color(0xFF311042), // Ungu gelap
                      ]
                    : [
                        const Color(0xFFEEF2F6), // Abu sangat terang
                        const Color(0xFFE0E7FF), // Indigo sangat terang
                        const Color(0xFFFAE8FF), // Pink sangat terang
                      ],
              ),
            ),
          ),

          // Lingkaran Dekorasi Blur Bercahaya
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: const SizedBox(),
              ),
            ),
          ),

          // Lingkaran Dekorasi Blur Bercahaya
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: const SizedBox(),
              ),
            ),
          ),

          // 2. Konten Utama Terpusat
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Judul Form
                    Text(
                      'Pendaftaran Kairos',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _showIntro
                          ? 'Mulai perjalanan melacak kemampuan Anda'
                          : 'Lengkapi formulir onboarding tunggal Anda',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. KARTU REGISTER GLASSMORPHISM
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color:
                                  (isDark
                                          ? Colors.white
                                          : theme.colorScheme.primary)
                                      .withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: _showIntro
                              ? _buildIntroStep(theme, accentColor)
                              : _buildSingleForm(
                                  theme,
                                  accentColor,
                                  isDark,
                                  isLoading,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FASE 1: Pertanyaan Awal Kesiapan (Intro)
  Widget _buildIntroStep(ThemeData theme, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: accentColor.withValues(alpha: 0.15),
            child: Icon(
              Icons.rocket_launch_rounded,
              color: accentColor,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Komitmen Pertumbuhan Diri',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Halo! Sebelum melacak perkembangan Anda di KAIROS, mari kita siapkan akun dan keahlian pertama Anda.\n\nApakah Anda siap mendisiplinkan diri untuk belajar, berlatih, dan berkembang setiap hari?',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.hintColor, fontSize: 13.5, height: 1.5),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                  foregroundColor: theme.hintColor,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0, // Minimalist (flat)
                ),
                onPressed: () {
                  setState(() {
                    _showIntro = false;
                  });
                },
                child: const Text(
                  'Ya, Saya Siap! 🚀',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // FASE 2: Formulir Onboarding Tunggal (1 Screen)
  Widget _buildSingleForm(
    ThemeData theme,
    Color accentColor,
    bool isDark,
    bool isLoading,
  ) {
    final templates = [
      {
        'type': 'Pemrograman',
        'name': 'Pemrograman',
        'icon': Icons.code_rounded,
        'color': Colors.blue,
      },
      {
        'type': 'Kebugaran',
        'name': 'Kebugaran',
        'icon': Icons.fitness_center_rounded,
        'color': Colors.green,
      },
      {
        'type': 'Bahasa',
        'name': 'Bahasa',
        'icon': Icons.translate_rounded,
        'color': Colors.orange,
      },
      {
        'type': 'Musik & Seni',
        'name': 'Musik & Seni',
        'icon': Icons.music_note_rounded,
        'color': Colors.purple,
      },
      {
        'type': 'Kustom',
        'name': 'Kategori Kustom',
        'icon': Icons.tune_rounded,
        'color': Colors.grey,
      },
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // BUBBLE ITINERARY ROADMAP
          _buildBubbleItinerary(theme),
          const SizedBox(height: 12),

          // ---------------- SECTION 1: AKUN ----------------
          Container(
            key: _akunKey,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_pin_rounded,
                      color: accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '1. Informasi Akun Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Alamat Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat email tidak boleh kosong!';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format email tidak valid!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kata sandi tidak boleh kosong!';
                    }
                    if (value.length < 6) {
                      return 'Kata sandi minimal harus 6 karakter!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Kata Sandi',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi kata sandi tidak boleh kosong!';
                    }
                    if (value != _passwordController.text) {
                      return 'Kata sandi tidak cocok!';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ---------------- SECTION 2: KATEGORI ----------------
          Container(
            key: _kategoriKey,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.category_rounded, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '2. Kategori Keahlian Pertama',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Horizontal Template Selector
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    itemBuilder: (context, idx) {
                      final tpl = templates[idx];
                      final type = tpl['type'] as String;
                      final name = tpl['name'] as String;
                      final icon = tpl['icon'] as IconData;
                      final color = tpl['color'] as Color;
                      final isSelected = _selectedCategoryType == type;

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategoryType = type),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : theme.dividerColor.withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: isSelected ? color : theme.hintColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                if (_selectedCategoryType == 'Kustom') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customCategoryNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Kategori Kustom',
                      hintText: 'misal: Memasak, Fotografi, Keuangan',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Warna Kategori:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorsList.length,
                      itemBuilder: (context, idx) {
                        final colorVal = _colorsList[idx]['value'] as int;
                        final isColorSelected =
                            _selectedCustomColor == colorVal;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCustomColor = colorVal),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(colorVal),
                              border: isColorSelected
                                  ? Border.all(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Ikon Kategori:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconsList.length,
                      itemBuilder: (context, idx) {
                        final iconName = _iconsList[idx];
                        final isIconSelected = _selectedCustomIcon == iconName;
                        IconData getIcon(String name) {
                          switch (name) {
                            case 'code':
                              return Icons.code_rounded;
                            case 'fitness_center':
                              return Icons.fitness_center_rounded;
                            case 'translate':
                              return Icons.translate_rounded;
                            case 'music_note':
                              return Icons.music_note_rounded;
                            case 'book':
                              return Icons.book_rounded;
                            case 'brush':
                              return Icons.brush_rounded;
                            case 'sports_basketball':
                              return Icons.sports_basketball_rounded;
                            default:
                              return Icons.category_rounded;
                          }
                        }

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCustomIcon = iconName),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isIconSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                              border: Border.all(
                                color: isIconSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              getIcon(iconName),
                              color: isIconSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // ---------------- SECTION 3: KEAHLIAN ----------------
          Container(
            key: _keahlianKey,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded, color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '3. Keterampilan / Keahlian Pertama',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skillNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Keahlian Pertama',
                    hintText: 'misal: Flutter, Lari 5K, Gitar Klasik',
                    prefixIcon: Icon(
                      Icons.workspace_premium_rounded,
                      color: accentColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama keahlian tidak boleh kosong!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skillDescController,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Keahlian (Opsional)',
                    hintText: 'misal: Memahami widget & state provider',
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: accentColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level Awal Anda: Level $_initialSkillLevel',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(5, (index) {
                    final lvl = index + 1;
                    final isSelected = _initialSkillLevel == lvl;
                    return GestureDetector(
                      onTap: () => setState(() => _initialSkillLevel = lvl),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? accentColor
                              : accentColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: isSelected
                                ? accentColor
                                : Colors.grey.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$lvl',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : accentColor,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progres Awal Keahlian:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      '${_initialSkillProgress.round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Slider(
                  value: _initialSkillProgress,
                  min: 0,
                  max: 100,
                  divisions: 10,
                  activeColor: accentColor,
                  inactiveColor: accentColor.withValues(alpha: 0.25),
                  label: '${_initialSkillProgress.round()}%',
                  onChanged: (val) =>
                      setState(() => _initialSkillProgress = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Tombol Aksi Minimalis Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                    foregroundColor: theme.hintColor,
                  ),
                  onPressed: () => setState(() => _showIntro = true),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0, // Minimalist (flat)
                  ),
                  onPressed: isLoading ? null : _handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Selesai & Buat Akun',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET: BUBBLE ITINERARY ROADMAP
  Widget _buildBubbleItinerary(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBubbleItem(0, 'Akun', _akunKey, theme),
          _buildBubbleConnector(theme, 0),
          _buildBubbleItem(1, 'Kategori', _kategoriKey, theme),
          _buildBubbleConnector(theme, 1),
          _buildBubbleItem(2, 'Keahlian', _keahlianKey, theme),
        ],
      ),
    );
  }

  Widget _buildBubbleItem(
    int index,
    String label,
    GlobalKey key,
    ThemeData theme,
  ) {
    final isSelected = _activeSectionIndex == index;
    final isPassed = _activeSectionIndex > index;
    final accentColor = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => _scrollToSection(key),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? accentColor
                  : (isPassed
                        ? Colors.green
                        : accentColor.withValues(alpha: 0.1)),
              border: Border.all(
                color: isSelected
                    ? accentColor
                    : (isPassed
                          ? Colors.green
                          : Colors.grey.withValues(alpha: 0.3)),
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: isPassed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? accentColor
                  : (isPassed ? Colors.green : theme.hintColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleConnector(ThemeData theme, int afterStep) {
    final isPassed = _activeSectionIndex > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
        color: isPassed
            ? Colors.green
            : theme.dividerColor.withValues(alpha: 0.2),
      ),
    );
  }
}
