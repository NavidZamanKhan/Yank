import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';

/// A small illustration made from the app's own content vocabulary. It has no
/// controls and no perpetual floating animation. The cards settle once on entry.
class AuthCardStack extends StatelessWidget {
  const AuthCardStack({super.key, this.height = 190});
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: YankMotion.duration(
          context,
          const Duration(milliseconds: 420),
        ),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 320,
              height: 212,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 24,
                    top: 17,
                    child: Transform.rotate(
                      angle: -.12,
                      child: _Paper(
                        width: 146,
                        height: 148,
                        color: context.colors.tint,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.alignLeft,
                                size: 17,
                                color: context.colors.iris,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'a thought\nfor later.',
                                style: TextStyle(
                                  fontSize: 18,
                                  height: 1.15,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.iris,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 17,
                    child: Transform.rotate(
                      angle: .105,
                      child: _Paper(
                        width: 166,
                        height: 70,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.link,
                                size: 18,
                                color: context.colors.iris,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'worth a read',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.ink,
                                      ),
                                    ),
                                    Text(
                                      'Saved for a slow day',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: context.colors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 64,
                    top: 57,
                    child: Transform.rotate(
                      angle: .035,
                      child: _Paper(
                        width: 194,
                        height: 150,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 96,
                              width: double.infinity,
                              child: PosterArtwork(),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'the little things',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.colors.ink,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    LucideIcons.arrowDownLeft,
                                    size: 14,
                                    color: context.colors.iris,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.iris,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.arrowDownLeft,
                            size: 12,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'kept close.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Paper extends StatelessWidget {
  const _Paper({
    required this.width,
    required this.height,
    required this.child,
    this.color,
  });
  final double width, height;
  final Color? color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color ?? context.colors.surface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: context.colors.line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .045),
          blurRadius: 15,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: MediaQuery.withClampedTextScaling(
      minScaleFactor: 1,
      maxScaleFactor: 1,
      child: child,
    ),
  );
}
