import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';

class FullscreenPhotoViewer extends StatelessWidget {
  const FullscreenPhotoViewer({super.key, required this.item});

  final YankItem item;

  static Future<void> open(BuildContext context, YankItem item) =>
      Navigator.of(context).push<void>(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, __, ___) => FullscreenPhotoViewer(item: item),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final imagePath = item.artwork;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 5.0,
              child: PosterArtwork(
                variant: imagePath ?? 'slow',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 22),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.displayTitle,
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
                    IconButton(
                      onPressed: () async {
                        final file = File(imagePath.replaceFirst(RegExp(r'^file://'), ''));
                        if (file.existsSync()) {
                          final box = context.findRenderObject() as RenderBox?;
                          await SharePlus.instance.share(
                            ShareParams(
                              files: [XFile(file.path, name: item.displayTitle)],
                              title: item.displayTitle,
                              sharePositionOrigin: box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        } else {
                          await SharePlus.instance.share(
                            ShareParams(text: item.displayTitle),
                          );
                        }
                      },
                      icon: const Icon(LucideIcons.share2, color: Colors.white, size: 20),
                      tooltip: 'Share',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(30),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
