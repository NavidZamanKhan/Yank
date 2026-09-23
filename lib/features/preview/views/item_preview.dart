import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/utils/formatters.dart';
import 'package:yank/core/utils/local_path_resolver.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/core/widgets/yank_feedback.dart';
import 'package:yank/features/audio/widgets/audio_controls.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/capture/services/url_metadata_service.dart';
import 'package:yank/features/library/widgets/item_actions.dart';
import 'package:yank/features/library/widgets/poster_artwork.dart';
import 'package:yank/features/preview/views/fullscreen_photo_viewer.dart';

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
        reverseCurve: Curves.easeInOutCubic,
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
      if (item.kind == ItemKind.link &&
          (item.artwork == null || item.title == item.domain)) {
        UrlMetadataService.enrichItem(
          context.read<LibraryBloc>().repository,
          item,
        );
      }
      final availability = state.availability(id);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeading(
            title: item.displayTitle,
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
                  switch (item.kind) {
                    ItemKind.photo => _PhotoPreview(
                        item: item,
                        availability: availability,
                        offline: state.offline,
                      ),
                    ItemKind.file => _DocumentPreview(
                        item: item,
                        availability: availability,
                        offline: state.offline,
                      ),
                    ItemKind.audio =>
                      availability != LocalAvailability.available
                          ? _DownloadPanel(
                              item: item,
                              availability: availability,
                              offline: state.offline,
                            )
                          : Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: AudioControls(item: item),
                            ),
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
                        ? 'Archive (deletes in ${item.daysUntilArchiveDeletion} days)'
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
                    child: YankButton(
                      label: item.isYanked ? 'Unyank' : 'Keep close',
                      icon: LucideIcons.arrowDownLeft,
                      onPressed: () =>
                          context.read<LibraryBloc>().add(ItemYankToggled(id)),
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

class _PhotoPreview extends StatefulWidget {
  const _PhotoPreview({
    required this.item,
    required this.availability,
    required this.offline,
  });
  final YankItem item;
  final LocalAvailability availability;
  final bool offline;

  @override
  State<_PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<_PhotoPreview> {
  bool _openOnDownload = false;

  @override
  void didUpdateWidget(covariant _PhotoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_openOnDownload &&
        oldWidget.availability != LocalAvailability.available &&
        widget.availability == LocalAvailability.available) {
      _openOnDownload = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FullscreenPhotoViewer.open(context, widget.item);
        }
      });
    }
  }

  void _onDownloadThenOpen() {
    if (widget.offline) {
      showMessage(context, 'Connect to download this photo.');
      return;
    }
    setState(() {
      _openOnDownload = true;
    });
    context.read<LibraryBloc>().add(DownloadRequested(widget.item.id));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAvailable = widget.availability == LocalAvailability.available;
    final isDownloading = widget.availability == LocalAvailability.downloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isAvailable
              ? () => FullscreenPhotoViewer.open(context, item)
              : isDownloading
                  ? null
                  : _onDownloadThenOpen,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: PosterArtwork(
                    variant: item.artwork ?? 'slow',
                    remoteUrl: item.url,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    isDownloading: isDownloading,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDownloading) ...[
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Downloading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (isAvailable) ...[
                        const Icon(LucideIcons.expand,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Tap to expand',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const Icon(LucideIcons.cloudDownload,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Download to open',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isDownloading) ...[
          const SizedBox(height: 10),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(2)),
            child: LinearProgressIndicator(minHeight: 3),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: isAvailable
                  ? YankButton(
                      label: 'Open',
                      icon: LucideIcons.maximize2,
                      onPressed: () =>
                          FullscreenPhotoViewer.open(context, item),
                    )
                  : isDownloading
                      ? const YankButton(
                          label: 'Downloading...',
                          loading: true,
                        )
                      : YankButton(
                          label: 'Download then open',
                          icon: LucideIcons.download,
                          onPressed: _onDownloadThenOpen,
                        ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: isDownloading
                  ? YankButton.secondary(
                      label: 'Cancel',
                      onPressed: () {
                        setState(() {
                          _openOnDownload = false;
                        });
                        context.read<LibraryBloc>().add(DownloadCancelled(item.id));
                      },
                    )
                  : YankButton.secondary(
                      label: 'Share',
                      icon: LucideIcons.share2,
                      onPressed: () => _shareLocalFile(context, item),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DocumentPreview extends StatefulWidget {
  const _DocumentPreview({
    required this.item,
    required this.availability,
    required this.offline,
  });
  final YankItem item;
  final LocalAvailability availability;
  final bool offline;

  @override
  State<_DocumentPreview> createState() => _DocumentPreviewState();
}

class _DocumentPreviewState extends State<_DocumentPreview> {
  bool _openOnDownload = false;

  @override
  void didUpdateWidget(covariant _DocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_openOnDownload &&
        oldWidget.availability != LocalAvailability.available &&
        widget.availability == LocalAvailability.available) {
      _openOnDownload = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openFile(context, widget.item);
        }
      });
    }
  }

  void _onDownloadThenOpen() {
    if (widget.offline) {
      showMessage(context, 'Connect to download this file.');
      return;
    }
    setState(() {
      _openOnDownload = true;
    });
    context.read<LibraryBloc>().add(DownloadRequested(widget.item.id));
  }

  IconData _getFileIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.apk')) return LucideIcons.package;
    if (lower.endsWith('.pdf')) return LucideIcons.fileText;
    if (lower.endsWith('.zip') ||
        lower.endsWith('.tar') ||
        lower.endsWith('.gz') ||
        lower.endsWith('.rar')) {
      return LucideIcons.fileArchive;
    }
    if (lower.endsWith('.dart') ||
        lower.endsWith('.js') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.py') ||
        lower.endsWith('.json') ||
        lower.endsWith('.html')) {
      return LucideIcons.fileCode;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac')) {
      return LucideIcons.fileAudio;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return LucideIcons.fileVideo;
    }
    return LucideIcons.file;
  }

  String _getExtensionBadge(String name) {
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toUpperCase();
    }
    return 'FILE';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isAvailable = widget.availability == LocalAvailability.available;
    final isDownloading = widget.availability == LocalAvailability.downloading;
    final title = item.displayTitle;
    final badge = _getExtensionBadge(title);
    final icon = _getFileIcon(title);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.iris.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colors.iris, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.colors.ink,
                            ),
                          ),
                        ),
                        if (item.sizeBytes > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            fileSize(item.sizeBytes),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.body.isNotEmpty &&
              item.body != item.title &&
              item.body != item.displayTitle &&
              !item.body.startsWith('/') &&
              !item.body.startsWith('file://')) ...[
            const SizedBox(height: 16),
            Text(
              item.body,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
          if (isDownloading) ...[
            const SizedBox(height: 16),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: isAvailable
                    ? YankButton(
                        label: 'Open',
                        icon: LucideIcons.externalLink,
                        onPressed: () => _openFile(context, item),
                      )
                    : isDownloading
                        ? const YankButton(
                            label: 'Downloading...',
                            loading: true,
                          )
                        : YankButton(
                            label: 'Download then open',
                            icon: LucideIcons.download,
                            onPressed: _onDownloadThenOpen,
                          ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: isDownloading
                    ? YankButton.secondary(
                        label: 'Cancel',
                        onPressed: () {
                          setState(() {
                            _openOnDownload = false;
                          });
                          context.read<LibraryBloc>().add(DownloadCancelled(item.id));
                        },
                      )
                    : YankButton.secondary(
                        label: 'Share',
                        icon: LucideIcons.share2,
                        onPressed: () => _shareLocalFile(context, item),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openFile(BuildContext context, YankItem item) async {
  final path = item.url ?? item.artwork ?? item.audioAsset ?? item.body;
  if (path.isEmpty) {
    showMessage(context, 'No file path found.');
    return;
  }
  final cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
  final file = LocalPathResolver.resolveFile(cleanPath);
  if (file == null || !file.existsSync()) {
    showMessage(context, 'This file is not currently stored on this device.');
    return;
  }

  // 1. Try launching file directly via launchUrl (works on macOS and iOS for supported files)
  try {
    final opened = await launchUrl(
      Uri.file(file.path),
      mode: LaunchMode.externalApplication,
    );
    if (opened) return;
  } catch (_) {}

  // 2. Cross-platform universal launcher: open via native share/action sheet
  try {
    if (!context.mounted) return;
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
  } catch (e) {
    if (context.mounted) {
      showMessage(context, 'Could not open file: $e');
    }
  }
}

Future<void> _shareLocalFile(BuildContext context, YankItem item) async {
  final path = item.url ?? item.artwork ?? item.audioAsset ?? item.body;
  if (path.isEmpty) return;
  final cleanPath = path.replaceFirst(RegExp(r'^file://'), '');
  final file = LocalPathResolver.resolveFile(cleanPath);
  if (file != null && file.existsSync()) {
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
      ShareParams(text: '${item.displayTitle}\n$path'),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  const _LinkPreview({required this.item});
  final YankItem item;

  @override
  Widget build(BuildContext context) {
    final hasArtwork = item.artwork != null && item.artwork!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasArtwork)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: PosterArtwork(
                variant: item.artwork!,
                remoteUrl: item.url,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.iris.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.globe,
                        size: 13,
                        color: context.colors.iris,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.domain,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.colors.iris,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                ),
                if (item.body.isNotEmpty && item.body != item.url) ...[
                  const SizedBox(height: 10),
                  Text(
                    item.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: context.colors.muted,
                        ),
                  ),
                ],
                const SizedBox(height: 14),
                SelectableText(
                  item.url ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.iris,
                      ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: YankButton(
                        label: 'Open original',
                        icon: LucideIcons.externalLink,
                        onPressed: () => openOriginal(context, item),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: YankButton.secondary(
                        label: 'Share',
                        icon: LucideIcons.share2,
                        onPressed: () => _shareLocalFile(context, item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
