import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/skill.dart';

/// Widget kustom untuk menampilkan kartu keahlian (Skill).
/// Memiliki logika internal (*stateful*) untuk gesture drag horizontal guna menyesuaikan progres.
/// Dilengkapi dengan mikro-animasi ketika pengguna berhasil meningkatkan level (*Level Up*).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        return Card(
          elevation: _isDragging ? 6 : 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isDragging
                  ? widget.themeColor
                  : widget.themeColor.withValues(alpha: 0.2),
              width: _isDragging ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onLongPress: widget.onLongPress,
            borderRadius: BorderRadius.circular(16),
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
                          if (widget.skill.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.skill.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.hintColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        const SizedBox(width: 12),
                        IconButton(
                          icon: Icon(Icons.more_vert_rounded, size: 20, color: theme.hintColor),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Opsi Keahlian',
                          onPressed: () => _showSkillOptionsBottomSheet(context),
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
                              widthFactor: _localProgress,
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
              ],
            ),
          ),),
        );
      },
    );
  }

  void _showSkillOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Ubah Keahlian'),
                onTap: () {
                  Navigator.pop(modalContext);
                  widget.onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Hapus Keahlian'),
                onTap: () {
                  Navigator.pop(modalContext);
                  widget.onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
