import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/utils/local_path_resolver.dart';
import 'package:yank/core/widgets/yank_feedback.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';

enum ItemMenuAction { preview, copy, share, archive, removeDownload, delete }

class ItemActions extends StatelessWidget {
  const ItemActions({super.key, required this.item, this.onPreview});
  final YankItem item;
  final VoidCallback? onPreview;
  @override
  Widget build(BuildContext context) => PopupMenuButton<ItemMenuAction>(
    tooltip: 'Actions for ${item.displayTitle}',
    icon: Icon(
      LucideIcons.ellipsisVertical,
      size: 17,
      color: context.colors.muted,
    ),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    color: context.colors.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    onSelected: (action) async {
      final bloc = context.read<LibraryBloc>();
      switch (action) {
        case ItemMenuAction.preview:
          onPreview?.call();
        case ItemMenuAction.copy:
          try {
            await Clipboard.setData(
              ClipboardData(
                text:
                    item.url ?? (item.body.isNotEmpty ? item.body : item.displayTitle),
              ),
            );
            if (context.mounted) {
              showMessage(
                context,
                item.kind == ItemKind.link ? 'Link copied.' : 'Copied.',
              );
            }
          } catch (_) {
            if (context.mounted) {
              showMessage(context, 'The clipboard is unavailable. Try again.');
            }
          }
        case ItemMenuAction.share:
          try {
            final box = context.findRenderObject() as RenderBox?;
            final origin = box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size;

            final localPath = item.url ?? item.artwork ?? item.audioAsset;
            final cleanPath =
                localPath?.replaceFirst(RegExp(r'^file://'), '');
            final localFile = LocalPathResolver.resolveFile(cleanPath);

            if (localFile != null && localFile.existsSync()) {
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(localFile.path, name: item.displayTitle)],
                  title: item.displayTitle,
                  sharePositionOrigin: origin,
                ),
              );
            } else {
              await SharePlus.instance.share(
                ShareParams(
                  text: '${item.displayTitle}\n${item.url ?? item.body}',
                  sharePositionOrigin: origin,
                ),
              );
            }
          } catch (_) {
            if (context.mounted) {
              showMessage(
                context,
                'Sharing is unavailable here. You can copy the details instead.',
              );
            }
          }
        case ItemMenuAction.archive:
          bloc.add(ItemArchiveToggled(item.id));
        case ItemMenuAction.removeDownload:
          bloc.add(LocalCopyRemoved(item.id));
        case ItemMenuAction.delete:
          bloc.add(ItemDeleted(item.id));
      }
    },
    itemBuilder: (context) => [
      if (onPreview != null)
        _entry(ItemMenuAction.preview, LucideIcons.scan, 'Preview'),
      _entry(
        ItemMenuAction.copy,
        LucideIcons.copy,
        item.kind == ItemKind.link ? 'Copy link' : 'Copy details',
      ),
      _entry(ItemMenuAction.share, LucideIcons.share2, 'Share details'),
      _entry(
        ItemMenuAction.archive,
        LucideIcons.archive,
        item.archived ? 'Restore to library' : 'Archive',
      ),
      if ({ItemKind.audio, ItemKind.file, ItemKind.photo}.contains(item.kind) &&
          context.read<LibraryBloc>().state.availability(item.id) ==
              LocalAvailability.available)
        _entry(
          ItemMenuAction.removeDownload,
          LucideIcons.cloud,
          'Remove download',
        ),
      _entry(ItemMenuAction.delete, LucideIcons.trash2, 'Delete'),
    ],
  );
  PopupMenuItem<ItemMenuAction> _entry(
    ItemMenuAction value,
    IconData icon,
    String text,
  ) => PopupMenuItem(
    value: value,
    child: Row(
      children: [Icon(icon, size: 17), const SizedBox(width: 12), Text(text)],
    ),
  );
}

Future<void> openOriginal(BuildContext context, YankItem item) async {
  if (item.url == null) {
    return;
  }
  try {
    final opened = await launchUrl(
      Uri.parse(item.url!),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showMessage(
        context,
        'Could not open the link. You can copy it from the item menu.',
      );
    }
  } catch (_) {
    if (context.mounted) {
      showMessage(
        context,
        'Could not open the link. You can copy it from the item menu.',
      );
    }
  }
}
