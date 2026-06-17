import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:open_file/open_file.dart';
import '../models/resource.dart';
import '../models/skill.dart';
import '../providers/skill_provider.dart';
import '../screens/webview_screen.dart';

class ResourceBookmarkCard extends StatefulWidget {
  final Resource resource;
  final SkillProvider provider;
  final Skill? linkedSkill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusChangeRequested;
  final bool isGrid;

  const ResourceBookmarkCard({
    super.key,
    required this.resource,
    required this.provider,
    required this.linkedSkill,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChangeRequested,
    this.isGrid = false,
  });

  @override
  State<ResourceBookmarkCard> createState() => _ResourceBookmarkCardState();
}

class _ResourceBookmarkCardState extends State<ResourceBookmarkCard>
    with TickerProviderStateMixin {
  // Animasi bintang untuk double tap
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Animasi buku terbuka untuk single tap
  late AnimationController _bookAnimationController;
  late Animation<double> _bookAnimation;

  // Animasi progress bar
  late AnimationController _progressAnimController;
  late Animation<double> _progressAnimation;

  // Lottie selebrasi saat status selesai
  bool _showLottie = false;
  bool _showStar = false;

  @override
  void initState() {
    super.initState();

    // --- Star animation (double tap) ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // --- Book open animation (tap) ---
    _bookAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bookAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bookAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // --- Progress bar animation ---
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _statusToProgress(widget.resource.status),
    ).animate(
      CurvedAnimation(
        parent: _progressAnimController,
        curve: Curves.easeOut,
      ),
    );
    _progressAnimController.forward();
  }

  @override
  void didUpdateWidget(ResourceBookmarkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animasikan kembali progress bar jika status berubah
    if (oldWidget.resource.status != widget.resource.status) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: _statusToProgress(widget.resource.status),
      ).animate(
        CurvedAnimation(
          parent: _progressAnimController,
          curve: Curves.easeOut,
        ),
      );
      _progressAnimController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bookAnimationController.dispose();
    _progressAnimController.dispose();
    super.dispose();
  }

  double _statusToProgress(int status) {
    switch (status) {
      case 0:
        return 0.0; // Belum Dibaca
      case 1:
        return 0.5; // Sedang Dibaca
      case 2:
        return 1.0; // Selesai
      default:
        return 0.0;
    }
  }

  Color _progressColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0:
        return widget.provider.translate('status_unread_icon');
      case 1:
        return widget.provider.translate('status_reading_icon');
      case 2:
        return widget.provider.translate('status_completed_icon');
      default:
        return '';
    }
  }

  /// Double tap → ubah status + animasi bintang/lottie
  void _handleDoubleTap() {
    if (widget.resource.resourceType == 'materi') {
      final nextStatus = (widget.resource.status + 1) % 3;
      widget.onStatusChangeRequested();

      // Jika status berikutnya = Selesai → tampilkan Lottie konfeti
      if (nextStatus == 2) {
        setState(() {
          _showLottie = true;
        });
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (mounted) {
            setState(() {
              _showLottie = false;
            });
          }
        });
      } else {
        // Tampilkan animasi bintang untuk status lain
        setState(() {
          _showStar = true;
        });
        _animationController.forward().then((_) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _animationController.reverse().then((_) {
                if (mounted) {
                  setState(() {
                    _showStar = false;
                  });
                }
              });
            }
          });
        });
      }
    }
  }

  /// Single tap → animasi buku terbuka lalu buka URL
  void _openLink() async {
    await _bookAnimationController.forward();

    if (widget.resource.url.isNotEmpty &&
        (widget.resource.url.startsWith('http') ||
            widget.resource.url.startsWith('https') ||
            widget.resource.url.startsWith('file://'))) {
      if (widget.resource.url.startsWith('file://')) {
        final filePath = widget.resource.url.replaceFirst('file://', '');
        try {
          await OpenFile.open(filePath);
        } catch (_) {}
      } else if (kIsWeb) {
        final Uri uri = Uri.parse(widget.resource.url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebViewScreen(
                url: widget.resource.url,
                title: widget.resource.title,
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) widget.onEdit();
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _bookAnimationController.reverse();
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Video':
        return Icons.play_circle_fill_rounded;
      case 'Artikel':
        return Icons.article_rounded;
      case 'Buku':
        return Icons.menu_book_rounded;
      case 'Dokumentasi':
        return Icons.code_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReference = widget.resource.resourceType == 'referensi';

    Color skillColor = theme.colorScheme.primary;
    if (widget.linkedSkill != null) {
      try {
        final parentCat = widget.provider.categories.firstWhere(
          (c) => c.id == widget.linkedSkill!.categoryId,
        );
        skillColor = Color(parentCat.colorValue);
      } catch (_) {}
    }

    final bool hasUrl = widget.resource.url.isNotEmpty &&
        (widget.resource.url.startsWith('http') ||
            widget.resource.url.startsWith('https') ||
            widget.resource.url.startsWith('file://'));

    final Color progressColor = _progressColor(widget.resource.status);

    return Slidable(
      key: Key('resource_${widget.resource.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (context) => widget.onEdit(),
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            icon: Icons.edit_rounded,
            label: widget.provider.translate('edit'),
          ),
          SlidableAction(
            onPressed: (context) => widget.onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: widget.provider.translate('delete'),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(20),
            ),
          ),
        ],
      ),
      child: GestureDetector(
        onDoubleTap: _handleDoubleTap,
        onLongPress: widget.onEdit,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Animasi Buku Terbuka (AnimatedBuilder + Transform Matrix4) ──
            AnimatedBuilder(
              animation: _bookAnimation,
              builder: (context, child) {
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(_bookAnimation.value * -0.8);
                return Transform(
                  alignment: Alignment.centerLeft,
                  transform: matrix,
                  child: child,
                );
              },
              child: Card(
                elevation: 1,
                shadowColor: skillColor.withValues(alpha: 0.2),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: widget.resource.status == 2
                        ? Colors.green.withValues(alpha: 0.5)
                        : theme.dividerColor.withValues(alpha: 0.05),
                    width: widget.resource.status == 2 ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                skillColor.withValues(alpha: 0.15),
                            child: Icon(
                              _getCategoryIcon(widget.resource.category),
                              color: skillColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.resource.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      widget.resource.category,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.hintColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (!isReference &&
                                        widget.resource.status == 2) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.provider.translate(
                                          'filter_completed',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ── Progress Bar (hanya untuk tipe materi) ──
                      if (!isReference) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, _) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _progressAnimation.value,
                                      minHeight: 5,
                                      backgroundColor: progressColor
                                          .withValues(alpha: 0.12),
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        progressColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _statusLabel(widget.resource.status),
                              style: TextStyle(
                                fontSize: 10,
                                color: progressColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (widget.resource.description.isNotEmpty &&
                          !widget.isGrid) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.resource.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // ── Tombol Buka Materi ──
                      if (hasUrl) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: _openLink,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.open_in_new_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  widget.provider.defaultLang == 'en'
                                      ? 'Open Material'
                                      : 'Buka Materi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Lottie Selebrasi saat Materi Selesai ──
            if (_showLottie)
              IgnorePointer(
                child: Lottie.network(
                  'https://assets10.lottiefiles.com/packages/lf20_touohxv0.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback jika gagal load Lottie dari network
                    return AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.amber,
                        size: 80,
                      ),
                    );
                  },
                ),
              ),

            // ── Animasi Bintang saat Double Tap (status != 2) ──
            if (_showStar)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 60,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
