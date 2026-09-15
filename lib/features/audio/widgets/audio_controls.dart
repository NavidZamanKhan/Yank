import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<AudioBloc, AudioState>(
    buildWhen: (a, b) =>
        a.item != b.item || a.playing != b.playing || a.loading != b.loading,
    builder: (context, state) {
      final item = state.item;
      if (item == null) {
        return const SizedBox.shrink();
      }
      return Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.line)),
        ),
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              onPressed: state.loading
                  ? null
                  : () => context.read<AudioBloc>().add(AudioTapped(item)),
              tooltip: state.playing ? 'Pause audio' : 'Play audio',
              icon: Icon(
                state.playing ? LucideIcons.pause : LucideIcons.play,
                size: 17,
              ),
            ),
            IconButton(
              onPressed: () =>
                  context.read<AudioBloc>().add(const AudioStopped()),
              tooltip: 'Close player',
              icon: const Icon(LucideIcons.x, size: 17),
            ),
          ],
        ),
      );
    },
  );
}
