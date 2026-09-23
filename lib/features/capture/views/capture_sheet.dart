import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:yank/core/motion/yank_motion.dart';
import 'package:yank/core/theme/yank_theme.dart';
import 'package:yank/core/widgets/yank_controls.dart';
import 'package:yank/core/widgets/yank_feedback.dart';
import 'package:yank/features/capture/bloc/capture_bloc.dart';
import 'package:yank/features/library/models/yank_item.dart';
import 'package:yank/features/library/repositories/library_repository.dart';

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
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      ),
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
  final _valueController = TextEditingController();
  final _titleController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _valueController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  bool _isPicking = false;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked != null) {
        final file = File(picked.path);
        final size = await file.length();
        if (!mounted) return;
        context.read<CaptureBloc>().add(
              CaptureFileSelected(
                filePath: picked.path,
                fileName: picked.name,
                fileSize: size,
              ),
            );
      }
    } catch (e) {
      if (e is PlatformException && e.code == 'multiple_request') {
        return;
      }
      if (mounted) {
        showMessage(context, 'Could not access photo: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      } else {
        _isPicking = false;
      }
    }
  }

  Future<void> _pickAudio() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'm4a',
          'wav',
          'aac',
          'flac',
          'ogg',
          'caf',
          'aiff',
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!mounted) return;
          context.read<CaptureBloc>().add(
                CaptureFileSelected(
                  filePath: file.path!,
                  fileName: file.name,
                  fileSize: file.size,
                ),
              );
        }
      }
    } catch (e) {
      if (e is PlatformException && e.code == 'multiple_request') {
        return;
      }
      if (mounted) {
        showMessage(context, 'Could not select audio: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      } else {
        _isPicking = false;
      }
    }
  }

  Future<void> _pickFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          if (!mounted) return;
          context.read<CaptureBloc>().add(
                CaptureFileSelected(
                  filePath: file.path!,
                  fileName: file.name,
                  fileSize: file.size,
                ),
              );
        }
      }
    } catch (e) {
      if (e is PlatformException && e.code == 'multiple_request') {
        return;
      }
      if (mounted) {
        showMessage(context, 'Could not select file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      } else {
        _isPicking = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<CaptureBloc, CaptureState>(
        listenWhen: (old, next) => !old.saved && next.saved,
        listener: (context, state) {
          HapticFeedback.lightImpact();
          FocusScope.of(context).unfocus();
          Navigator.pop(context, true);
        },
        builder: (context, state) {
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
                                (kind) {
                                  final isSelected = state.kind == kind;
                                  final icon = switch (kind) {
                                    ItemKind.link => LucideIcons.link,
                                    ItemKind.photo => LucideIcons.images,
                                    ItemKind.audio => LucideIcons.music,
                                    ItemKind.file => LucideIcons.fileText,
                                    ItemKind.text => LucideIcons.type,
                                  };
                                  return PressScale(
                                    child: ChoiceChip(
                                      avatar: Icon(
                                        icon,
                                        size: 15,
                                        color: isSelected
                                            ? context.colors.iris
                                            : context.colors.muted,
                                      ),
                                      label: Text(
                                        kind == ItemKind.link
                                            ? 'Link'
                                            : kind == ItemKind.photo
                                                ? 'Image'
                                                : kind == ItemKind.file
                                                    ? 'File'
                                                    : kind.label,
                                      ),
                                      selected: isSelected,
                                      showCheckmark: false,
                                      selectedColor: context.colors.tint,
                                      backgroundColor: context.colors.surface,
                                      side: BorderSide(
                                        color: isSelected
                                            ? context.colors.tint
                                            : context.colors.line,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      labelStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? context.colors.iris
                                            : context.colors.muted,
                                      ),
                                      onSelected: state.saving
                                          ? null
                                          : (_) {
                                              HapticFeedback.lightImpact();
                                              _valueController.clear();
                                              _titleController.clear();
                                              context.read<CaptureBloc>().add(
                                                    CaptureKindChanged(kind),
                                                  );
                                            },
                                    ),
                                  );
                                },
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        if (state.kind == ItemKind.link ||
                            state.kind == ItemKind.text) ...[
                          TextField(
                            controller: _valueController,
                            enabled: !state.saving,
                            autofocus: false,
                            maxLines: state.kind == ItemKind.text ? 5 : 2,
                            minLines: state.kind == ItemKind.text ? 4 : 1,
                            maxLength:
                                state.kind == ItemKind.text ? 6000 : 2048,
                            keyboardType: state.kind == ItemKind.link
                                ? TextInputType.url
                                : TextInputType.multiline,
                            textCapitalization: state.kind == ItemKind.text
                                ? TextCapitalization.sentences
                                : TextCapitalization.none,
                            onChanged: (value) =>
                                context.read<CaptureBloc>().add(
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          YankButton.subtle(
                            onPressed: state.saving
                                ? null
                                : () async {
                                    try {
                                      final clipboard = await Clipboard.getData(
                                        Clipboard.kTextPlain,
                                      );
                                      if (!context.mounted) return;
                                      final text = clipboard?.text;
                                      if (text == null || text.isEmpty) {
                                        showMessage(
                                          context,
                                          'There is no text on the clipboard.',
                                        );
                                        return;
                                      }
                                      final maximum =
                                          state.kind == ItemKind.text
                                              ? 6000
                                              : 2048;
                                      _valueController.text = text.substring(
                                        0,
                                        text.length.clamp(0, maximum),
                                      );
                                      context.read<CaptureBloc>().add(
                                            CaptureValueChanged(
                                              _valueController.text,
                                            ),
                                          );
                                    } catch (_) {
                                      if (context.mounted) {
                                        showMessage(
                                          context,
                                          'Could not read clipboard.',
                                        );
                                      }
                                    }
                                  },
                            icon: LucideIcons.clipboard,
                            label: 'Paste from clipboard',
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _titleController,
                            enabled: !state.saving,
                            maxLength: 120,
                            onChanged: (title) =>
                                context.read<CaptureBloc>().add(
                                      CaptureTitleChanged(title),
                                    ),
                            decoration: const InputDecoration(
                              labelText: 'Title or note (optional)',
                              hintText: 'Leave empty for automatic title',
                              counterText: '',
                            ),
                          ),
                        ] else if (state.kind == ItemKind.photo) ...[
                          if (state.filePath == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.colors.line),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: context.colors.tint,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      LucideIcons.images,
                                      size: 26,
                                      color: context.colors.iris,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add an image to your library',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: YankButton.secondary(
                                          onPressed: (state.saving || _isPicking)
                                              ? null
                                              : () => _pickImage(
                                                    ImageSource.gallery,
                                                  ),
                                          icon: LucideIcons.image,
                                          label: 'Photos',
                                          fullWidth: true,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: YankButton.secondary(
                                          onPressed: (state.saving || _isPicking)
                                              ? null
                                              : () => _pickImage(
                                                    ImageSource.camera,
                                                  ),
                                          icon: LucideIcons.camera,
                                          label: 'Camera',
                                          fullWidth: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 180,
                                    width: double.infinity,
                                    child: Image.file(
                                      File(state.filePath!),
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: PressScale(
                                      child: IconButton.filled(
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.black.withValues(alpha: 0.6),
                                        ),
                                        onPressed: state.saving
                                            ? null
                                            : () => context
                                                .read<CaptureBloc>()
                                                .add(const CaptureFileCleared()),
                                        icon: const Icon(
                                          LucideIcons.x,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    state.fileName ?? 'Selected photo',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (state.fileSize > 0)
                                  Text(
                                    _formatBytes(state.fileSize),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              enabled: !state.saving,
                              maxLength: 120,
                              onChanged: (title) =>
                                   context.read<CaptureBloc>().add(
                                         CaptureTitleChanged(title),
                                       ),
                              decoration: const InputDecoration(
                                labelText: 'Caption or title (optional)',
                                hintText: 'What is this photo about?',
                                counterText: '',
                              ),
                            ),
                          ],
                        ] else if (state.kind == ItemKind.audio) ...[
                          if (state.filePath == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.colors.line),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: context.colors.tint,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      LucideIcons.music,
                                      size: 26,
                                      color: context.colors.iris,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose an audio track or voice note',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  YankButton.secondary(
                                    onPressed: (state.saving || _isPicking)
                                        ? null
                                        : _pickAudio,
                                    icon: LucideIcons.fileAudio,
                                    label: 'Browse audio files',
                                    fullWidth: true,
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.colors.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: context.colors.tint,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      LucideIcons.music,
                                      size: 22,
                                      color: context.colors.iris,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.fileName ?? 'Audio track',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (state.fileSize > 0)
                                          Text(
                                            _formatBytes(state.fileSize),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  PressScale(
                                    child: IconButton(
                                      onPressed: state.saving
                                          ? null
                                          : () => context
                                              .read<CaptureBloc>()
                                              .add(const CaptureFileCleared()),
                                      icon: const Icon(LucideIcons.x, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              enabled: !state.saving,
                              maxLength: 120,
                              onChanged: (title) =>
                                  context.read<CaptureBloc>().add(
                                        CaptureTitleChanged(title),
                                      ),
                              decoration: const InputDecoration(
                                labelText: 'Audio title (optional)',
                                hintText: 'Name of the recording or track',
                                counterText: '',
                              ),
                            ),
                          ],
                        ] else if (state.kind == ItemKind.file) ...[
                          if (state.filePath == null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 22,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.colors.line),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: context.colors.tint,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      LucideIcons.fileText,
                                      size: 26,
                                      color: context.colors.iris,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Choose a document or file',
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  YankButton.secondary(
                                    onPressed: (state.saving || _isPicking)
                                        ? null
                                        : _pickFile,
                                    icon: LucideIcons.fileUp,
                                    label: 'Browse files',
                                    fullWidth: true,
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.colors.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: context.colors.tint,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      LucideIcons.fileText,
                                      size: 22,
                                      color: context.colors.iris,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          state.fileName ?? 'Document',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (state.fileSize > 0)
                                          Text(
                                            _formatBytes(state.fileSize),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  PressScale(
                                    child: IconButton(
                                      onPressed: state.saving
                                          ? null
                                          : () => context
                                              .read<CaptureBloc>()
                                              .add(const CaptureFileCleared()),
                                      icon: const Icon(LucideIcons.x, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _titleController,
                              enabled: !state.saving,
                              maxLength: 120,
                              onChanged: (title) =>
                                  context.read<CaptureBloc>().add(
                                        CaptureTitleChanged(title),
                                      ),
                              decoration: const InputDecoration(
                                labelText: 'File title (optional)',
                                hintText: 'Name of the document',
                                counterText: '',
                              ),
                            ),
                          ],
                        ],
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              state.error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        YankButton(
                          onPressed: state.saving
                              ? null
                              : () => context.read<CaptureBloc>().add(
                                    const CaptureSubmitted(),
                                  ),
                          icon: LucideIcons.plus,
                          label: 'Add to library',
                          loading: state.saving,
                          fullWidth: true,
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
