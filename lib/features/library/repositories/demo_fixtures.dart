import 'package:yank/features/library/models/yank_item.dart';

abstract final class DemoFixtures {
  static const brief = '''Yank
See it. Yank it. Find it anywhere.

01  The idea
Capture things while they matter. A link, an image, a sound, a file, or a few words. Find them again without remembering where you left them.

02  Keep it close
Your library remembers when something arrived. Yank is the smaller set you are using right now. Adding an item to Yank leaves its place in the timeline unchanged.

03  A little personality
Stone surfaces, smoky iris accents, sharp icons, and movement that follows your hand. Every kind of content gets enough space to be recognized.

04  Across your day
Find a reference on your phone. Use it at your desk. Keep the useful things close.

Design sample document. September 2026.''';

  static const demoIds = {
    'flutter',
    'poster',
    'audio',
    'brief',
    'thought',
    'bloc',
    'scenic',
    'video',
    'list',
    'type',
    'design',
    'checklist',
    'archive',
  };

  static List<YankItem> build([DateTime? clock]) {
    final now = clock ?? DateTime.now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
    return [
      YankItem(
        id: 'flutter',
        kind: ItemKind.link,
        title: 'Flutter animation guide',
        createdAt: ago(12),
        url: 'https://docs.flutter.dev/ui/animations',
        body: 'A reference for transitions, curves, and movement that feels natural.',
        yankedAt: ago(4),
      ),
      YankItem(
        id: 'poster',
        kind: ItemKind.photo,
        title: 'A little visual inspiration',
        createdAt: ago(28),
        artwork: 'slow',
        sizeBytes: 420000,
      ),
      YankItem(
        id: 'audio',
        kind: ItemKind.audio,
        title: 'An idea for the weekend',
        createdAt: ago(46),
        audioAsset: 'audio/weekend.wav',
        durationSeconds: 24,
        body: 'A small, original instrumental sketch.',
        sizeBytes: 768044,
      ),
      YankItem(
        id: 'brief',
        kind: ItemKind.file,
        title: 'Yank product brief.pdf',
        createdAt: ago(60),
        body: brief,
        sizeBytes: 1800000,
        yankedAt: ago(8),
      ),
      YankItem(
        id: 'thought',
        kind: ItemKind.text,
        title: 'Keep the useful things close.',
        createdAt: ago(120),
        body: 'Keep the useful things close. Give everything else enough room to breathe.',
      ),
      YankItem(
        id: 'bloc',
        kind: ItemKind.link,
        title: 'A better way to handle state',
        createdAt: ago(1500),
        url: 'https://github.com/felangel/bloc',
        body: 'Patterns for predictable state and reusable features.',
      ),
      YankItem(
        id: 'scenic',
        kind: ItemKind.photo,
        title: 'Take the scenic route',
        createdAt: ago(1540),
        artwork: 'scenic',
        sizeBytes: 640000,
      ),
      YankItem(
        id: 'video',
        kind: ItemKind.link,
        title: 'Something for a slow evening',
        createdAt: ago(1700),
        url: 'https://www.youtube.com/@NPRMusic',
        body: 'Tiny Desk concerts and live performances.',
      ),
      YankItem(
        id: 'list',
        kind: ItemKind.text,
        title: 'For a quieter Sunday',
        createdAt: ago(1800),
        body: 'Coffee. A long walk. A little music. Leave the laptop at home for once.',
      ),
      YankItem(
        id: 'type',
        kind: ItemKind.photo,
        title: 'Form, function, and a little feeling',
        createdAt: ago(2800),
        artwork: 'form',
        sizeBytes: 510000,
      ),
      YankItem(
        id: 'design',
        kind: ItemKind.link,
        title: 'Interfaces worth studying',
        createdAt: ago(3000),
        url: 'https://www.instagram.com/design',
        body: 'A saved design reference.',
      ),
      YankItem(
        id: 'checklist',
        kind: ItemKind.file,
        title: 'Weekend checklist.pdf',
        createdAt: ago(4200),
        sizeBytes: 240000,
        body: 'A little reset\n\nTidy the desk.\nBack up the photographs.\nFinish the small things.\nMake time for a walk.\n\nLeave a little room for doing nothing.',
      ),
      YankItem(
        id: 'archive',
        kind: ItemKind.text,
        title: 'The first rough idea',
        createdAt: ago(6000),
        body: 'What if sharing something to yourself only took one action?',
        archived: true,
      ),
    ];
  }
}
