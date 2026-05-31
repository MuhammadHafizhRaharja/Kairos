import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';

/// Halaman Placeholder untuk Modul Progress (Log Progress & Tantangan) milik rekan tim.
/// Mengintegrasikan kontrol Shared Preferences secara fungsional.
class ProgressPlaceholderScreen extends StatelessWidget {
  const ProgressPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal Progres'),
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
                  colors: [theme.colorScheme.tertiaryContainer, theme.colorScheme.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  Icons.trending_up,
                  size: 80,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Jurnal Progres Harian',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini mencatat perjalanan harian Anda dalam melatih keterampilan, merekam kendala, serta memetakan milestone.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bagian Integrasi Shared Preferences
            Text(
              'Pengaturan Jurnal',
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
                    // Slider Ukuran Font
                    ListTile(
                      title: const Text('Ukuran Font Catatan'),
                      subtitle: Text('${provider.fontSize.toStringAsFixed(1)} pt (Seret slider untuk mencoba)'),
                    ),
                    Slider(
                      value: provider.fontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      label: provider.fontSize.round().toString(),
                      onChanged: (val) {
                        provider.updateFontSize(val);
                      },
                    ),
                    // Teks demonstrasi ukuran font
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Contoh teks log progress harian dengan ukuran terpilih.',
                        style: TextStyle(fontSize: provider.fontSize),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Divider(),
                    // Toggle View Mode (List / Grid)
                    ListTile(
                      title: const Text('Tampilan Log'),
                      subtitle: const Text('Layout ringkasan aktivitas harian'),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'List',
                            label: Text('List'),
                            icon: Icon(Icons.view_list),
                          ),
                          ButtonSegment<String>(
                            value: 'Grid',
                            label: Text('Grid'),
                            icon: Icon(Icons.grid_view),
                          ),
                        ],
                        selected: {provider.viewMode},
                        onSelectionChanged: (Set<String> newSelection) {
                          provider.updateViewMode(newSelection.first);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Layout diubah ke: ${newSelection.first}'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
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
                  Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Fitur ini siap dikembangkan lebih lanjut dengan log harian yang sinkron dengan database SQLite.',
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
