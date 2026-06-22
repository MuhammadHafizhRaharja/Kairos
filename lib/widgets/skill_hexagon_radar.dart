import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/skill_category.dart';
import '../models/skill.dart';

/// Custom Widget: Heksagon Radar Chart untuk Modul Keahlian.
/// Memenuhi kriteria Assessment 3:
/// 1. Custom Widget: Memiliki fungsionalitas internal (rotasi & interaksi tap select).
/// 2. Art & Gesture: Menggunakan CustomPainter dan GestureDetector untuk interaksi sentuhan.
/// 3. Theme & UX: Menyesuaikan mode terang/gelap secara otomatis dengan animasi pemuatan awal.
class SkillHexagonRadar extends StatefulWidget {
  final List<Map<String, dynamic>> categoryData; // Berisi {'category': SkillCategory, 'skills': List<Skill>, 'progress': double}

  const SkillHexagonRadar({
    super.key,
    required this.categoryData,
  });

  @override
  State<SkillHexagonRadar> createState() => _SkillHexagonRadarState();
}

class _SkillHexagonRadarState extends State<SkillHexagonRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  double _rotationAngle = 0.0;
  double _lastDragAngle = 0.0;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    // Default memilih kategori pertama jika tersedia
    if (widget.categoryData.isNotEmpty) {
      _selectedIndex = 0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SkillHexagonRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex == null && widget.categoryData.isNotEmpty) {
      setState(() {
        _selectedIndex = 0;
      });
    } else if (widget.categoryData.isEmpty) {
      setState(() {
        _selectedIndex = null;
      });
    } else if (_selectedIndex != null && _selectedIndex! >= widget.categoryData.length) {
      setState(() {
        _selectedIndex = widget.categoryData.length - 1;
      });
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pos = details.localPosition;
    _lastDragAngle = atan2(pos.dy - center.dy, pos.dx - center.dx);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final pos = details.localPosition;
    final currentAngle = atan2(pos.dy - center.dy, pos.dx - center.dx);

    // Hitung perbedaan sudut untuk putaran yang mulus
    double delta = currentAngle - _lastDragAngle;
    
    // Normalisasi delta agar tidak meloncat saat berpindah kuadran (+pi ke -pi)
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;

    setState(() {
      _rotationAngle += delta;
      _lastDragAngle = currentAngle;
    });
  }

  void _onTapDown(TapDownDetails details, Size size) {
    if (widget.categoryData.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final pos = details.localPosition;
    final tapAngle = atan2(pos.dy - center.dy, pos.dx - center.dx);
    final distance = sqrt(pow(pos.dx - center.dx, 2) + pow(pos.dy - center.dy, 2));

    // Jangan pilih jika ketukan terlalu dekat ke pusat (dalam radius 15px)
    if (distance < 15) return;

    int numAxes = 6; // Tetap 6 untuk Heksagon Radar
    int closestIndex = -1;
    double minDiff = double.infinity;

    for (int i = 0; i < numAxes; i++) {
      // Sudut sumbu ke-i dengan mempertimbangkan rotasi
      double axisAngle = i * (2 * pi / numAxes) - pi / 2 + _rotationAngle;
      
      // Hitung selisih sudut terkecil
      double diff = (tapAngle - axisAngle).abs() % (2 * pi);
      if (diff > pi) diff = 2 * pi - diff;

      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    // Hanya pilih jika dekat dengan sumbu (selisih < 35 derajat)
    if (closestIndex != -1 && minDiff < (35 * pi / 180)) {
      // Petakan kembali dari 6 sumbu ke indeks data yang valid
      if (closestIndex < widget.categoryData.length) {
        if (_selectedIndex != closestIndex) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = closestIndex;
          });
        }
      } else {
        // Jika sumbu kosong diklik, hilangkan seleksi atau tetap
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.categoryData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              Icon(Icons.radar_rounded, size: 48, color: theme.hintColor.withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text(
                'Belum ada kategori untuk radar',
                style: TextStyle(color: theme.hintColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    // Menyiapkan label, nilai, dan warna untuk 6 sumbu heksagon
    final List<String> axisLabels = [];
    final List<double> axisValues = [];
    final List<Color> axisColors = [];

    for (int i = 0; i < 6; i++) {
      if (i < widget.categoryData.length) {
        final data = widget.categoryData[i];
        final SkillCategory cat = data['category'];
        axisLabels.add(cat.name);
        axisValues.add(data['progress'] as double);
        axisColors.add(Color(cat.colorValue));
      } else {
        axisLabels.add('Belum Ada');
        axisValues.add(0.0);
        axisColors.add(Colors.grey);
      }
    }

    return Column(
      children: [
        // Container Heksagon Radar Chart
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double height = 230;
            final size = Size(width, height);

            return GestureDetector(
              onPanStart: (details) => _onPanStart(details, size),
              onPanUpdate: (details) => _onPanUpdate(details, size),
              onTapDown: (details) => _onTapDown(details, size),
              child: Container(
                width: width,
                height: height,
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _RadarPainter(
                        labels: axisLabels,
                        values: axisValues,
                        colors: axisColors,
                        rotationAngle: _rotationAngle,
                        scale: _scaleAnimation.value,
                        selectedIndex: _selectedIndex,
                        isDark: isDark,
                        themePrimary: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Detail Kategori Terpilih dengan mikro-animasi card
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedIndex != null && _selectedIndex! < widget.categoryData.length
              ? _buildSelectedCategoryDetails(widget.categoryData[_selectedIndex!])
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSelectedCategoryDetails(Map<String, dynamic> data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final SkillCategory category = data['category'];
    final List<Skill> skills = data['skills'];
    final double progress = data['progress'];
    final color = Color(category.colorValue);

    // Kriteria Mastery level
    String masteryLevel = 'Pemula';
    Color masteryColor = Colors.blue;
    if (skills.isEmpty) {
      masteryLevel = 'Kosong';
      masteryColor = Colors.grey;
    } else if (progress >= 1.0) {
      masteryLevel = 'Master 🏆';
      masteryColor = Colors.amber;
    } else if (progress >= 0.8) {
      masteryLevel = 'Ahli';
      masteryColor = Colors.redAccent;
    } else if (progress >= 0.4) {
      masteryLevel = 'Menengah';
      masteryColor = Colors.purple;
    }

    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[950] : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nama Kategori, Ikon, & Badge Tingkat Penguasaan
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(
                  _getIconData(category.icon),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${skills.length} keahlian terdaftar',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: masteryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: masteryColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  masteryLevel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: masteryColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),

          // Progres Rerata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rata-rata Penguasaan:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
            ),
          ),

          // Sub-Skills List (Preview)
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Daftar Keahlian:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.take(3).map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    '${s.name} (Lvl ${s.level})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'translate':
        return Icons.translate;
      case 'music_note':
        return Icons.music_note;
      case 'book':
        return Icons.book;
      case 'brush':
        return Icons.brush;
      case 'sports_basketball':
        return Icons.sports_basketball;
      default:
        return Icons.star;
    }
  }
}

/// CustomPainter untuk menggambar heksagon radar secara dinamis & estetis.
class _RadarPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final List<Color> colors;
  final double rotationAngle;
  final double scale;
  final int? selectedIndex;
  final bool isDark;
  final Color themePrimary;

  _RadarPainter({
    required this.labels,
    required this.values,
    required this.colors,
    required this.rotationAngle,
    required this.scale,
    required this.selectedIndex,
    required this.isDark,
    required this.themePrimary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2.0 - 42.0;
    const int numAxes = 6;

    // Paint untuk jaring heksagon (grid background)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Paint untuk sumbu utama radial
    final axisPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 1. Menggambar Jaring Heksagon Konsentris (5 Tingkatan: 20%, 40%, 60%, 80%, 100%)
    for (int step = 1; step <= 5; step++) {
      final double currentRadius = maxRadius * (step / 5.0);
      final Path path = Path();

      for (int i = 0; i < numAxes; i++) {
        final double angle = i * (2 * pi / numAxes) - pi / 2 + rotationAngle;
        final double x = center.dx + currentRadius * cos(angle);
        final double y = center.dy + currentRadius * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Menggambar Sumbu Radial & Label Text
    for (int i = 0; i < numAxes; i++) {
      final double angle = i * (2 * pi / numAxes) - pi / 2 + rotationAngle;
      final double outerX = center.dx + maxRadius * cos(angle);
      final double outerY = center.dy + maxRadius * sin(angle);

      // Gambar garis sumbu radial
      canvas.drawLine(center, Offset(outerX, outerY), axisPaint);

      // Persiapan penggambaran label teks sumbu
      final String label = labels[i];
      final Color axisColor = colors[i];
      final bool isSelected = selectedIndex == i;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: isSelected
                ? axisColor
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Penempatan teks di luar ujung sumbu dengan penyesuaian kuadran
      final double cosVal = cos(angle);
      final double sinVal = sin(angle);
      final double labelDistance = maxRadius + 14.0;
      final double labelX = center.dx + labelDistance * cosVal;
      final double labelY = center.dy + labelDistance * sinVal;

      double finalX = labelX;
      double finalY = labelY;

      if (cosVal > 0.3) {
        // Kuadran Kanan
        finalX = labelX;
        finalY = labelY - textPainter.height / 2;
      } else if (cosVal < -0.3) {
        // Kuadran Kiri
        finalX = labelX - textPainter.width;
        finalY = labelY - textPainter.height / 2;
      } else {
        // Tengah (Atas / Bawah)
        finalX = labelX - textPainter.width / 2;
        if (sinVal > 0) {
          finalY = labelY;
        } else {
          finalY = labelY - textPainter.height;
        }
      }

      // Render teks
      textPainter.paint(canvas, Offset(finalX, finalY));
    }

    // 3. Menggambar Daerah Polygon Data Kategori
    final Path dataPath = Path();
    final List<Offset> dataPoints = [];

    for (int i = 0; i < numAxes; i++) {
      final double angle = i * (2 * pi / numAxes) - pi / 2 + rotationAngle;
      
      // Ambil nilai progress berskala dengan load animation (scale)
      final double value = values[i] * scale;
      final double currentRadius = maxRadius * value;
      
      final double x = center.dx + currentRadius * cos(angle);
      final double y = center.dy + currentRadius * sin(angle);
      final point = Offset(x, y);

      dataPoints.add(point);

      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Warnai area dalam polygon
    final fillPaint = Paint()
      ..color = themePrimary.withValues(alpha: isDark ? 0.18 : 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Gambar border luar polygon data
    final borderPaint = Paint()
      ..color = themePrimary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(dataPath, borderPaint);

    // 4. Menggambar Dot Penanda Data & Efek Glow pada Vertex Terpilih
    for (int i = 0; i < numAxes; i++) {
      if (i >= values.length) continue;
      
      final value = values[i];
      if (value <= 0.0) continue; // Jangan gambar dot jika progresnya 0%

      final double angle = i * (2 * pi / numAxes) - pi / 2 + rotationAngle;
      final double currentRadius = maxRadius * value * scale;
      final double x = center.dx + currentRadius * cos(angle);
      final double y = center.dy + currentRadius * sin(angle);
      final Offset point = Offset(x, y);

      final Color axisColor = colors[i];
      final bool isSelected = selectedIndex == i;

      if (isSelected) {
        // Efek Glow / Halo di sekitar vertex yang terpilih
        final glowPaint = Paint()
          ..color = axisColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(point, 9.0, glowPaint);

        // Dot Luar
        final dotOuterPaint = Paint()
          ..color = axisColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 5.5, dotOuterPaint);

        // Dot Dalam (Putih)
        final dotInnerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 2.0, dotInnerPaint);
      } else {
        // Dot Biasa
        final dotPaint = Paint()
          ..color = themePrimary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return rotationAngle != oldDelegate.rotationAngle ||
        scale != oldDelegate.scale ||
        selectedIndex != oldDelegate.selectedIndex ||
        isDark != oldDelegate.isDark ||
        values != oldDelegate.values;
  }
}
