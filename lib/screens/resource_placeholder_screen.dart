import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';

/// Halaman Placeholder untuk Modul Resource (Materi & Referensi) milik rekan tim.
/// Mengintegrasikan kontrol Shared Preferences secara fungsional.
class ResourcePlaceholderScreen extends StatelessWidget {
  const ResourcePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Referensi Belajar'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Ilustrasi Mock
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_stories,
                  size: 80,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Referensi & Sumber Belajar',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini dirancang untuk mencatat referensi bacaan, artikel, dan video tutorial yang menunjang perkembangan keahlian Anda.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bagian Integrasi Shared Preferences
            Text(
              'Preferensi Referensi',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Column(
                  children: [
                    // Switch Notifikasi
                    SwitchListTile(
                      title: const Text('Aktifkan Notifikasi Harian'),
                      subtitle: const Text('Kirim pengingat belajar secara berkala'),
                      value: provider.isNotificationEnabled,
                      onChanged: (val) {
                        provider.toggleNotification(val);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val ? 'Notifikasi diaktifkan!' : 'Notifikasi dimatikan!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    // Dropdown Bahasa
                    ListTile(
                      title: const Text('Bahasa Utama Konten'),
                      subtitle: const Text('Bahasa rujukan untuk artikel & materi'),
                      trailing: DropdownButton<String>(
                        value: provider.defaultLang,
                        underline: const SizedBox(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            provider.updateDefaultLang(newValue);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Bahasa utama diubah ke: ${newValue.toUpperCase()}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'id', child: Text('Indonesia (ID)')),
                          DropdownMenuItem(value: 'en', child: Text('English (EN)')),
                          DropdownMenuItem(value: 'jp', child: Text('日本語 (JP)')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Placeholder Info Developer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fitur ini siap dikembangkan lebih lanjut dengan sinkronisasi database lokal untuk materi referensi Anda.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
