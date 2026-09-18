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

  void _archive(BuildContext context) {
    context.read<LibraryBloc>().add(ItemArchiveToggled(item.id));
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
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          if ((item.kind == ItemKind.link || item.kind == ItemKind.file) &&
              MediaQuery.sizeOf(context).width > 360 &&
              MediaQuery.textScalerOf(context).scale(14) < 19) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.canvas,
                borderRadius: BorderRadius.circular(10),
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
            const SizedBox(width: 12),
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
    final card = Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onOpen, onLongPress: onPreview, child: content),
    );

    return _ClampedSwipeCard(
      key: ValueKey('swipe-${item.id}'),
      isYanked: item.isYanked,
      isArchived: item.archived,
      onSwipeRight: () => _yank(context),
      onSwipeLeft: () => _archive(context),
      child: card,
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
}

class _ClampedSwipeCard extends StatefulWidget {
  const _ClampedSwipeCard({
    super.key,
    required this.child,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.isYanked,
    required this.isArchived,
  });

  final Widget child;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final bool isYanked;
  final bool isArchived;

  @override
  State<_ClampedSwipeCard> createState() => _ClampedSwipeCardState();
}

class _ClampedSwipeCardState extends State<_ClampedSwipeCard>
    with TickerProviderStateMixin {
  static const double _triggerThreshold = 56.0;
  static const double _maxTravel = 80.0;

  late final AnimationController _springController;
  late final AnimationController _collapseController;
  late final Animation<double> _sizeFactorAnimation;
  Animation<double>? _slideAnimation;
  double _dragOffset = 0.0;
  bool _hasTriggeredHaptic = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        setState(() {
          _dragOffset = _slideAnimation?.value ?? 0.0;
        });
      });

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sizeFactorAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _collapseController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _collapseController.dispose();
    super.dispose();
  }

  double _clampDrag(double raw) {
    if (raw > 0) {
      if (raw <= _triggerThreshold) return raw;
      final over = raw - _triggerThreshold;
      return (_triggerThreshold + over * 0.25).clamp(0.0, _maxTravel);
    } else {
      if (raw >= -_triggerThreshold) return raw;
      final over = raw + _triggerThreshold;
      return (-_triggerThreshold + over * 0.25).clamp(-_maxTravel, 0.0);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    if (_springController.isAnimating) {
      _springController.stop();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    final newRaw = _dragOffset + details.delta.dx;
    final clamped = _clampDrag(newRaw);

    if (clamped.abs() >= _triggerThreshold && !_hasTriggeredHaptic) {
      HapticFeedback.lightImpact();
      _hasTriggeredHaptic = true;
    } else if (clamped.abs() < _triggerThreshold && _hasTriggeredHaptic) {
      _hasTriggeredHaptic = false;
    }

    setState(() {
      _dragOffset = clamped;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final reachedRight = _dragOffset >= _triggerThreshold;
    final reachedLeft = _dragOffset <= -_triggerThreshold;

    if (reachedRight) {
      widget.onSwipeRight();
      _springBack();
    } else if (reachedLeft) {
      _dismissAndArchive();
    } else {
      _springBack();
    }
  }

  void _onHorizontalDragCancel() {
    if (_isDismissing) return;
    _springBack();
  }

  void _springBack() {
    _hasTriggeredHaptic = false;
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.duration = const Duration(milliseconds: 240);
    _springController.forward(from: 0.0);
  }

  Future<void> _dismissAndArchive() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isDismissing = true;
      _hasTriggeredHaptic = false;
    });

    final screenWidth = MediaQuery.sizeOf(context).width;
    _slideAnimation = Tween<double>(
      begin: _dragOffset,
      end: -screenWidth * 0.9,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeInCubic,
    ));
    _springController.duration = const Duration(milliseconds: 160);
    await _springController.forward(from: 0.0);

    if (!mounted) return;

    await _collapseController.forward(from: 0.0);

    if (!mounted) return;

    widget.onSwipeLeft();
  }

  @override
  Widget build(BuildContext context) {
    final isSwipingRight = _dragOffset > 0;
    final isSwipingLeft = _dragOffset < 0;
    final progress = (_dragOffset.abs() / _triggerThreshold).clamp(0.0, 1.0);
    final pastThreshold = _dragOffset.abs() >= _triggerThreshold;
    final dismissOpacity = _isDismissing
        ? (1.0 - _springController.value).clamp(0.0, 1.0)
        : 1.0;

    return SizeTransition(
      sizeFactor: _sizeFactorAnimation,
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: _isDismissing,
        child: Opacity(
          opacity: dismissOpacity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSwipingRight || isSwipingLeft)
                Positioned.fill(
                  child: Container(
                    alignment: isSwipingRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: context.colors.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Transform.scale(
                      scale: 0.8 + (progress * 0.2),
                      child: Opacity(
                        opacity: 0.4 + (progress * 0.6),
                        child: Icon(
                          isSwipingRight
                              ? LucideIcons.arrowDownLeft
                              : (widget.isArchived
                                  ? LucideIcons.archiveRestore
                                  : LucideIcons.archive),
                          color: pastThreshold
                              ? context.colors.iris
                              : context.colors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              GestureDetector(
                onHorizontalDragStart: _onHorizontalDragStart,
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onHorizontalDragCancel: _onHorizontalDragCancel,
                behavior: HitTestBehavior.opaque,
                child: Transform.translate(
                  offset: Offset(_dragOffset, 0),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
