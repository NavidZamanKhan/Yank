import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/motion/yank_motion.dart';
import '../../../core/widgets/yank_feedback.dart';
import '../../audio/bloc/audio_bloc.dart';
import '../../audio/repositories/audio_repository.dart';
import '../../library/bloc/library_bloc.dart';
import '../../library/repositories/library_repository.dart';
import '../../library/views/library_page.dart';
import '../bloc/auth_bloc.dart';
import 'auth_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.audioFactory});
  final AudioRepository Function()? audioFactory;
  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    buildWhen: (old, next) => old.user?.id != next.user?.id,
    listenWhen: (old, next) =>
        old.noticeSerial != next.noticeSerial && next.user != null,
    listener: (context, state) {
      if (state.message != null) {
        showMessage(context, state.message!);
      }
    },
    builder: (context, state) => AnimatedSwitcher(
      duration: YankMotion.duration(context, const Duration(milliseconds: 180)),
      // Outgoing screens stop receiving input immediately. In particular, rapid
      // taps cannot interact with a library that's already been logged out.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [
          ...previous.map(
            (child) => ExcludeSemantics(child: IgnorePointer(child: child)),
          ),
          ?current,
        ],
      ),
      child: state.user == null
          ? const AuthPage(key: ValueKey('signed-out'))
          : _LibrarySession(
              key: ValueKey(state.user!.id),
              audioFactory: audioFactory,
            ),
    ),
  );
}

/// Session-local Blocs and a nested Navigator share one lifecycle. Closing the
/// session disposes every sheet/preview, playback subscription, and download
/// timer. Library metadata remains in the repository above the auth gate.
/// The Navigator sits below the providers so its modal routes inherit them too.
class _LibrarySession extends StatefulWidget {
  const _LibrarySession({super.key, this.audioFactory});
  final AudioRepository Function()? audioFactory;
  @override
  State<_LibrarySession> createState() => _LibrarySessionState();
}

class _LibrarySessionState extends State<_LibrarySession> {
  final _navigator = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => LibraryBloc(context.read<LibraryRepository>()),
      ),
      BlocProvider(
        create: (_) =>
            AudioBloc(widget.audioFactory?.call() ?? AssetAudioRepository()),
      ),
    ],
    child: NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navigator.currentState!.pop(),
      child: Navigator(
        key: _navigator,
        onGenerateRoute: (_) =>
            MaterialPageRoute<void>(builder: (_) => const LibraryPage()),
      ),
    ),
  );
}
