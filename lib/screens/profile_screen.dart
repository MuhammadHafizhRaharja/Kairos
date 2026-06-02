import 'dart:ui';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/progress_provider.dart';

/// Layar Detail Profil Pengguna yang mewah, interaktif, dan berdedikasi tinggi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Render helper untuk avatar pengguna yang fleksibel dan premium
  static Widget buildAvatarWidget(String? photoPath, String name, double radius, ThemeData theme) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'K';
    
    // Check if it's a predefined archetype first
    if (photoPath == 'coder') {
      return _avatarContainer(radius, [Colors.blue, Colors.cyan], Icons.code_rounded);
    } else if (photoPath == 'athlete') {
      return _avatarContainer(radius, [Colors.green, Colors.teal], Icons.fitness_center_rounded);
    } else if (photoPath == 'polyglot') {
      return _avatarContainer(radius, [Colors.orange, Colors.amber], Icons.translate_rounded);
    } else if (photoPath == 'artist') {
      return _avatarContainer(radius, [Colors.red, Colors.pink], Icons.music_note_rounded);
    } else if (photoPath == 'explorer') {
      return _avatarContainer(radius, [Colors.purple, Colors.deepPurple], Icons.rocket_launch_rounded);
    } else if (photoPath == 'scholar') {
      return _avatarContainer(radius, [Colors.teal, Colors.cyan], Icons.menu_book_rounded);
    } else if (photoPath == 'gamer') {
      return _avatarContainer(radius, [Colors.pink, Colors.purple], Icons.sports_esports_rounded);
    } else if (photoPath == 'minimal') {
      return _avatarContainer(radius, [Colors.blueGrey, Colors.grey], Icons.person_rounded);
    }
    
    // Custom photo (Base64 string or Image URL)
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        if (photoPath.startsWith('http') || photoPath.startsWith('https')) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.transparent,
            backgroundImage: NetworkImage(photoPath),
          );
        }
        
        // Clean base64 string
        String cleanBase64 = photoPath;
        if (photoPath.contains(',')) {
          cleanBase64 = photoPath.split(',').last;
        }
        final decodedBytes = base64Decode(cleanBase64);
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: MemoryImage(decodedBytes),
        );
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
      }
    }
    
    // Fallback: Initial Avatar
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  static Widget _avatarContainer(double radius, List<Color> colors, IconData icon) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: radius,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    final skillProvider = Provider.of<SkillProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(skillProvider.translate('logout_session'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              skillProvider.translate('logout_confirm'),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(skillProvider.translate('cancel'), style: TextStyle(color: theme.hintColor)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context); // Tutup halaman profil
                  await authProvider.logout(); // Bersihkan sesi aktif
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(skillProvider.translate('logout_success')),
                        backgroundColor: Colors.blueGrey,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(skillProvider.translate('logout')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, AuthProvider authProvider, ThemeData theme) {
    final user = authProvider.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final urlController = TextEditingController(
      text: (user.photoPath != null && user.photoPath!.startsWith('http')) ? user.photoPath : ''
    );
    
    String? tempSelectedAvatar = user.photoPath;
    final formKey = GlobalKey<FormState>();

    final avatars = [
      {'id': 'coder', 'icon': Icons.code_rounded, 'color': Colors.blue, 'label': 'Tech Coder'},
      {'id': 'athlete', 'icon': Icons.fitness_center_rounded, 'color': Colors.green, 'label': 'Athlete'},
      {'id': 'polyglot', 'icon': Icons.translate_rounded, 'color': Colors.orange, 'label': 'Polyglot'},
      {'id': 'artist', 'icon': Icons.music_note_rounded, 'color': Colors.red, 'label': 'Artist'},
      {'id': 'explorer', 'icon': Icons.rocket_launch_rounded, 'color': Colors.purple, 'label': 'Explorer'},
      {'id': 'scholar', 'icon': Icons.menu_book_rounded, 'color': Colors.teal, 'label': 'Scholar'},
      {'id': 'gamer', 'icon': Icons.sports_esports_rounded, 'color': Colors.pink, 'label': 'Gamer'},
      {'id': 'minimal', 'icon': Icons.person_rounded, 'color': Colors.blueGrey, 'label': 'Minimalist'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            
            Future<void> pickCustomImage() async {
              try {
                final result = await FilePicker.pickFiles(
                  type: FileType.image,
                  allowMultiple: false,
                  withData: true,
                );
                if (result != null) {
                  final file = result.files.single;
                  Uint8List? bytes;
                  
                  if (kIsWeb) {
                    bytes = file.bytes;
                  } else {
                    bytes = file.bytes ?? (file.path != null ? io.File(file.path!).readAsBytesSync() : null);
                  }
                  
                  if (bytes != null) {
                    if (kIsWeb && bytes.length > 500 * 1024) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ukuran gambar terlalu besar! Maksimal 500 KB untuk versi Web. ⚠️'),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                      return;
                    }
                    final base64String = base64Encode(bytes);
                    setSheetState(() {
                      tempSelectedAvatar = base64String;
                      urlController.clear(); // Bersihkan URL jika memilih file
                    });
                  }
                }
              } catch (e) {
                debugPrint('Error picking file: $e');
              }
            }

            final skillProvider = Provider.of<SkillProvider>(context, listen: false);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              skillProvider.translate('edit_profile'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(sheetCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Input Nama Lengkap
                        TextFormField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: skillProvider.translate('full_name'),
                            prefixIcon: const Icon(Icons.person_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return skillProvider.translate('name_empty');
                            return null;
                          },
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),

                        // Input Email
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: skillProvider.translate('email_account'),
                            prefixIcon: const Icon(Icons.email_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return skillProvider.translate('email_empty');
                            if (!val.contains('@')) return skillProvider.translate('email_invalid');
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Input Nomor Telepon
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: skillProvider.translate('phone_number'),
                            prefixIcon: const Icon(Icons.phone_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ==========================================
                        // SEKSI DEDIKASI: FOTO/GAMBAR CUSTOM
                        // ==========================================
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.photo_library_rounded, color: theme.colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    skillProvider.translate('use_own_photo'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Preview foto saat ini yang diupload
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: (tempSelectedAvatar != null && tempSelectedAvatar!.isNotEmpty && !['coder','athlete','polyglot','artist','explorer','scholar','gamer','minimal'].contains(tempSelectedAvatar))
                                            ? theme.colorScheme.primary
                                            : Colors.grey.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: (tempSelectedAvatar != null && tempSelectedAvatar!.isNotEmpty)
                                          ? buildAvatarWidget(tempSelectedAvatar, '', 30, theme)
                                          : Container(
                                              color: Colors.grey.withValues(alpha: 0.1),
                                              child: const Icon(Icons.person_rounded, color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (tempSelectedAvatar != null && tempSelectedAvatar!.isNotEmpty && !['coder','athlete','polyglot','artist','explorer','scholar','gamer','minimal'].contains(tempSelectedAvatar))
                                              ? skillProvider.translate('custom_photo_active')
                                              : skillProvider.translate('using_archetype'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: (tempSelectedAvatar != null && tempSelectedAvatar!.isNotEmpty && !['coder','athlete','polyglot','artist','explorer','scholar','gamer','minimal'].contains(tempSelectedAvatar))
                                                ? Colors.green
                                                : theme.hintColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          skillProvider.translate('choose_small_photo'),
                                          style: const TextStyle(fontSize: 10, height: 1.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Cara 1: File Picker
                              OutlinedButton.icon(
                                onPressed: pickCustomImage,
                                icon: const Icon(Icons.cloud_upload_rounded, size: 16),
                                label: Text(skillProvider.translate('choose_file_device')),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                              
                              const SizedBox(height: 10),
                              Center(child: Text(skillProvider.translate('or'), style: const TextStyle(fontSize: 11, color: Colors.grey))),
                              const SizedBox(height: 10),
                              
                              // Cara 2: Paste URL Gambar
                              TextFormField(
                                controller: urlController,
                                decoration: InputDecoration(
                                  labelText: skillProvider.translate('web_image_url'),
                                  hintText: 'https://example.com/profile.jpg',
                                  prefixIcon: const Icon(Icons.link_rounded),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (val) {
                                  setSheetState(() {
                                    tempSelectedAvatar = val.trim();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pilihan Avatar Archetype
                        Text(
                          skillProvider.translate('or_choose_archetype'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 10),

                        // Grid Avatar Archetypes
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: avatars.length + 1,
                          itemBuilder: (gridCtx, index) {
                            if (index == 0) {
                              // Pilihan Avatar Klasik (Inisial Nama)
                              final isSelected = tempSelectedAvatar == null || tempSelectedAvatar == '';
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    tempSelectedAvatar = '';
                                    urlController.clear();
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                      width: 2.5,
                                    ),
                                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: theme.colorScheme.primaryContainer,
                                        child: Text(
                                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'K',
                                          style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        skillProvider.translate('classic'),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final av = avatars[index - 1];
                            final String id = av['id'] as String;
                            final IconData icon = av['icon'] as IconData;
                            final Color color = av['color'] as Color;
                            final String label = av['label'] as String;
                            final isSelected = tempSelectedAvatar == id;

                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  tempSelectedAvatar = id;
                                  urlController.clear();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [color, color.withValues(alpha: 0.7)],
                                        ),
                                      ),
                                      child: Icon(icon, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Action Submit Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final newName = nameController.text.trim();
                              final newEmail = emailController.text.trim();
                              final newPhone = phoneController.text.trim();

                              final errMsg = await authProvider.updateProfile(
                                name: newName,
                                email: newEmail,
                                phone: newPhone,
                                photoPath: tempSelectedAvatar,
                              );

                              if (context.mounted) {
                                if (errMsg == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(skillProvider.translate('profile_updated')),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  Navigator.pop(sheetCtx);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errMsg),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: Text(skillProvider.translate('save_changes')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final authProvider = context.watch<AuthProvider>();
    final skillProvider = context.watch<SkillProvider>();
    
    final user = authProvider.currentUser;
    
    // Formatting date
    final String formattedDate = user != null
        ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
        : '1/6/2026';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(skillProvider.translate('user_profile'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Latar Belakang Gradasi Premium
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        theme.colorScheme.surface,
                      ]
                    : [
                        theme.colorScheme.primary.withValues(alpha: 0.05),
                        theme.colorScheme.surface,
                      ],
              ),
            ),
          ),
          
          // Lingkaran Hiasan Blur
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: const SizedBox(),
              ),
            ),
          ),

          // 2. Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // A. HEAD SHOT & GLOWING AVATAR CARD
                  Center(
                    child: Column(
                      children: [
                        // Avatar Berkilau
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: buildAvatarWidget(user?.photoPath, user?.name ?? '', 46, theme),
                        ),
                        const SizedBox(height: 16),
                        
                        // Nama Lengkap Pengguna
                        Text(
                          user?.name ?? 'Pengguna Kairos',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        
                        // Email Pengguna
                        Text(
                          user?.email ?? 'user@kairos.app',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Nomor Telepon Pengguna (Jika ada)
                        if (user?.phone != null && user!.phone!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_rounded, size: 14, color: theme.colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                user.phone!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Tombol Edit Profil
                        TextButton.icon(
                          onPressed: () => _showEditProfileBottomSheet(context, authProvider, theme),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: Text(skillProvider.translate('edit_profile_info'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Joined Chip
                        Chip(
                          avatar: Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.primary),
                          label: Text(
                            skillProvider.translate('joined', args: [formattedDate]),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // B. SECTION STATISTIK AKTIF (Visual Riil)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      skillProvider.translate('learning_achievements'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      _buildStatCard(
                        theme, 
                        Icons.dashboard_customize_rounded, 
                        skillProvider.translate('categories'), 
                        '${skillProvider.categories.length}',
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        theme, 
                        Icons.workspace_premium_rounded, 
                        skillProvider.translate('nav_skills'), 
                        '${skillProvider.skills.length}',
                        theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        theme, 
                        Icons.menu_book_rounded, 
                        skillProvider.translate('nav_resources'), 
                        '${skillProvider.resources.length}',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // C. SECTION PREFERENSI & SETELAN
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      skillProvider.translate('preferences_settings'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                               Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: [
                          // 1. Switch Notifikasi
                          ListTile(
                            leading: Icon(Icons.notifications_active_outlined, color: theme.colorScheme.primary),
                            title: Text(skillProvider.translate('daily_notifications'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(skillProvider.translate('periodic_reminders'), style: const TextStyle(fontSize: 11)),
                            trailing: Switch(
                              value: skillProvider.isNotificationEnabled,
                              onChanged: (val) {
                                skillProvider.toggleNotification(val);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(val ? skillProvider.translate('notification_active') : skillProvider.translate('notification_inactive')),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 2. Switch Mode Gelap
                          ListTile(
                            leading: Icon(
                              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              color: Colors.purple,
                            ),
                            title: Text(skillProvider.translate('dark_mode'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              isDark ? skillProvider.translate('dark_theme_active') : skillProvider.translate('light_theme_active'),
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Switch(
                              value: skillProvider.isDarkMode,
                              onChanged: (val) => skillProvider.toggleTheme(val),
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 3. Dropdown Bahasa Default
                          ListTile(
                            leading: const Icon(Icons.language_rounded, color: Colors.blue),
                            title: Text(skillProvider.translate('main_language'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(skillProvider.translate('language_desc'), style: const TextStyle(fontSize: 11)),
                            trailing: DropdownButton<String>(
                              value: skillProvider.defaultLang,
                              underline: const SizedBox(),
                              borderRadius: BorderRadius.circular(16),
                              items: const [
                                DropdownMenuItem(value: 'id', child: Text('Indonesia (ID)', style: TextStyle(fontSize: 12))),
                                DropdownMenuItem(value: 'en', child: Text('English (EN)', style: TextStyle(fontSize: 12))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  skillProvider.updateDefaultLang(val);
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(skillProvider.translate('lang_changed', args: [val.toUpperCase()])),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 4. Pengaturan Teks (FontSize)
                          ListTile(
                            leading: const Icon(Icons.text_format_rounded, color: Colors.blueGrey),
                            title: Text(skillProvider.translate('text_size') == 'text_size' ? (skillProvider.defaultLang == 'id' ? 'Ukuran Teks' : 'Text Size') : skillProvider.translate('text_size'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(skillProvider.translate('adjust_text_size') == 'adjust_text_size' ? (skillProvider.defaultLang == 'id' ? 'Ubah ukuran font aplikasi' : 'Change app font size') : skillProvider.translate('adjust_text_size'), style: const TextStyle(fontSize: 11)),
                            trailing: Consumer<ProgressProvider>(
                              builder: (context, progressProv, child) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.text_decrease),
                                      onPressed: progressProv.fontSize > 10.0
                                          ? () => progressProv.updateFontSize(progressProv.fontSize - 2.0)
                                          : null,
                                    ),
                                    Text('${progressProv.fontSize.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.text_increase),
                                      onPressed: progressProv.fontSize < 30.0
                                          ? () => progressProv.updateFontSize(progressProv.fontSize + 2.0)
                                          : null,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                          
                          // 5. Pengaturan Tampilan (View Mode)
                          ListTile(
                            leading: const Icon(Icons.dashboard_customize_rounded, color: Colors.teal),
                            title: Text(skillProvider.translate('layout_view') == 'layout_view' ? (skillProvider.defaultLang == 'id' ? 'Tampilan Tata Letak' : 'Layout View') : skillProvider.translate('layout_view'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text(skillProvider.translate('change_view_mode') == 'change_view_mode' ? (skillProvider.defaultLang == 'id' ? 'Ubah mode List/Grid' : 'Change List/Grid mode') : skillProvider.translate('change_view_mode'), style: const TextStyle(fontSize: 11)),
                            trailing: Consumer<ProgressProvider>(
                              builder: (context, progressProv, child) {
                                return DropdownButton<String>(
                                  value: progressProv.viewMode,
                                  underline: const SizedBox(),
                                  borderRadius: BorderRadius.circular(16),
                                  items: const [
                                    DropdownMenuItem(value: 'List', child: Text('List View', style: TextStyle(fontSize: 12))),
                                    DropdownMenuItem(value: 'Grid', child: Text('Grid View', style: TextStyle(fontSize: 12))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      progressProv.updateViewMode(val);
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // D. TOMBOL LOGOUT PREMIUM
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        foregroundColor: theme.colorScheme.error,
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.03),
                      ),
                      onPressed: () => _showLogoutDialog(context, authProvider, theme),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        skillProvider.translate('logout_active_session'),
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: theme.hintColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
