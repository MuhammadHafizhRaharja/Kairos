import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:any_link_preview/any_link_preview.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _showStar = false;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Only animate for 'materi' (study materials)
    if (widget.resource.resourceType == 'materi') {
      widget.onStatusChangeRequested();

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

  void _openLink() async {
    if (widget.resource.url.isNotEmpty &&
        (widget.resource.url.startsWith('http') ||
            widget.resource.url.startsWith('https'))) {
      if (kIsWeb) {
        final Uri uri = Uri.parse(widget.resource.url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      } else {
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
    } else {
      // Fallback for non-http links or empty links
      widget.onEdit();
    }
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

    bool hasUrl = widget.resource.url.isNotEmpty &&
        (widget.resource.url.startsWith('http') ||
            widget.resource.url.startsWith('https'));

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
        onTap: _openLink,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Card(
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
                          backgroundColor: skillColor.withValues(alpha: 0.15),
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
                    if (hasUrl && !widget.isGrid) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AnyLinkPreview(
                          link: widget.resource.url,
                          displayDirection: UIDirection.uiDirectionHorizontal,
                          showMultimedia: true,
                          bodyMaxLines: 2,
                          bodyTextOverflow: TextOverflow.ellipsis,
                          titleStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          bodyStyle: TextStyle(
                            color: theme.hintColor,
                            fontSize: 11,
                          ),
                          errorWidget: Container(
                            padding: const EdgeInsets.all(8),
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.resource.url,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          cache: const Duration(days: 7),
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: 12,
                          removeElevation: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Floating Star Animation on Double Tap
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
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
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
