import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/theme/yank_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../library/models/yank_item.dart';
import '../bloc/audio_bloc.dart';

class AudioControls extends StatelessWidget {
  const AudioControls({super.key, required this.item});
  final YankItem item;
  @override
  Widget build(BuildContext context) => BlocBuilder<AudioBloc, AudioState>(
    buildWhen: (old, next) =>
        old.item?.id == item.id || next.item?.id == item.id,
    builder: (context, state) {
      final active = state.item?.id == item.id;
      final duration = active && state.duration > Duration.zero
          ? state.duration
          : Duration(seconds: item.durationSeconds);
      final position = active ? state.position : Duration.zero;
      final fraction = duration.inMilliseconds == 0
          ? 0.0
          : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
      return Row(
        children: [
          IconButton(
            tooltip: active && state.playing ? 'Pause audio' : 'Play audio',
            onPressed: active && state.loading
                ? null
                : () => context.read<AudioBloc>().add(AudioTapped(item)),
            style: IconButton.styleFrom(
              backgroundColor: context.colors.tint,
              foregroundColor: context.colors.iris,
              shape: const CircleBorder(),
            ),
            icon: active && state.loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : Icon(
                    active && state.playing
                        ? LucideIcons.pause
                        : LucideIcons.play,
                    size: 17,
                  ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _WaveSeekBar(
              value: fraction,
              duration: duration,
              enabled: active,
              onSeek: (value) => context.read<AudioBloc>().add(
                AudioSeeked(
                  Duration(
                    milliseconds: (duration.inMilliseconds * value).round(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            audioTime(active && position > Duration.zero ? position : duration),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    },
  );
}

// Scrubbing is transient presentation state. Only the final requested position
// becomes a Bloc event, so pointer movement cannot flood the native player queue.
class _WaveSeekBar extends StatefulWidget {
  const _WaveSeekBar({
    required this.value,
    required this.duration,
    required this.enabled,
    required this.onSeek,
  });
  final double value;
  final Duration duration;
  final bool enabled;
  final ValueChanged<double> onSeek;
  @override
  State<_WaveSeekBar> createState() => _WaveSeekBarState();
}

class _WaveSeekBarState extends State<_WaveSeekBar> {
  double? _drag;
  @override
  Widget build(BuildContext context) {
    final value = _drag ?? widget.value;
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: CustomPaint(
                painter: _WaveformPainter(
                  value,
                  context.colors.iris,
                  context.colors.muted.withValues(alpha: .35),
                ),
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 0,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: widget.enabled
                  ? context.colors.iris
                  : Colors.transparent,
              disabledThumbColor: Colors.transparent,
              overlayColor: context.colors.iris.withValues(alpha: .1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackShape: const RectangularSliderTrackShape(),
            ),
            child: Slider(
              value: value,
              semanticFormatterCallback: (position) => audioTime(
                Duration(
                  milliseconds: (widget.duration.inMilliseconds * position)
                      .round(),
                ),
              ),
              onChanged: widget.enabled
                  ? (position) => setState(() => _drag = position)
                  : null,
              onChangeEnd: widget.enabled
                  ? (position) {
                      widget.onSeek(position);
                      setState(() => _drag = null);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter(this.progress, this.active, this.inactive);
  final double progress;
  final Color active, inactive;
  // A decorative envelope for the bundled instrumental sample, not a claim of
  // microphone analysis. Real audio position drives color and the seek control.
  static const bars = [
    .18,
    .35,
    .25,
    .58,
    .8,
    .49,
    .97,
    .67,
    .32,
    .46,
    .76,
    .51,
    .87,
    .35,
    .21,
    .49,
    .73,
    .94,
    .52,
    .28,
    .63,
    .42,
    .21,
    .14,
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final height = size.height * bars[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * step,
            (size.height - height) / 2,
            (step * .48).clamp(1.5, 4),
            height,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = i / bars.length < progress ? active : inactive,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress ||
      old.active != active ||
      old.inactive != inactive;
}

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  YankItem? _displayItem;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: YankMotion.panel,
      reverseDuration: YankMotion.settle,
    );
    _curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final initialItem = context.read<AudioBloc>().state.item;
    if (initialItem != null) {
      _displayItem = initialItem;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioBloc, AudioState>(
      listenWhen: (prev, curr) => prev.item != curr.item,
      listener: (context, state) {
        final forwardDur = YankMotion.duration(context, YankMotion.panel);
        final reverseDur = YankMotion.duration(context, YankMotion.settle);
        _controller.duration = forwardDur;
        _controller.reverseDuration = reverseDur;
        if (state.item != null) {
          setState(() => _displayItem = state.item);
          _controller.forward();
        } else {
          _controller.reverse();
        }
      },
      buildWhen: (prev, curr) =>
          prev.item != curr.item ||
          prev.playing != curr.playing ||
          prev.loading != curr.loading,
      builder: (context, state) {
        if (state.item != null && _displayItem != state.item) {
          _displayItem = state.item;
          if (_controller.value == 0.0) {
            final forwardDur = YankMotion.duration(context, YankMotion.panel);
            _controller.duration = forwardDur;
            _controller.forward();
          }
        }

        final item = state.item ?? _displayItem;
        if (item == null) {
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _curved,
          builder: (context, _) {
            if (_controller.value == 0.0 && state.item == null) {
              return const SizedBox.shrink();
            }
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _curved.value,
                child: Opacity(
                  opacity: _curved.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0.0, (1.0 - _curved.value) * 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        border: Border(
                          top: BorderSide(color: context.colors.line),
                        ),
                      ),
                      padding: const EdgeInsets.only(left: 16, right: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: YankMotion.duration(
                                context,
                                YankMotion.quick,
                              ),
                              child: SizedBox(
                                key: ValueKey(item.id),
                                width: double.infinity,
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: state.loading
                                ? null
                                : () => context
                                    .read<AudioBloc>()
                                    .add(AudioTapped(item)),
                            tooltip: state.playing
                                ? 'Pause audio'
                                : 'Play audio',
                            icon: Icon(
                              state.playing
                                  ? LucideIcons.pause
                                  : LucideIcons.play,
                              size: 17,
                            ),
                          ),
                          IconButton(
                            onPressed: () => context
                                .read<AudioBloc>()
                                .add(const AudioStopped()),
                            tooltip: 'Close player',
                            icon: const Icon(LucideIcons.x, size: 17),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
