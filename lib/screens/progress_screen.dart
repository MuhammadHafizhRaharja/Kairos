import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/progress_provider.dart';
import '../providers/skill_provider.dart';
import '../models/progress_log.dart';
import '../models/challenge.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Jurnal Progres',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            Consumer<ProgressProvider>(
              builder: (context, provider, child) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.text_decrease),
                      tooltip: 'Perkecil Teks',
                      onPressed: () {
                        if (provider.fontSize > 10.0) {
                          provider.updateFontSize(provider.fontSize - 2.0);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_increase),
                      tooltip: 'Perbesar Teks',
                      onPressed: () {
                        if (provider.fontSize < 30.0) {
                          provider.updateFontSize(provider.fontSize + 2.0);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        provider.viewMode == 'List'
                            ? Icons.grid_view_rounded
                            : Icons.view_list_rounded,
                      ),
                      tooltip: 'Ubah Tampilan',
                      onPressed: () {
                        provider.updateViewMode(
                          provider.viewMode == 'List' ? 'Grid' : 'List',
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Log Aktivitas', icon: Icon(Icons.history_edu)),
              Tab(text: 'Tantangan', icon: Icon(Icons.emoji_events)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ProgressLogsView(),
            _ChallengesView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            title: const Text('Tambah Baru'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Log'),
                      Tab(text: 'Tantangan'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _AddLogForm(),
                        _AddChallengeForm(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLogsView extends StatelessWidget {
  const _ProgressLogsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final logs = provider.logs;
    final fontSize = provider.fontSize;

    if (logs.isEmpty) {
      return const Center(child: Text('Belum ada log aktivitas.'));
    }

    if (provider.viewMode == 'Grid') {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showEditLogDialog(context, log),
              onLongPress: () async {
                final confirm = await _showDeleteConfirmationDialog(context, log.title);
                if (confirm && log.id != null) {
                  provider.deleteProgressLog(log.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log progres berhasil dihapus!')),
                    );
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: fontSize),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(log.date),
                      style: TextStyle(color: Colors.grey, fontSize: fontSize * 0.8),
                    ),
                    const Spacer(),
                    Text(
                      '${log.durationMinutes} Menit',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize * 0.9),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(log.title,
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(log.note, style: TextStyle(fontSize: fontSize * 0.9)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(log.date),
                  style: TextStyle(fontSize: fontSize * 0.8, color: Colors.grey),
                ),
              ],
            ),
            trailing: Chip(
              label: Text('${log.durationMinutes}m',
                  style: TextStyle(fontSize: fontSize * 0.8)),
            ),
            onTap: () => _showEditLogDialog(context, log),
            onLongPress: () async {
              final confirm = await _showDeleteConfirmationDialog(context, log.title);
              if (confirm && log.id != null) {
                provider.deleteProgressLog(log.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log progres berhasil dihapus!')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _ChallengesView extends StatelessWidget {
  const _ChallengesView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final challenges = provider.challenges;
    final fontSize = provider.fontSize;

    if (challenges.isEmpty) {
      return const Center(child: Text('Belum ada tantangan.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isCompleted = challenge.isCompleted == 1;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Checkbox(
              value: isCompleted,
              onChanged: (val) {
                if (val != null) {
                  provider.updateChallenge(
                    challenge.copyWith(isCompleted: val ? 1 : 0),
                  );
                }
              },
            ),
            title: Text(
              challenge.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (challenge.description.isNotEmpty) ...[
                  Text(challenge.description,
                      style: TextStyle(fontSize: fontSize * 0.9)),
                  const SizedBox(height: 4),
                ],
                Text(
                  'Tenggat: ${DateFormat('dd MMM yyyy').format(challenge.targetDate)}',
                  style: TextStyle(
                      fontSize: fontSize * 0.8,
                      color: isCompleted ? Colors.grey : Colors.orange),
                ),
              ],
            ),
            onTap: () => _showEditChallengeDialog(context, challenge),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await _showDeleteConfirmationDialog(context, challenge.title);
                if (confirm && challenge.id != null) {
                  provider.deleteChallenge(challenge.id!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tantangan berhasil dihapus!')),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class _AddLogForm extends StatefulWidget {
  const _AddLogForm();

  @override
  State<_AddLogForm> createState() => _AddLogFormState();
}

class _AddLogFormState extends State<_AddLogForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _durationController = TextEditingController();
  int? _selectedSkillId;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Aktivitas',
                hintText: 'Contoh: Belajar Asynchronous Programming',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Tulis deskripsi progres belajar Anda',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durasi (Menit)',
                hintText: 'Contoh: 30',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Durasi tidak boleh kosong';
                }
                final dur = int.tryParse(value);
                if (dur == null || dur <= 0) {
                  return 'Durasi harus berupa angka positif (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: const InputDecoration(
                labelText: 'Keahlian Terkait',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Global (Tanpa Keahlian)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProgressProvider>().addProgressLog(
                        title: _titleController.text.trim(),
                        note: _noteController.text.trim(),
                        durationMinutes: int.parse(_durationController.text.trim()),
                        date: DateTime.now(),
                        skillId: _selectedSkillId,
                      );
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log progres berhasil ditambahkan!')),
                    );
                  }
                }
              },
              child: const Text('Simpan Log'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChallengeForm extends StatefulWidget {
  const _AddChallengeForm();

  @override
  State<_AddChallengeForm> createState() => _AddChallengeFormState();
}

class _AddChallengeFormState extends State<_AddChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int? _selectedSkillId;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Tantangan',
                hintText: 'Contoh: Selesaikan 3 Coding Challenge',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tantangan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Tulis rincian tantangan Anda',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tenggat: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: const InputDecoration(
                labelText: 'Keahlian Terkait',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Global (Tanpa Keahlian)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<ProgressProvider>().addChallenge(
                        title: _titleController.text.trim(),
                        description: _descController.text.trim(),
                        targetDate: _selectedDate,
                        skillId: _selectedSkillId,
                      );
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tantangan baru berhasil ditambahkan!')),
                    );
                  }
                }
              },
              child: const Text('Simpan Tantangan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditLogForm extends StatefulWidget {
  final ProgressLog log;
  const _EditLogForm({required this.log});

  @override
  State<_EditLogForm> createState() => _EditLogFormState();
}

class _EditLogFormState extends State<_EditLogForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _durationController;
  int? _selectedSkillId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log.title);
    _noteController = TextEditingController(text: widget.log.note);
    _durationController = TextEditingController(text: widget.log.durationMinutes.toString());
    _selectedSkillId = widget.log.skillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Aktivitas',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durasi (Menit)',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Durasi tidak boleh kosong';
                }
                final dur = int.tryParse(value);
                if (dur == null || dur <= 0) {
                  return 'Durasi harus berupa angka positif (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: const InputDecoration(
                labelText: 'Keahlian Terkait',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Global (Tanpa Keahlian)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedLog = widget.log.copyWith(
                    title: _titleController.text.trim(),
                    note: _noteController.text.trim(),
                    durationMinutes: int.parse(_durationController.text.trim()),
                    skillId: _selectedSkillId,
                  );
                  context.read<ProgressProvider>().updateProgressLog(updatedLog);
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Log progres berhasil diperbarui!')),
                    );
                  }
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditChallengeForm extends StatefulWidget {
  final Challenge challenge;
  const _EditChallengeForm({required this.challenge});

  @override
  State<_EditChallengeForm> createState() => _EditChallengeFormState();
}

class _EditChallengeFormState extends State<_EditChallengeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late DateTime _selectedDate;
  int? _selectedSkillId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.challenge.title);
    _descController = TextEditingController(text: widget.challenge.description);
    _selectedDate = widget.challenge.targetDate;
    _selectedSkillId = widget.challenge.skillId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skills = context.watch<SkillProvider>().skills;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Tantangan',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tantangan tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tenggat: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pilih Tanggal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _selectedSkillId,
              decoration: const InputDecoration(
                labelText: 'Keahlian Terkait',
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Global (Tanpa Keahlian)'),
                ),
                ...skills.map((skill) {
                  return DropdownMenuItem<int?>(
                    value: skill.id,
                    child: Text(skill.name),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedSkillId = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedChallenge = widget.challenge.copyWith(
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    targetDate: _selectedDate,
                    skillId: _selectedSkillId,
                  );
                  context.read<ProgressProvider>().updateChallenge(updatedChallenge);
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tantangan berhasil diperbarui!')),
                    );
                  }
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PEMBANTU DIALOG (EDIT & KONFIRMASI HAPUS)
// =============================================================================

void _showEditLogDialog(BuildContext context, ProgressLog log) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Log Aktivitas'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _EditLogForm(log: log),
        ),
      );
    },
  );
}

void _showEditChallengeDialog(BuildContext context, Challenge challenge) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Tantangan'),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: _EditChallengeForm(challenge: challenge),
        ),
      );
    },
  );
}

Future<bool> _showDeleteConfirmationDialog(BuildContext context, String title) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Apakah Anda yakin ingin menghapus "$title"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      ) ??
      false;
}
