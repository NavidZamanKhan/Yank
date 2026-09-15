import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

class AudioFrame {
  const AudioFrame({
    required this.id,
    required this.position,
    required this.duration,
    required this.playing,
    this.completed = false,
  });
  final String id;
  final Duration position, duration;
  final bool playing, completed;
}

abstract interface class AudioRepository {
  Stream<AudioFrame> get frames;
  Future<void> play(String id, String asset);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> close();
}

class AssetAudioRepository implements AudioRepository {
  final _player = AudioPlayer();
  final _frames = StreamController<AudioFrame>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _id;
  Duration _position = Duration.zero, _duration = Duration.zero;
  bool _playing = false;
  AssetAudioRepository() {
    _subscriptions.add(
      _player.onPositionChanged.listen((value) {
        _position = value;
        _publish();
      }, onError: _error),
    );
    _subscriptions.add(
      _player.onDurationChanged.listen((value) {
        _duration = value;
        _publish();
      }, onError: _error),
    );
    _subscriptions.add(
      _player.onPlayerStateChanged.listen((value) {
        _playing = value == PlayerState.playing;
        _publish();
      }, onError: _error),
    );
    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        _playing = false;
        _position = Duration.zero;
        _publish(completed: true);
      }, onError: _error),
    );
  }
  void _error(Object error) {
    if (!_frames.isClosed) {
      _frames.addError(error);
    }
  }

  void _publish({bool completed = false}) {
    if (_id == null || _frames.isClosed) {
      return;
    }
    _frames.add(
      AudioFrame(
        id: _id!,
        position: _position,
        duration: _duration,
        playing: _playing,
        completed: completed,
      ),
    );
  }

  @override
  Stream<AudioFrame> get frames => _frames.stream;
  @override
  Future<void> play(String id, String asset) async {
    _id = null;
    await _player.stop();
    _position = Duration.zero;
    _duration = Duration.zero;
    _id = id;
    await _player.play(AssetSource(asset), volume: .65);
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.resume();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() async {
    _id = null;
    await _player.stop();
  }

  @override
  Future<void> close() async {
    _id = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _frames.close();
  }
}
