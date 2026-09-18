import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/yank_theme.dart';
import '../../../core/widgets/yank_controls.dart';
import '../../../core/widgets/yank_feedback.dart';
import '../../library/models/yank_item.dart';
import '../../library/repositories/library_repository.dart';
import '../../library/widgets/poster_artwork.dart';
import '../bloc/capture_bloc.dart';

Future<bool?> showCaptureSheet(
  BuildContext context, {
  AnimationController? animationController,
}) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 620),
      transitionAnimationController: animationController,
      builder: (context) => BlocProvider(
        create: (_) => CaptureBloc(context.read<LibraryRepository>()),
        child: const CaptureSheet(),
      ),
    );

class CaptureSheet extends StatefulWidget {
  const CaptureSheet({super.key});
  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CaptureBloc, CaptureState>(
    listenWhen: (old, next) => !old.saved && next.saved,
    listener: (context, state) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    },
    builder: (context, state) {
      final isWriting =
          state.kind == ItemKind.link || state.kind == ItemKind.text;
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHeading(
                title: 'Something worth keeping.',
                subtitle: 'Pull it into your day.',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: ItemKind.values
                          .map(
                            (kind) => ChoiceChip(
                              label: Text(
                                kind == ItemKind.link
                                    ? 'Link'
                                    : kind == ItemKind.photo
                                    ? 'Image'
                                    : kind == ItemKind.file
                                    ? 'File'
                                    : kind.label,
                              ),
                              selected: state.kind == kind,
                              showCheckmark: false,
                              selectedColor: context.colors.tint,
                              backgroundColor: context.colors.surface,
                              side: BorderSide(
                                color: state.kind == kind
                                    ? context.colors.tint
                                    : context.colors.line,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 13,
                                color: state.kind == kind
                                    ? context.colors.iris
                                    : context.colors.muted,
                              ),
                              onSelected: state.saving
                                  ? null
                                  : (_) {
                                      _controller.clear();
                                      context.read<CaptureBloc>().add(
                                        CaptureKindChanged(kind),
                                      );
                                    },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 22),
                    if (isWriting) ...[
                      TextField(
                        controller: _controller,
                        enabled: !state.saving,
                        autofocus: false,
                        maxLines: state.kind == ItemKind.text ? 5 : 2,
                        minLines: state.kind == ItemKind.text ? 4 : 1,
                        maxLength: state.kind == ItemKind.text ? 6000 : 2048,
                        keyboardType: state.kind == ItemKind.link
                            ? TextInputType.url
                            : TextInputType.multiline,
                        textCapitalization: state.kind == ItemKind.text
                            ? TextCapitalization.sentences
                            : TextCapitalization.none,
                        onChanged: (value) => context.read<CaptureBloc>().add(
                          CaptureValueChanged(value),
                        ),
                        decoration: InputDecoration(
                          labelText: state.kind == ItemKind.link
                              ? 'Web address'
                              : 'Your text',
                          hintText: state.kind == ItemKind.link
                              ? 'Paste a link...'
                              : 'A thought, a quote, a tiny plan...',
                          alignLabelWithHint: true,
                          counterText: '',
                          errorText: state.error,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: state.saving
                            ? null
                            : () async {
                                try {
                                  final clipboard = await Clipboard.getData(
                                    Clipboard.kTextPlain,
                                  );
                                  if (!context.mounted) {
                                    return;
                                  }
                                  final current = context
                                      .read<CaptureBloc>()
                                      .state;
                                  if (current.kind != state.kind ||
                                      current.saving) {
                                    return;
                                  }
                                  final text = clipboard?.text;
                                  if (text == null || text.isEmpty) {
                                    showMessage(
                                      context,
                                      'There is no text on the clipboard.',
                                    );
                                    return;
                                  }
                                  final maximum = state.kind == ItemKind.text
                                      ? 6000
                                      : 2048;
                                  _controller.text = text.substring(
                                    0,
                                    text.length.clamp(0, maximum),
                                  );
                                  context.read<CaptureBloc>().add(
                                    CaptureValueChanged(_controller.text),
                                  );
                                } catch (_) {
                                  if (context.mounted) {
                                    showMessage(
                                      context,
                                      'Could not read the clipboard. Paste into the field instead.',
                                    );
                                  }
                                }
                              },
                        icon: const Icon(LucideIcons.clipboard, size: 16),
                        label: const Text('Paste from clipboard'),
                      ),
                    ] else ...[
                      Text(
                        'Try a sample',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      if (state.kind == ItemKind.photo)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: const SizedBox(
                            height: 165,
                            width: double.infinity,
                            child: PosterArtwork(variant: 'scenic'),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.colors.line),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.kind == ItemKind.audio
                                    ? LucideIcons.music
                                    : LucideIcons.fileText,
                                color: context.colors.iris,
                                size: 25,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.kind == ItemKind.audio
                                          ? 'An idea for the weekend'
                                          : 'Yank product brief.pdf',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      state.kind == ItemKind.audio
                                          ? '24-second instrumental sketch'
                                          : 'A short, readable design brief',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        'Add this sample to see how it behaves in your library.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            state.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.saving
                            ? null
                            : () => context.read<CaptureBloc>().add(
                                const CaptureSubmitted(),
                              ),
                        icon: state.saving
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.plus, size: 18),
                        label: Text(
                          state.saving ? 'Saving...' : 'Add to library',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
