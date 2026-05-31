import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/skill.dart';

/// Widget kustom untuk menampilkan kartu keahlian (Skill).
/// Memiliki logika internal (*stateful*) untuk gesture drag horizontal guna menyesuaikan progres.
/// Dilengkapi dengan mikro-animasi ketika pengguna berhasil meningkatkan level (*Level Up*).
/// Dapat diekspansi untuk menampilkan pintasan progres cepat, deskripsi lengkap, motivasi, dan tombol aksi.
class InteractiveProgressCard extends StatefulWidget {
  final Skill skill;
  final Color themeColor;
  final Function(int newLevel, double newProgress) onProgressChanged;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const InteractiveProgressCard({
    super.key,
    required this.skill,
    required this.themeColor,
    required this.onProgressChanged,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<InteractiveProgressCard> createState() => _InteractiveProgressCardState();
}

class _InteractiveProgressCardState extends State<InteractiveProgressCard> {
  late double _localProgress;
  late int _localLevel;
  bool _isDragging = false;
  bool _triggerLevelUpAnim = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _localProgress = widget.skill.progress;
    _localLevel = widget.skill.level;
  }

  // Menjaga sinkronisasi dengan widget tree jika database berubah dari luar
  @override
  void didUpdateWidget(covariant InteractiveProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _localProgress = widget.skill.progress;
      _localLevel = widget.skill.level;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, double cardWidth) {
    if (cardWidth <= 0) return;
    
    setState(() {
      _isDragging = true;
      // Menghitung delta perubahan berdasarkan lebar widget sesungguhnya
      final double delta = details.delta.dx / cardWidth;
      _localProgress = (_localProgress + delta).clamp(0.0, 1.0);

      // Logika naik level (Level Up) jika mencapai batas progres 100% (1.0)
      if (_localProgress >= 1.0) {
        _localLevel += 1;
        _localProgress = 0.0; // Reset progres untuk tingkat berikutnya
        _triggerLevelUpAnim = true; // Memicu mikro-animasi
        
        // Memberikan feedback haptic sederhana menggunakan default Flutter feedback
        Feedback.forLongPress(context);
      }
    });
  }

  void _handleDragEnd() {
    setState(() {
      _isDragging = false;
    });
    // Memanggil callback untuk menyimpan data secara permanen ke database SQLite
    widget.onProgressChanged(_localLevel, _localProgress);
  }

  void _changeProgressByAmount(double amount) {
    setState(() {
      _localProgress += amount;
      if (_localProgress >= 1.0) {
        _localLevel += 1;
        _localProgress = 0.0;
        _triggerLevelUpAnim = true;
        Feedback.forLongPress(context);
      } else if (_localProgress < 0.0) {
        if (_localLevel > 1) {
          _localLevel -= 1;
          _localProgress = 0.9;
        } else {
          _localProgress = 0.0;
        }
      }
    });
    widget.onProgressChanged(_localLevel, _localProgress);
  }

  void _triggerLevelUp() {
    setState(() {
      _localLevel += 1;
      _localProgress = 0.0;
      _triggerLevelUpAnim = true;
      Feedback.forLongPress(context);
    });
    widget.onProgressChanged(_localLevel, _localProgress);
  }

  String _getMotivationalMessage(int level) {
    if (level <= 1) {
      return "Langkah awal yang luar biasa! Mari terus konsisten berlatih.";
    } else if (level == 2) {
      return "Keahlian dasar sudah terbentuk. Tingkatkan lagi fokus Anda!";
    } else if (level == 3) {
      return "Kemampuan Anda mulai diakui. Anda berada di jalur yang benar.";
    } else if (level == 4) {
      return "Luar biasa! Tinggal sedikit lagi untuk mencapai tingkat Master.";
    } else {
      return "Luar biasa! Anda telah menguasai keahlian ini sepenuhnya! 🏆";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return Card(
          elevation: _isDragging ? 6 : (_isExpanded ? 4 : 2),
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDragging || _isExpanded
                  ? widget.themeColor
                  : widget.themeColor.withValues(alpha: 0.2),
              width: _isDragging || _isExpanded ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    widget.themeColor.withValues(alpha: isDark ? 0.04 : 0.02),
                    widget.themeColor.withValues(alpha: isDark ? 0.12 : 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Atas: Nama Skill & Indikator Level Up Animasi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.skill.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dilacak sejak: ${DateFormat('dd MMM yyyy').format(widget.skill.createdAt)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.hintColor.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Indikator Level dengan Mikro-Animasi Scale & Rotate
                            TweenAnimationBuilder<double>(
                              key: ValueKey('${_localLevel}_$_triggerLevelUpAnim'),
                              tween: Tween<double>(
                                begin: _triggerLevelUpAnim ? 0.7 : 1.0,
                                end: 1.0,
                              ),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              onEnd: () {
                                if (_triggerLevelUpAnim) {
                                  setState(() {
                                    _triggerLevelUpAnim = false;
                                  });
                                }
                              },
                              builder: (context, scale, child) {
                                return Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _triggerLevelUpAnim 
                                          ? Colors.amber 
                                          : widget.themeColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _triggerLevelUpAnim 
                                            ? Colors.orange 
                                            : widget.themeColor.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _triggerLevelUpAnim ? Icons.emoji_events : Icons.trending_up,
                                          size: 14,
                                          color: _triggerLevelUpAnim 
                                              ? Colors.white 
                                              : (isDark ? Colors.white : widget.themeColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Lvl $_localLevel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: _triggerLevelUpAnim 
                                                ? Colors.white 
                                                : (isDark ? Colors.white : widget.themeColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                size: 20,
                                color: theme.hintColor,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'Opsi Keahlian',
                              onPressed: () {
                                setState(() {
                                  _isExpanded = !_isExpanded;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Area Pengukuran Progres Interaktif dengan GESTURE DETECTOR
                    GestureDetector(
                      onHorizontalDragUpdate: (details) => _handleDragUpdate(details, cardWidth),
                      onHorizontalDragEnd: (_) => _handleDragEnd(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Label Progres & Petunjuk Usap
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progres: ${(_localProgress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isDragging ? widget.themeColor : theme.hintColor,
                                ),
                              ),
                              if (_isDragging)
                                Text(
                                  'Menyesuaikan...',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: widget.themeColor,
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.swipe_left_alt, size: 12, color: theme.hintColor.withValues(alpha: 0.7)),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Geser untuk mengubah',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: theme.hintColor.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Bar Progres Kustom
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Stack(
                              children: [
                                // Fill bar progres
                                FractionallySizedBox(
                                  widthFactor: _localProgress > 0.0 ? _localProgress : 0.001,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          widget.themeColor.withValues(alpha: 0.7),
                                          widget.themeColor,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: _isDragging
                                          ? [
                                              BoxShadow(
                                                color: widget.themeColor.withValues(alpha: 0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                                // Handle geser visual kecil saat dragging
                                if (_isDragging && _localProgress > 0.02)
                                  Align(
                                    alignment: Alignment(_localProgress * 2 - 1, 0),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Area ekspansi kustom
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(height: 1),
                          ),
                          
                          // Deskripsi Lengkap
                          if (widget.skill.description.isNotEmpty) ...[
                            Text(
                              'Catatan & Deskripsi:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.themeColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.skill.description,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Motivasi Belajar
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.themeColor.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.themeColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _localLevel >= 5 ? Icons.emoji_events : Icons.lightbulb_outline_rounded,
                                  color: _localLevel >= 5 ? Colors.amber : widget.themeColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _getMotivationalMessage(_localLevel),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Tombol Penyesuaian Progres Cepat
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Aksi Cepat:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.hintColor,
                                ),
                              ),
                              Row(
                                children: [
                                  _buildQuickButton(
                                    icon: Icons.remove,
                                    label: '-10%',
                                    onPressed: () => _changeProgressByAmount(-0.1),
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildQuickButton(
                                    icon: Icons.add,
                                    label: '+10%',
                                    onPressed: () => _changeProgressByAmount(0.1),
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    icon: const Icon(Icons.emoji_events_rounded, size: 12, color: Colors.white),
                                    label: const Text(
                                      'Level Up',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: _triggerLevelUp,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Tombol Aksi (Ubah & Hapus)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(Icons.edit_rounded, size: 16, color: widget.themeColor),
                                label: Text(
                                  'Ubah',
                                  style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                                ),
                                onPressed: widget.onEdit,
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.redAccent),
                                  backgroundColor: Colors.redAccent.withValues(alpha: 0.05),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                                onPressed: widget.onDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                      crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        backgroundColor: color.withValues(alpha: isDark ? 0.15 : 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
