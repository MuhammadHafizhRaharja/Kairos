import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../data/database_helper.dart';
import '../models/skill_category.dart';
import '../models/skill.dart';

/// Halaman Register dengan desain premium, modern, dan sangat estetis (Glassmorphism).
/// Menerapkan Multi-step Form / Onboarding untuk inisiasi kategori & skill pertama pengguna.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep =
      0; // 0: Kredensial Akun, 1: Kategori, 2: Keahlian & Level Awal

  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Controllers Langkah 1 (Kredensial Akun)
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // State Langkah 2 (Kategori Pertama)
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

  // State Langkah 3 (Keahlian Pertama)
  final _skillNameController = TextEditingController();
  final _skillDescController = TextEditingController();
  int _initialSkillLevel = 1;
  double _initialSkillProgress = 0.0; // 0.0 sampai 100.0

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _customCategoryNameController.dispose();
    _skillNameController.dispose();
    _skillDescController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_step1FormKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
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
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _handleRegister() async {
    if (_step3FormKey.currentState!.validate()) {
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
      if (_currentStep < 1) return theme.colorScheme.primary;
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
                      'Mulai melacak kemampuan Anda secara terstruktur',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 3. KARTU REGISTER GLASSMORPHISM MULTI-STEP
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Indikator Progress Langkah
                              _buildStepIndicator(theme),

                              // Form Per Langkah
                              if (_currentStep == 0)
                                _buildStep1Credentials(theme)
                              else if (_currentStep == 1)
                                _buildStep2Category(theme, isDark)
                              else
                                _buildStep3SkillDetail(theme),

                              const SizedBox(height: 24),

                              // Navigasi Tombol Bawah
                              Row(
                                children: [
                                  if (_currentStep > 0)
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          side: BorderSide(color: accentColor),
                                          foregroundColor: accentColor,
                                        ),
                                        onPressed: isLoading ? null : _prevStep,
                                        child: const Text('Kembali'),
                                      ),
                                    ),
                                  if (_currentStep > 0)
                                    const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 4,
                                        shadowColor: accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      onPressed: isLoading
                                          ? null
                                          : (_currentStep == 2
                                                ? _handleRegister
                                                : _nextStep),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _currentStep == 2
                                                  ? 'Selesai & Buat Akun'
                                                  : 'Lanjut',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hubungkan Kembali Ke Login
                    if (_currentStep == 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun?',
                            style: TextStyle(color: theme.hintColor),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Masuk Sekarang',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildStepIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Akun', theme),
          _buildStepDivider(theme, 0),
          _buildStepCircle(1, 'Kategori', theme),
          _buildStepDivider(theme, 1),
          _buildStepCircle(2, 'Keahlian', theme),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String title, ThemeData theme) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? Colors.green
                : (isActive ? theme.colorScheme.primary : Colors.grey[400]),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? theme.colorScheme.primary
                : (isDone ? Colors.green : theme.hintColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(ThemeData theme, int afterStep) {
    final isPassed = _currentStep > afterStep;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isPassed ? Colors.green : Colors.grey.withValues(alpha: 0.3),
    );
  }

  // LANGKAH 1: Kredensial Akun
  Widget _buildStep1Credentials(ThemeData theme) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informasi Kredensial Akun',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Input Nama Lengkap
          TextFormField(
            controller: _nameController,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama lengkap tidak boleh kosong!';
              }
              if (value.trim().length < 2) {
                return 'Nama minimal harus 2 karakter!';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Input Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Alamat Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
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
          const SizedBox(height: 16),

          // Input Password
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
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
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
          const SizedBox(height: 16),

          // Input Konfirmasi Password
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
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
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
    );
  }

  // LANGKAH 2: Kategori Pertama
  Widget _buildStep2Category(ThemeData theme, bool isDark) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pilih Kategori Pertama Anda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ...templates.map((tpl) {
          final isSelected = _selectedCategoryType == tpl['type'];
          final color = tpl['color'] as Color;
          final icon = tpl['icon'] as IconData;
          return Card(
            elevation: isSelected ? 4 : 0.5,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  _selectedCategoryType = tpl['type'] as String;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        tpl['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: color),
                  ],
                ),
              ),
            ),
          );
        }),
        if (_selectedCategoryType == 'Kustom') ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Kustomisasi Kategori Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
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
          const SizedBox(height: 16),
          const Text(
            'Pilih Warna Kategori:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colorsList.length,
              itemBuilder: (context, idx) {
                final colorVal = _colorsList[idx]['value'] as int;
                final isColorSelected = _selectedCustomColor == colorVal;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCustomColor = colorVal),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(colorVal),
                      border: isColorSelected
                          ? Border.all(
                              color: isDark ? Colors.white : Colors.black,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Ikon Kategori:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
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
                  onTap: () => setState(() => _selectedCustomIcon = iconName),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isIconSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
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
    );
  }

  // LANGKAH 3: Detail Keahlian Pertama
  Widget _buildStep3SkillDetail(ThemeData theme) {
    Color getActiveColor() {
      if (_selectedCategoryType == 'Pemrograman') return Colors.blue;
      if (_selectedCategoryType == 'Kebugaran') return Colors.green;
      if (_selectedCategoryType == 'Bahasa') return Colors.orange;
      if (_selectedCategoryType == 'Musik & Seni') return Colors.purple;
      return Color(_selectedCustomColor);
    }

    final activeColor = getActiveColor();

    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Keahlian Pertama Anda',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: activeColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Lacak kemampuan awal di kategori ini',
            style: TextStyle(color: theme.hintColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Input Nama Keahlian
          TextFormField(
            controller: _skillNameController,
            decoration: InputDecoration(
              labelText: 'Nama Keahlian Pertama',
              hintText: 'misal: Flutter, Lari 5K, Gitar Klasik',
              prefixIcon: Icon(Icons.stars_rounded, color: activeColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: activeColor, width: 2),
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
          const SizedBox(height: 16),

          // Input Deskripsi Keahlian
          TextFormField(
            controller: _skillDescController,
            decoration: InputDecoration(
              labelText: 'Deskripsi / Catatan (Opsional)',
              hintText: 'misal: Belajar routing dan state provider',
              prefixIcon: Icon(Icons.edit_note_rounded, color: activeColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: activeColor, width: 2),
              ),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // Seleksi Level Awal
          Text(
            'Level Awal Anda: Level $_initialSkillLevel',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 12),
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
                        ? activeColor
                        : activeColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$lvl',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : activeColor,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Seleksi Progres Awal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progres Awal Keahlian:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${_initialSkillProgress.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: activeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _initialSkillProgress,
            min: 0,
            max: 100,
            divisions: 10,
            activeColor: activeColor,
            inactiveColor: activeColor.withValues(alpha: 0.25),
            label: '${_initialSkillProgress.round()}%',
            onChanged: (val) {
              setState(() => _initialSkillProgress = val);
            },
          ),
        ],
      ),
    );
  }
}
