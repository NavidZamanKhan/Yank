import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/yank_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/yank_controls.dart';
import '../../audio/widgets/audio_controls.dart';
import '../../library/bloc/library_bloc.dart';
import '../../library/models/yank_item.dart';
import '../../library/widgets/item_actions.dart';
import '../../library/widgets/poster_artwork.dart';

Future<void> showItemPreview(
  BuildContext context,
  String id, {
  AnimationController? animationController,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 720),
      transitionAnimationController: animationController,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .86,
        child: ItemPreview(id: id),
      ),
    );

class ItemPreview extends StatelessWidget {
  const ItemPreview({super.key, required this.id, this.onClose});
  final String id;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => BlocConsumer<LibraryBloc, LibraryState>(
    listenWhen: (old, next) => old.item(id) != null && next.item(id) == null,
    listener: (context, state) {
      if (onClose == null) {
        Navigator.pop(context);
      }
    },
    builder: (context, state) {
      final item = state.item(id);
      if (item == null) {
        return Column(
          children: [
            SheetHeading(title: 'Item removed', onClose: onClose),
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text('This item is no longer in your library.'),
            ),
          ],
        );
      }
      final availability = state.availability(id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeading(
            title: item.title,
            subtitle:
                '${item.kind == ItemKind.link ? item.domain : item.kind.label} · ${timeAgo(item.createdAt)}',
            onClose: onClose,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (availability != LocalAvailability.available)
                    _DownloadPanel(
                      item: item,
                      availability: availability,
                      offline: state.offline,
                    )
                  else
                    switch (item.kind) {
                      ItemKind.photo => ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: PosterArtwork(
                              variant: item.artwork ?? 'slow',
                            ),
                          ),
                        ),
                      ),
                      ItemKind.audio => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: AudioControls(item: item),
                      ),
                      ItemKind.file => _DocumentPreview(item: item),
                      ItemKind.text => SelectionArea(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            border: Border.all(color: context.colors.line),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            item.body,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      ItemKind.link => _LinkPreview(item: item),
                    },
                  const SizedBox(height: 20),
                  if (item.kind == ItemKind.audio && item.body.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Text(
                        item.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  _DetailRow(
                    label: 'Saved',
                    value:
                        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                  ),
                  if (item.sizeBytes > 0)
                    _DetailRow(label: 'Size', value: fileSize(item.sizeBytes)),
                  _DetailRow(
                    label: 'Location',
                    value: item.archived
                        ? 'Archive'
                        : item.isYanked
                        ? 'Library and Yank'
                        : 'Library',
                  ),
                  if (item.sizeBytes > 0)
                    _DetailRow(
                      label: 'On this device',
                      value: availability == LocalAvailability.available
                          ? 'Available'
                          : availability == LocalAvailability.downloading
                          ? 'Downloading'
                          : 'Download when needed',
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 13, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          context.read<LibraryBloc>().add(ItemYankToggled(id)),
                      icon: const Icon(LucideIcons.arrowDownLeft, size: 18),
                      label: Text(item.isYanked ? 'Unyank' : 'Keep close'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ItemActions(item: item),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _DownloadPanel extends StatelessWidget {
  const _DownloadPanel({
    required this.item,
    required this.availability,
    required this.offline,
  });
  final YankItem item;
  final LocalAvailability availability;
  final bool offline;
  @override
  Widget build(BuildContext context) {
    final downloading = availability == LocalAvailability.downloading;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.cloudDownload, size: 30, color: context.colors.iris),
          const SizedBox(height: 16),
          Text(
            downloading
                ? 'Bringing it closer...'
                : offline
                ? 'Waiting for a connection'
                : 'Ready when you need it.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            downloading ? 'Your item will open here.' : 'This item is in your library. Download it to open it on this device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          if (downloading) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () =>
                  context.read<LibraryBloc>().add(DownloadCancelled(item.id)),
              child: const Text('Cancel download'),
            ),
          ] else
            FilledButton.icon(
              onPressed: () =>
                  context.read<LibraryBloc>().add(DownloadRequested(item.id)),
              icon: const Icon(LucideIcons.download, size: 16),
              label: const Text('Download'),
            ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.item});
  final YankItem item;
  @override
  Widget build(BuildContext context) => SelectionArea(
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YANK / NOTES',
            style: TextStyle(
              color: context.colors.iris,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            item.body,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.8),
          ),
        ],
      ),
    ),
  );
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview({required this.item});
  final YankItem item;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.colors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.link, color: context.colors.iris, size: 27),
        const SizedBox(height: 18),
        if (item.body.isNotEmpty) ...[
          Text(item.body, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
        ],
        SelectableText(item.url!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => openOriginal(context, item),
          icon: const Icon(LucideIcons.externalLink, size: 17),
          label: const Text('Open original'),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.colors.ink),
          ),
        ),
      ],
    ),
  );
}
