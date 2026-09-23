import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LocalPathResolver {
  LocalPathResolver._();

  static Directory? _documentsDirectory;
  static Directory? _containerDirectory;
  static Directory? _temporaryDirectory;

  static Directory? get documentsDirectory => _documentsDirectory;
  static Directory? get containerDirectory => _containerDirectory;
  static Directory? get temporaryDirectory => _temporaryDirectory;

  static Future<void> initialize() async {
    try {
      _documentsDirectory = await getApplicationDocumentsDirectory();
      _containerDirectory = _documentsDirectory?.parent;
    } catch (e) {
      debugPrint('LocalPathResolver failed to get documents dir: $e');
    }

    try {
      _temporaryDirectory = await getTemporaryDirectory();
    } catch (e) {
      debugPrint('LocalPathResolver failed to get temporary dir: $e');
    }
  }

  @visibleForTesting
  static void setDirectories({
    Directory? documentsDirectory,
    Directory? temporaryDirectory,
  }) {
    _documentsDirectory = documentsDirectory;
    _containerDirectory = documentsDirectory?.parent;
    _temporaryDirectory = temporaryDirectory;
  }

  @visibleForTesting
  static void reset() {
    _documentsDirectory = null;
    _containerDirectory = null;
    _temporaryDirectory = null;
  }

  /// Resolves a file path that may be a stale absolute path (e.g. from an earlier iOS
  /// sandbox container), a relative path, or a direct filename.
  /// Returns the existing [File], or null if no corresponding file exists.
  static File? resolveFile(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) {
      return null;
    }

    final clean = rawPath.trim().replaceFirst(RegExp(r'^file://'), '');
    final direct = File(clean);
    if (direct.existsSync()) {
      return direct;
    }

    // 1. iOS sandbox container UUID translation:
    // When an app is reinstalled, updated, or accessed from a Share Extension on iOS,
    // the container UUID changes while files remain in Documents or tmp.
    final appMatch = RegExp(r'/Application/[^/]+/(.+)$').firstMatch(clean);
    if (appMatch != null) {
      final relativePortion = appMatch.group(1);
      if (relativePortion != null && relativePortion.isNotEmpty) {
        if (_containerDirectory != null) {
          final cand = File('${_containerDirectory!.path}/$relativePortion');
          if (cand.existsSync()) {
            return cand;
          }
        }
        if (_documentsDirectory != null &&
            relativePortion.startsWith('Documents/')) {
          final sub = relativePortion.substring('Documents/'.length);
          final cand = File('${_documentsDirectory!.path}/$sub');
          if (cand.existsSync()) {
            return cand;
          }
        }
        if (_temporaryDirectory != null &&
            relativePortion.startsWith('tmp/')) {
          final sub = relativePortion.substring('tmp/'.length);
          final cand = File('${_temporaryDirectory!.path}/$sub');
          if (cand.existsSync()) {
            return cand;
          }
        }
      }
    }

    // 2. Android app storage translation:
    final androidMatch = RegExp(r'/app_flutter/(.+)$').firstMatch(clean);
    if (androidMatch != null && _documentsDirectory != null) {
      final relativePortion = androidMatch.group(1);
      if (relativePortion != null && relativePortion.isNotEmpty) {
        final cand = File('${_documentsDirectory!.path}/$relativePortion');
        if (cand.existsSync()) {
          return cand;
        }
      }
    }

    // 3. Basename lookup across standard capture directories:
    final fileName = clean.split(RegExp(r'[/\\]')).last;
    if (fileName.isNotEmpty && fileName != clean) {
      final candidates = <File>[
        if (_documentsDirectory != null) ...[
          File('${_documentsDirectory!.path}/captures/$fileName'),
          File('${_documentsDirectory!.path}/$fileName'),
        ],
        if (_temporaryDirectory != null) ...[
          File('${_temporaryDirectory!.path}/captures/$fileName'),
          File('${_temporaryDirectory!.path}/yank_captures/$fileName'),
          File('${_temporaryDirectory!.path}/$fileName'),
        ],
        File('${Directory.systemTemp.path}/captures/$fileName'),
        File('${Directory.systemTemp.path}/yank_captures/$fileName'),
        File('${Directory.systemTemp.path}/$fileName'),
      ];

      for (final candidate in candidates) {
        try {
          if (candidate.existsSync()) {
            return candidate;
          }
        } catch (_) {}
      }
    }

    // 4. Relative path check against documents and temporary directories:
    if (!clean.startsWith('/')) {
      final relCandidates = <File>[
        if (_documentsDirectory != null)
          File('${_documentsDirectory!.path}/$clean'),
        if (_temporaryDirectory != null)
          File('${_temporaryDirectory!.path}/$clean'),
        File('${Directory.systemTemp.path}/$clean'),
      ];
      for (final candidate in relCandidates) {
        try {
          if (candidate.existsSync()) {
            return candidate;
          }
        } catch (_) {}
      }
    }

    return null;
  }

  /// Resolves the raw path and returns the resolved string path if found, or null.
  static String? resolve(String? rawPath) => resolveFile(rawPath)?.path;

  /// Resolves the raw path or returns the original string if resolution fails.
  static String resolveOrOriginal(String rawPath) =>
      resolve(rawPath) ?? rawPath;
}
