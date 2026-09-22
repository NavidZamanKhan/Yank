import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:yank/features/capture/services/share_receiver_service.dart';
import 'package:yank/features/library/bloc/library_bloc.dart';
import 'package:yank/features/library/repositories/library_repository.dart';

class ShareReceiverListener extends StatefulWidget {
  const ShareReceiverListener({
    super.key,
    required this.child,
    this.serviceFactory,
  });

  final Widget child;
  final ShareReceiverService Function(LibraryRepository repo, LibraryBloc bloc)?
      serviceFactory;

  @override
  State<ShareReceiverListener> createState() => _ShareReceiverListenerState();
}

class _ShareReceiverListenerState extends State<ShareReceiverListener> {
  ShareReceiverService? _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final repo = context.read<LibraryRepository>();
      final bloc = context.read<LibraryBloc>();
      _service = widget.serviceFactory?.call(repo, bloc) ??
          ShareReceiverService(repository: repo, libraryBloc: bloc);
      _service!.initialize();
    });
  }

  @override
  void dispose() {
    _service?.dispose();
    _service = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
