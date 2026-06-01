import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/skill_provider.dart';
import '../models/resource.dart';
import '../models/skill.dart';

/// Halaman Modul Resource (Referensi & Materi Belajar) yang sangat estetis dan fungsional.
/// Menyediakan manajemen materi belajar (CRUD) yang terintegrasi dengan database lokal
/// serta kontrol Shared Preferences untuk preferensi pengguna.
class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  String _selectedFilter = 'Semua'; // Filter tab: Semua, Belum Dibaca, Sedang Dibaca, Selesai
  bool _isPrefExpanded = false; // Status expand/collapse setelan preferensi

  // Kategori materi yang didukung
  final List<String> _categories = ['Video', 'Artikel', 'Buku', 'Dokumentasi', 'Lainnya'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);

    // Filter resources berdasarkan status
    final filteredResources = provider.resources.where((resource) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Belum Dibaca') return resource.status == 0;
      if (_selectedFilter == 'Sedang Dibaca') return resource.status == 1;
      if (_selectedFilter == 'Selesai') return resource.status == 2;
      return true;
    }).toList();

    // Hitung statistik untuk header
    final totalCount = provider.resources.length;
    final unreadCount = provider.resources.where((r) => r.status == 0).length;
    final readingCount = provider.resources.where((r) => r.status == 1).length;
    final completedCount = provider.resources.where((r) => r.status == 2).length;

    // Hitung persentase progres untuk ring tengah
    double resourceProgress = 0.3;
    if (provider.isNotificationEnabled) resourceProgress += 0.1;
    if (provider.defaultLang == 'id') resourceProgress += 0.1;
    if (totalCount > 0) {
      resourceProgress += (completedCount / totalCount) * 0.45;
    }
    resourceProgress = resourceProgress.clamp(0.15, 0.95);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Materi & Referensi',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
                children: [
                  // 1. STATS BANNER
                  _buildStatsBanner(theme, totalCount, completedCount, readingCount, unreadCount, resourceProgress),
                  const SizedBox(height: 16),

                  // 2. SETELAN PREFERENSI (COLLAPSIBLE CARD)
                  _buildCollapsiblePrefsCard(context, provider, theme),
                  const SizedBox(height: 24),

                  // 3. FILTER TAB CHIPS
                  _buildFilterChips(theme),
                  const SizedBox(height: 16),

                  // 4. RESOURCE LIST / EMPTY STATE
                  filteredResources.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredResources.length,
                          itemBuilder: (context, index) {
                            final resource = filteredResources[index];
                            return _buildResourceCard(context, provider, theme, resource);
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Agar tidak tertutup BottomNavBar
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEditResourceBottomSheet(context, provider),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah Materi / Referensi'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Membuat visualisasi statistik ringkas modul Resource
  Widget _buildStatsBanner(
    ThemeData theme,
    int total,
    int completed,
    int reading,
    int unread,
    double progressPercent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Radial progress ring kecil
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  value: progressPercent,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  color: const Color(0xFF4CAF50), // Hijau Resource
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4CAF50)),
              ),
            ],
          ),
          const SizedBox(width: 18),
          // Ringkasan Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progres Pembelajaran',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('Total', total.toString(), theme),
                    _buildMiniStat('Selesai', completed.toString(), theme, color: const Color(0xFF4CAF50)),
                    _buildMiniStat('Membaca', reading.toString(), theme, color: const Color(0xFFFF9800)),
                    _buildMiniStat('Unread', unread.toString(), theme),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, ThemeData theme, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 9.5, color: theme.hintColor),
        ),
      ],
    );
  }

  /// Dropdown preferensi pengaturan collapsible
  Widget _buildCollapsiblePrefsCard(BuildContext context, SkillProvider provider, ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Header Tappable
          ListTile(
            onTap: () {
              setState(() {
                _isPrefExpanded = !_isPrefExpanded;
              });
            },
            leading: Icon(Icons.settings_suggest_rounded, color: theme.colorScheme.primary),
            title: const Text(
              'Preferensi & Setelan Referensi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            subtitle: Text(
              _isPrefExpanded ? 'Sembunyikan pengaturan cepat' : 'Tampilkan pengaturan notifikasi & bahasa',
              style: TextStyle(fontSize: 10.5, color: theme.hintColor),
            ),
            trailing: Icon(
              _isPrefExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  // Switch Notifikasi
                  SwitchListTile(
                    title: const Text('Notifikasi Belajar Harian', style: TextStyle(fontSize: 12.5)),
                    subtitle: const Text('Kirim pengingat belajar berkala', style: TextStyle(fontSize: 10)),
                    value: provider.isNotificationEnabled,
                    onChanged: (val) {
                      provider.toggleNotification(val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Notifikasi belajar aktif! 🔔' : 'Notifikasi belajar nonaktif! 🔕'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  // Bahasa utama
                  ListTile(
                    title: const Text('Bahasa Utama Konten', style: TextStyle(fontSize: 12.5)),
                    subtitle: const Text('Bahasa rujukan untuk artikel/materi', style: TextStyle(fontSize: 10)),
                    trailing: DropdownButton<String>(
                      value: provider.defaultLang,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          provider.updateDefaultLang(newValue);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bahasa rujukan diubah ke: ${newValue.toUpperCase()} 🌐'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'id', child: Text('Indonesia (ID)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'en', child: Text('English (EN)', style: TextStyle(fontSize: 12))),
                        DropdownMenuItem(value: 'jp', child: Text('日本語 (JP)', style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isPrefExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  /// Chips untuk filter status resources
  Widget _buildFilterChips(ThemeData theme) {
    final filters = ['Semua', 'Belum Dibaca', 'Sedang Dibaca', 'Selesai'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tampilan jika filter kosong
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.auto_stories_rounded, size: 72, color: theme.hintColor.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Referensi',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'Semua'
                ? 'Belum ada referensi terdaftar. Tambahkan tautan materi belajar Anda!'
                : 'Tidak ada materi dengan status: $_selectedFilter',
            style: TextStyle(color: theme.hintColor, fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Kartu referensi yang sangat premium dengan swipe & gesture lengkap
  Widget _buildResourceCard(
    BuildContext context,
    SkillProvider provider,
    ThemeData theme,
    Resource resource,
  ) {
    // 1. Cari relasi ke Skill
    Skill? linkedSkill;
    Color skillColor = theme.colorScheme.primary;
    if (resource.skillId != null) {
      try {
        linkedSkill = provider.skills.firstWhere((s) => s.id == resource.skillId);
        final parentCat = provider.categories.firstWhere((c) => c.id == linkedSkill!.categoryId);
        skillColor = Color(parentCat.colorValue);
      } catch (_) {
        linkedSkill = null;
      }
    }

    return Dismissible(
      key: Key('resource_${resource.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Hapus Referensi?', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text('Apakah Anda yakin ingin menghapus "${resource.title}" secara permanen?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        if (resource.id != null) {
          provider.deleteResource(resource.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Materi "${resource.title}" berhasil dihapus'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: GestureDetector(
        // Double Tap Shortcut: Ganti status dengan memutar nilai status 0 -> 1 -> 2 -> 0
        onDoubleTap: () {
          final nextStatus = (resource.status + 1) % 3;
          final updatedResource = Resource(
            id: resource.id,
            skillId: resource.skillId,
            title: resource.title,
            url: resource.url,
            description: resource.description,
            category: resource.category,
            status: nextStatus,
            createdAt: resource.createdAt,
          );
          provider.updateResource(updatedResource);
          
          String statusWord = nextStatus == 0 ? 'Belum Dibaca 💤' : (nextStatus == 1 ? 'Sedang Dibaca 📖' : 'Selesai Dibaca! 🎉');
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${resource.title}" diubah ke: $statusWord'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 1),
            ),
          );
        },
        // Long Press Shortcut: langsung edit bottom sheet
        onLongPress: () => _showAddEditResourceBottomSheet(context, provider, resource: resource),
        child: Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Kategori Icon + Judul + Popup Options
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        _getCategoryIcon(resource.category),
                        color: theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            resource.category,
                            style: TextStyle(fontSize: 10.5, color: theme.hintColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert_rounded, color: theme.hintColor, size: 20),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showAddEditResourceBottomSheet(context, provider, resource: resource);
                        } else if (val == 'delete') {
                          _confirmDelete(context, provider, resource, theme);
                        } else if (val == 'status') {
                          _showStatusQuickSelect(context, provider, resource, theme);
                        }
                      },
                      itemBuilder: (popCtx) => [
                        const PopupMenuItem(value: 'status', child: Row(children: [Icon(Icons.rule_rounded, size: 16), SizedBox(width: 8), Text('Ubah Status', style: TextStyle(fontSize: 12.5))])),
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit Detail', style: TextStyle(fontSize: 12.5))])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, color: Colors.red, size: 16), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12.5))])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Deskripsi jika ada
                if (resource.description.trim().isNotEmpty) ...[
                  Text(
                    resource.description,
                    style: TextStyle(fontSize: 12, color: theme.hintColor, height: 1.3),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                ],

                // Relasi Keahlian (Skill) jika ada
                if (linkedSkill != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: skillColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: skillColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events_rounded, color: skillColor, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Keahlian: ${linkedSkill.name}',
                          style: TextStyle(color: skillColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const Divider(height: 1),
                const SizedBox(height: 10),

                // Baris Bawah: Status Badge + Aksi Tautan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(resource.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(resource.status).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(resource.status),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(resource.status),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _getStatusColor(resource.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Aksi URL
                    Row(
                      children: [
                        // Salin Link
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Salin Tautan',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: resource.url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Tautan disalin ke papan klip! 📋'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        // Launch link
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: resource.url));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Membuka tautan: ${resource.url} (Tautan disalin) 🌐'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text('Buka', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menampilkan menu selection status cepat
  void _showStatusQuickSelect(
    BuildContext context,
    SkillProvider provider,
    Resource resource,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Pilih Status Membaca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              _buildQuickStatusItem(context, provider, resource, 0, 'Belum Dibaca 💤', Colors.grey),
              const Divider(height: 1),
              _buildQuickStatusItem(context, provider, resource, 1, 'Sedang Dibaca 📖', const Color(0xFFFF9800)),
              const Divider(height: 1),
              _buildQuickStatusItem(context, provider, resource, 2, 'Selesai 🏆', const Color(0xFF4CAF50)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatusItem(
    BuildContext context,
    SkillProvider provider,
    Resource resource,
    int targetStatus,
    String label,
    Color color,
  ) {
    final isSelected = resource.status == targetStatus;
    return ListTile(
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        final updated = Resource(
          id: resource.id,
          skillId: resource.skillId,
          title: resource.title,
          url: resource.url,
          description: resource.description,
          category: resource.category,
          status: targetStatus,
          createdAt: resource.createdAt,
        );
        provider.updateResource(updated);
        Navigator.pop(context);
      },
    );
  }

  /// Dialog konfirmasi hapus manual dari PopupMenu
  void _confirmDelete(BuildContext context, SkillProvider provider, Resource resource, ThemeData theme) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hapus Referensi?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "${resource.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (resource.id != null) {
                provider.deleteResource(resource.id!);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Materi "${resource.title}" berhasil dihapus'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// Lembar bottom-sheet formulir Tambah/Edit Referensi belajar
  void _showAddEditResourceBottomSheet(
    BuildContext context,
    SkillProvider provider, {
    Resource? resource,
  }) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: resource?.title ?? '');
    final urlController = TextEditingController(text: resource?.url ?? '');
    final descController = TextEditingController(text: resource?.description ?? '');

    String currentCategory = resource?.category ?? 'Lainnya';
    int currentStatus = resource?.status ?? 0;
    int? currentSkillId = resource?.skillId;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                        // Pill handle drag
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        // Title header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              resource == null ? 'Tambah Materi & Referensi' : 'Edit Materi & Referensi',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(sheetCtx),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Input Judul
                        TextFormField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Judul Materi / Referensi',
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Judul tidak boleh kosong';
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Input Tautan/URL
                        TextFormField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: 'Link / URL Materi',
                            prefixIcon: const Icon(Icons.link_rounded),
                            hintText: 'https://...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Link tidak boleh kosong';
                            if (!val.trim().startsWith('http://') && !val.trim().startsWith('https://')) {
                              return 'Gunakan format URL yang valid (dimulai http/https)';
                            }
                            return null;
                          },
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),

                        // Catatan / Deskripsi singkat
                        TextFormField(
                          controller: descController,
                          decoration: InputDecoration(
                            labelText: 'Catatan / Deskripsi Singkat (Opsional)',
                            prefixIcon: const Icon(Icons.note_alt_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 20),

                        // Chip Pilihan Kategori
                        Text(
                          'Kategori Konten',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = currentCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() {
                                        currentCategory = cat;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Chip Pilihan Status
                        Text(
                          'Status Membaca',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildChoiceStatusChip(0, 'Belum Dibaca 💤', currentStatus, (status) {
                              setSheetState(() => currentStatus = status);
                            }),
                            const SizedBox(width: 8),
                            _buildChoiceStatusChip(1, 'Membaca 📖', currentStatus, (status) {
                              setSheetState(() => currentStatus = status);
                            }),
                            const SizedBox(width: 8),
                            _buildChoiceStatusChip(2, 'Selesai 🏆', currentStatus, (status) {
                              setSheetState(() => currentStatus = status);
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Relasi ke Skill (Keahlian)
                        Text(
                          'Hubungkan ke Keahlian (Skill)',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        provider.skills.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Belum ada keahlian terdaftar. Buat keahlian terlebih dahulu di tab Keahlian untuk menghubungkan referensi.',
                                        style: TextStyle(fontSize: 11, color: Colors.amber),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: currentSkillId,
                                    isExpanded: true,
                                    hint: const Text('Pilih keahlian terkait (Opsional)', style: TextStyle(fontSize: 13.5)),
                                    onChanged: (int? newValue) {
                                      setSheetState(() {
                                        currentSkillId = newValue;
                                      });
                                    },
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Tidak dihubungkan', style: TextStyle(fontSize: 13.5)),
                                      ),
                                      ...provider.skills.map((Skill skill) {
                                        return DropdownMenuItem<int?>(
                                          value: skill.id,
                                          child: Text(skill.name, style: const TextStyle(fontSize: 13.5)),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),

                        // Tombol Aksi Simpan
                        ElevatedButton.icon(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              final title = titleController.text.trim();
                              final url = urlController.text.trim();
                              final desc = descController.text.trim();

                              if (resource == null) {
                                provider.addResource(
                                  skillId: currentSkillId,
                                  title: title,
                                  url: url,
                                  description: desc,
                                  category: currentCategory,
                                  status: currentStatus,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Materi "$title" berhasil ditambahkan! 🚀'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                final updated = Resource(
                                  id: resource.id,
                                  skillId: currentSkillId,
                                  title: title,
                                  url: url,
                                  description: desc,
                                  category: currentCategory,
                                  status: currentStatus,
                                  createdAt: resource.createdAt,
                                );
                                provider.updateResource(updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Referensi "$title" berhasil diperbarui! 📝'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              Navigator.pop(sheetCtx);
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(resource == null ? 'Simpan Materi' : 'Perbarui Materi'),
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

  Widget _buildChoiceStatusChip(int statusValue, String label, int selectedValue, Function(int) onSelected) {
    final isSelected = selectedValue == statusValue;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        if (val) onSelected(statusValue);
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Video':
        return Icons.video_library_rounded;
      case 'Artikel':
        return Icons.article_rounded;
      case 'Buku':
        return Icons.menu_book_rounded;
      case 'Dokumentasi':
        return Icons.description_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 2:
        return const Color(0xFF4CAF50); // Hijau (Selesai)
      case 1:
        return const Color(0xFFFF9800); // Jingga (Membaca)
      default:
        return Colors.grey; // Abu-abu (Belum)
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 2:
        return 'Selesai';
      case 1:
        return 'Sedang Dibaca';
      default:
        return 'Belum Dibaca';
    }
  }
}
