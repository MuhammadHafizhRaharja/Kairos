import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/skill_provider.dart';
import '../models/resource.dart';
import '../models/skill.dart';
import '../providers/progress_provider.dart';
import '../widgets/resource_bookmark_card.dart';

/// Halaman Modul Resource (Referensi & Materi Belajar) yang sangat estetis dan fungsional.
/// Menyediakan manajemen materi belajar (CRUD) yang terintegrasi dengan database lokal
/// serta kontrol Shared Preferences untuk preferensi pengguna.
class ResourceScreen extends StatefulWidget {
  const ResourceScreen({super.key});

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Kategori materi yang didukung
  final List<String> _categories = [
    'Video',
    'Artikel',
    'Buku',
    'Dokumentasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillProvider>();
    final theme = Theme.of(context);
    final selectedFilter = provider.selectedFilter;

    // Filter resources based on type
    final materiList = provider.resources
        .where((r) => r.resourceType == 'materi')
        .toList();
    final referensiList = provider.resources
        .where((r) => r.resourceType == 'referensi')
        .toList();

    // Filter materi berdasarkan status tab
    final filteredMateri = materiList.where((resource) {
      if (selectedFilter == 'Semua') return true;
      if (selectedFilter == 'Belum Dibaca') return resource.status == 0;
      if (selectedFilter == 'Sedang Dibaca') return resource.status == 1;
      if (selectedFilter == 'Selesai') return resource.status == 2;
      return true;
    }).toList();

    // Hitung statistik untuk tab Materi Belajar
    final totalMateri = materiList.length;
    final unreadMateri = materiList.where((r) => r.status == 0).length;
    final readingMateri = materiList.where((r) => r.status == 1).length;
    final completedMateri = materiList.where((r) => r.status == 2).length;

    double materiProgress = 0.0;
    if (totalMateri > 0) {
      materiProgress =
          ((completedMateri * 1.0) + (readingMateri * 0.5)) / totalMateri;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          provider.translate('learning_resources'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.menu_book_rounded, size: 20),
              text: provider.translate('study_materials'),
            ),
            Tab(
              icon: const Icon(Icons.bookmark_added_rounded, size: 20),
              text: provider.translate('additional_references'),
            ),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: MATERI BELAJAR
            ListView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 120,
              ),
              children: [
                _buildStatsBanner(
                  theme,
                  provider,
                  totalMateri,
                  completedMateri,
                  readingMateri,
                  unreadMateri,
                  materiProgress,
                ),
                const SizedBox(height: 16),
                _buildFilterChips(theme, provider),
                const SizedBox(height: 16),
                filteredMateri.isEmpty
                    ? _buildEmptyState(theme, selectedFilter)
                    : (context.watch<ProgressProvider>().viewMode == 'Grid'
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: filteredMateri.length,
                              itemBuilder: (context, index) {
                                return _buildResourceCard(
                                  context,
                                  provider,
                                  theme,
                                  filteredMateri[index],
                                  isGrid: true,
                                );
                              },
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredMateri.length,
                              itemBuilder: (context, index) {
                                return _buildResourceCard(
                                  context,
                                  provider,
                                  theme,
                                  filteredMateri[index],
                                  isGrid: false,
                                );
                              },
                            )),
              ],
            ),

            // TAB 2: REFERENSI TAMBAHAN
            ListView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 120,
              ),
              children: [
                referensiList.isEmpty
                    ? _buildEmptyStateForReferences(theme)
                    : (context.watch<ProgressProvider>().viewMode == 'Grid'
                          ? GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: referensiList.length,
                              itemBuilder: (context, index) {
                                return _buildResourceCard(
                                  context,
                                  provider,
                                  theme,
                                  referensiList[index],
                                  isGrid: true,
                                );
                              },
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: referensiList.length,
                              itemBuilder: (context, index) {
                                return _buildResourceCard(
                                  context,
                                  provider,
                                  theme,
                                  referensiList[index],
                                  isGrid: false,
                                );
                              },
                            )),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: 80.0,
        ), // Agar tidak tertutup BottomNavBar
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            if (_tabController.index == 0) {
              _showAddEditResourceBottomSheet(
                context,
                provider,
                type: 'materi',
              );
            } else {
              _showAddEditResourceBottomSheet(
                context,
                provider,
                type: 'referensi',
              );
            }
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _tabController.index == 0
                ? provider.translate('add_material')
                : provider.translate('add_reference'),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }

  /// Membuat visualisasi statistik ringkas modul Resource
  Widget _buildStatsBanner(
    ThemeData theme,
    SkillProvider provider,
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
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
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
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  color: const Color(0xFF4CAF50), // Hijau Resource
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF4CAF50),
                ),
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
                  provider.translate('learning_progress'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat(
                      provider.translate('total'),
                      total.toString(),
                      theme,
                    ),
                    _buildMiniStat(
                      provider.translate('completed'),
                      completed.toString(),
                      theme,
                      color: const Color(0xFF4CAF50),
                    ),
                    _buildMiniStat(
                      provider.translate('reading'),
                      reading.toString(),
                      theme,
                      color: const Color(0xFFFF9800),
                    ),
                    _buildMiniStat(
                      provider.translate('unread'),
                      unread.toString(),
                      theme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
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
        Text(label, style: TextStyle(fontSize: 9.5, color: theme.hintColor)),
      ],
    );
  }

  /// Chips untuk filter status resources
  Widget _buildFilterChips(ThemeData theme, SkillProvider provider) {
    final filters = [
      {'key': 'Semua', 'label': provider.translate('filter_all')},
      {'key': 'Belum Dibaca', 'label': provider.translate('filter_unread')},
      {'key': 'Sedang Dibaca', 'label': provider.translate('filter_reading')},
      {'key': 'Selesai', 'label': provider.translate('filter_completed')},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final filterKey = f['key']!;
          final filterLabel = f['label']!;
          final isSelected = provider.selectedFilter == filterKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filterLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (val) {
                if (val) {
                  provider.updateSelectedFilter(filterKey);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String selectedFilter) {
    return Consumer<SkillProvider>(
      builder: (context, skillProv, _) {
        String localizedFilter = selectedFilter;
        if (selectedFilter == 'Belum Dibaca') {
          localizedFilter = skillProv.translate('filter_unread');
        } else if (selectedFilter == 'Sedang Dibaca') {
          localizedFilter = skillProv.translate('filter_reading');
        } else if (selectedFilter == 'Selesai') {
          localizedFilter = skillProv.translate('filter_completed');
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 72,
                color: theme.hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                skillProv.translate('no_material'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedFilter == 'Semua'
                    ? skillProv.translate('no_material_desc')
                    : skillProv.translate(
                        'no_material_status',
                        args: [localizedFilter],
                      ),
                style: TextStyle(color: theme.hintColor, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tampilan jika referensi kosong
  Widget _buildEmptyStateForReferences(ThemeData theme) {
    return Consumer<SkillProvider>(
      builder: (context, skillProv, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.bookmark_border_rounded,
                size: 72,
                color: theme.hintColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                skillProv.translate('no_reference'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                skillProv.translate('no_reference_desc'),
                style: TextStyle(color: theme.hintColor, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Kartu referensi yang sangat premium dengan swipe & gesture lengkap
  Widget _buildResourceCard(
    BuildContext context,
    SkillProvider provider,
    ThemeData theme,
    Resource resource, {
    bool isGrid = false,
  }) {
    Skill? linkedSkill;
    if (resource.skillId != null) {
      try {
        linkedSkill = provider.skills.firstWhere(
          (s) => s.id == resource.skillId,
        );
      } catch (_) {
        linkedSkill = null;
      }
    }

    return ResourceBookmarkCard(
      resource: resource,
      provider: provider,
      linkedSkill: linkedSkill,
      isGrid: isGrid,
      onEdit: () {
        _showAddEditResourceBottomSheet(
          context,
          provider,
          resource: resource,
          type: resource.resourceType,
        );
      },
      onDelete: () {
        _confirmDelete(context, provider, resource, theme);
      },
      onStatusChangeRequested: () {
        final nextStatus = (resource.status + 1) % 3;
        final updatedResource = Resource(
          id: resource.id,
          userId: resource.userId,
          skillId: resource.skillId,
          title: resource.title,
          url: resource.url,
          description: resource.description,
          category: resource.category,
          status: nextStatus,
          resourceType: resource.resourceType,
          createdAt: resource.createdAt,
        );
        provider.updateResource(updatedResource);

        String statusWord = nextStatus == 0
            ? provider.translate('status_unread_icon')
            : (nextStatus == 1
                  ? provider.translate('status_reading_icon')
                  : provider.translate('status_completed_icon'));
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.translate(
                'status_changed',
                args: [resource.title, statusWord],
              ),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }



  /// Dialog konfirmasi hapus manual dari PopupMenu
  void _confirmDelete(
    BuildContext context,
    SkillProvider provider,
    Resource resource,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          provider.translate('delete_confirm_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          provider.translate('delete_confirm_desc', args: [resource.title]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(provider.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (resource.id != null) {
                provider.deleteResource(resource.id!);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.translate(
                        'deleted_success',
                        args: [resource.title],
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(provider.translate('delete')),
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
    String? type,
  }) {
    final theme = Theme.of(context);
    final titleController = TextEditingController(text: resource?.title ?? '');
    final urlController = TextEditingController(text: resource?.url ?? '');
    final descController = TextEditingController(
      text: resource?.description ?? '',
    );

    final resType = resource?.resourceType ?? type ?? 'materi';
    final isReference = resType == 'referensi';

    String currentCategory = resource?.category ?? 'Lainnya';
    int currentStatus = resource?.status ?? 0;
    int? currentSkillId = resource?.skillId;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        // Title header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              resource == null
                                  ? (isReference
                                        ? provider.translate('add_reference')
                                        : provider.translate('add_material'))
                                  : (isReference
                                        ? '${provider.translate('edit')} ${provider.translate('referensi')}'
                                        : '${provider.translate('edit')} ${provider.translate('materi')}'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
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
                            labelText: isReference
                                ? (provider.defaultLang == 'id'
                                      ? 'Judul Referensi'
                                      : 'Reference Title')
                                : (provider.defaultLang == 'id'
                                      ? 'Judul Materi'
                                      : 'Material Title'),
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return provider.defaultLang == 'id'
                                  ? 'Judul tidak boleh kosong'
                                  : 'Title cannot be empty';
                            }
                            return null;
                          },
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),

                        // Input Tautan/URL
                        TextFormField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: isReference
                                ? (provider.defaultLang == 'id'
                                      ? 'Link / URL Referensi'
                                      : 'Reference Link / URL')
                                : (provider.defaultLang == 'id'
                                      ? 'Link / URL Materi'
                                      : 'Material Link / URL'),
                            prefixIcon: const Icon(Icons.link_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.attach_file_rounded),
                              tooltip: provider.defaultLang == 'id'
                                  ? 'Pilih File Lokal'
                                  : 'Pick Local File',
                              onPressed: () async {
                                final result = await FilePicker.pickFiles(
                                  type: FileType.any,
                                );
                                if (result != null && result.files.single.path != null) {
                                  urlController.text = 'file://${result.files.single.path}';
                                }
                              },
                            ),
                            hintText: 'https://...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return provider.defaultLang == 'id'
                                  ? 'Link tidak boleh kosong'
                                  : 'Link cannot be empty';
                            }
                            if (!val.trim().startsWith('http://') &&
                                !val.trim().startsWith('https://') &&
                                !val.trim().startsWith('file://')) {
                              return provider.defaultLang == 'id'
                                  ? 'Gunakan format URL yang valid (dimulai http/https/file)'
                                  : 'Use valid URL format (starting with http/https/file)';
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
                            labelText: provider.defaultLang == 'id'
                                ? 'Catatan / Deskripsi Singkat (Opsional)'
                                : 'Notes / Short Description (Optional)',
                            prefixIcon: const Icon(Icons.note_alt_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 20),

                        // Chip Pilihan Kategori
                        Text(
                          provider.defaultLang == 'id'
                              ? 'Kategori Konten'
                              : 'Content Category',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                                  label: Text(
                                    _getLocalizedCategoryName(
                                      cat,
                                      provider.defaultLang,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
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

                        // Chip Pilihan Status (Hanya untuk materi)
                        if (!isReference) ...[
                          Text(
                            provider.defaultLang == 'id'
                                ? 'Status Membaca'
                                : 'Reading Status',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildChoiceStatusChip(
                                0,
                                provider.translate('status_unread_icon'),
                                currentStatus,
                                (status) {
                                  setSheetState(() => currentStatus = status);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildChoiceStatusChip(
                                1,
                                provider.translate('status_reading_icon'),
                                currentStatus,
                                (status) {
                                  setSheetState(() => currentStatus = status);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildChoiceStatusChip(
                                2,
                                provider.translate('status_completed_icon'),
                                currentStatus,
                                (status) {
                                  setSheetState(() => currentStatus = status);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Relasi ke Skill (Keahlian)
                        Text(
                          provider.defaultLang == 'id'
                              ? 'Hubungkan ke Keahlian (Skill)'
                              : 'Connect to Skill',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        provider.skills.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        provider.defaultLang == 'id'
                                            ? 'Belum ada keahlian terdaftar. Buat keahlian terlebih dahulu di tab Keahlian untuk menghubungkan referensi.'
                                            : 'No skills registered yet. Create a skill in the Skills tab first to connect a reference.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int?>(
                                    value: currentSkillId,
                                    isExpanded: true,
                                    hint: Text(
                                      provider.defaultLang == 'id'
                                          ? 'Pilih keahlian terkait (Opsional)'
                                          : 'Select related skill (Optional)',
                                      style: const TextStyle(fontSize: 13.5),
                                    ),
                                    onChanged: (int? newValue) {
                                      setSheetState(() {
                                        currentSkillId = newValue;
                                      });
                                    },
                                    items: [
                                      DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text(
                                          provider.defaultLang == 'id'
                                              ? 'Tidak dihubungkan'
                                              : 'Not connected',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                      ...provider.skills.map((Skill skill) {
                                        return DropdownMenuItem<int?>(
                                          value: skill.id,
                                          child: Text(
                                            skill.name,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                        const SizedBox(height: 24),

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
                                  status: isReference ? 0 : currentStatus,
                                  resourceType: resType,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.defaultLang == 'id'
                                          ? '${isReference ? "Referensi" : "Materi"} "$title" berhasil ditambahkan! 🚀'
                                          : '${isReference ? "Reference" : "Material"} "$title" successfully added! 🚀',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                final updated = Resource(
                                  id: resource.id,
                                  userId: resource.userId,
                                  skillId: currentSkillId,
                                  title: title,
                                  url: url,
                                  description: desc,
                                  category: currentCategory,
                                  status: isReference ? 0 : currentStatus,
                                  resourceType: resource.resourceType,
                                  createdAt: resource.createdAt,
                                );
                                provider.updateResource(updated);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.defaultLang == 'id'
                                          ? '${isReference ? "Referensi" : "Materi"} "$title" berhasil diperbarui! 📝'
                                          : '${isReference ? "Reference" : "Material"} "$title" successfully updated! 📝',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              Navigator.pop(sheetCtx);
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(
                            resource == null
                                ? (isReference
                                      ? (provider.defaultLang == 'id'
                                            ? 'Simpan Referensi'
                                            : 'Save Reference')
                                      : (provider.defaultLang == 'id'
                                            ? 'Simpan Materi'
                                            : 'Save Material'))
                                : (isReference
                                      ? (provider.defaultLang == 'id'
                                            ? 'Perbarui Referensi'
                                            : 'Update Reference')
                                      : (provider.defaultLang == 'id'
                                            ? 'Perbarui Materi'
                                            : 'Update Material')),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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


  Widget _buildChoiceStatusChip(
    int statusValue,
    String label,
    int selectedValue,
    Function(int) onSelected,
  ) {
    final isSelected = selectedValue == statusValue;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (val) {
        if (val) onSelected(statusValue);
      },
    );
  }

  String _getLocalizedCategoryName(String cat, String lang) {
    if (lang == 'en') {
      switch (cat) {
        case 'Artikel':
          return 'Article';
        case 'Buku':
          return 'Book';
        case 'Dokumentasi':
          return 'Documentation';
        case 'Lainnya':
          return 'Others';
        default:
          return cat;
      }
    }
    return cat;
  }
}
