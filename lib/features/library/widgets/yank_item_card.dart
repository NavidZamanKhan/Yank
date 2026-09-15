import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/yank_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/yank_controls.dart';
import '../../audio/widgets/audio_controls.dart';
import '../bloc/library_bloc.dart';
import '../models/yank_item.dart';
import 'item_actions.dart';
import 'poster_artwork.dart';

class YankItemCard extends StatelessWidget {
  const YankItemCard({
    super.key,
    required this.item,
    required this.availability,
    required this.onOpen,
    required this.onPreview,
  });
  final YankItem item;
  final LocalAvailability availability;
  final VoidCallback onOpen, onPreview;
  void _yank(BuildContext context) {
    HapticFeedback.selectionClick();
    context.read<LibraryBloc>().add(ItemYankToggled(item.id));
  }

  @override
  Widget build(BuildContext context) {
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        YankToggle(
          selected: item.isYanked,
          onPressed: () => _yank(context),
          title: item.title,
        ),
        ItemActions(item: item, onPreview: onPreview),
      ],
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: item.kind == ItemKind.text
                ? FontWeight.w400
                : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _metadata(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
    final row = Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 3, 10),
      child: Row(
        children: [
          if ((item.kind == ItemKind.link || item.kind == ItemKind.file) &&
              MediaQuery.sizeOf(context).width > 360 &&
              MediaQuery.textScalerOf(context).scale(14) < 19) ...[
            Container(
              width: 34,
              height: 38,
              decoration: BoxDecoration(
                color: context.colors.canvas,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                item.kind == ItemKind.file
                    ? LucideIcons.fileText
                    : item.source == 'GitHub' || item.source == 'Flutter'
                    ? LucideIcons.codeXml
                    : LucideIcons.link,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: copy),
          const SizedBox(width: 4),
          actions,
        ],
      ),
    );
    Widget content = row;
    if (item.kind == ItemKind.photo) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 118,
            width: double.infinity,
            child: PosterArtwork(variant: item.artwork ?? 'slow'),
          ),
          row,
        ],
      );
    } else if (item.kind == ItemKind.audio &&
        availability == LocalAvailability.available) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row,
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 14, 10),
            child: AudioControls(item: item),
          ),
        ],
      );
    }
    return Dismissible(
      key: ValueKey('swipe-${item.id}'),
      dismissThresholds: const {
        DismissDirection.startToEnd: .28,
        DismissDirection.endToStart: .28,
      },
      background: _swipeBackground(context, left: true),
      secondaryBackground: _swipeBackground(context, left: false),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _yank(context);
        } else {
          context.read<LibraryBloc>().add(ItemArchiveToggled(item.id));
        }
        return false;
      },
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onOpen, onLongPress: onPreview, child: content),
      ),
    );
  }

  String _metadata() {
    final prefix = switch (item.kind) {
      ItemKind.link => item.domain,
      ItemKind.photo => 'Image',
      ItemKind.audio => 'Audio',
      ItemKind.file => 'PDF · ${fileSize(item.sizeBytes)}',
      ItemKind.text => 'Text',
    };
    return '$prefix · ${timeAgo(item.createdAt)}${item.archived ? ' · Archived' : ''}${availability == LocalAvailability.cloud
        ? ' · Cloud'
        : availability == LocalAvailability.downloading
        ? ' · Downloading'
        : ''}';
  }

  Widget _swipeBackground(BuildContext context, {required bool left}) =>
      Container(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.colors.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          left ? LucideIcons.arrowDownLeft : LucideIcons.archive,
          color: context.colors.iris,
        ),
      );
}
