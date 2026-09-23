import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/utils/local_path_resolver.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';

class FullscreenPhotoViewer extends StatefulWidget {
  const FullscreenPhotoViewer({super.key, required this.item});

  final YankItem item;

  static Future<void> open(BuildContext context, YankItem item) =>
      Navigator.of(context).push<void>(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (context, _, _) => FullscreenPhotoViewer(item: item),
          transitionsBuilder: (context, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        ),
      );

  @override
  State<FullscreenPhotoViewer> createState() => _FullscreenPhotoViewerState();
}

class _FullscreenPhotoViewerState extends State<FullscreenPhotoViewer>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _zoomAnimation;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (_animationController.isAnimating) return;
    final currentMatrix = _transformationController.value;
    final isZoomed = !currentMatrix.isIdentity();

    Matrix4 targetMatrix;
    if (isZoomed) {
      targetMatrix = Matrix4.identity();
    } else {
      final position = details.localPosition;
      targetMatrix = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0, 1)
        ..scaleByDouble(2.5, 2.5, 1, 1);
    }

    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward(from: 0);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item.artwork ?? widget.item.url;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: _handleDoubleTap,
            onDoubleTap: () {},
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 5.0,
                child: PosterArtwork(
                  variant: imagePath ?? 'slow',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      PressScale(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (imagePath != null) ...[
                        PressScale(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final rawPath = imagePath;
                              final clean = rawPath.replaceFirst(RegExp(r'^file://'), '');
                              final file = LocalPathResolver.resolveFile(clean);
                              if (file != null && file.existsSync()) {
                                final box = context.findRenderObject() as RenderBox?;
                                await SharePlus.instance.share(
                                  ShareParams(
                                    files: [
                                      XFile(file.path, name: widget.item.displayTitle),
                                    ],
                                    title: widget.item.displayTitle,
                                    sharePositionOrigin: box == null
                                        ? null
                                        : box.localToGlobal(Offset.zero) & box.size,
                                  ),
                                );
                              } else {
                                await SharePlus.instance.share(
                                  ShareParams(text: widget.item.displayTitle),
                                );
                              }
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
