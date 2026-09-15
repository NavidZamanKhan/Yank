# Validation record

## Executed in the authoring environment

| Check | Result |
| --- | --- |
| Pure Dart domain checks | 17 passed |
| Pure Dart repository checks | 8 passed |
| Dart formatter | All authored Dart files parsed and formatted |
| Shell setup scripts | Syntax checked with `bash -n` |
| Platform configuration script | Exercised against temporary host fixtures, including repeat execution |
| Assets and archive | Relative imports, WAV metadata, icon sizes, and ZIP integrity checked |

The domain checks exercise the real model and projection code: unchanged timeline after Yank, working-set order, archived search, multiword search, source filtering, deleted-item exclusion, timestamp round trips, link validation, and immutable projections.

The repository checks exercise the real demo repository with an in-memory store: simultaneous capture/update survival, reopen persistence, preserved capture timestamps, failed-write behavior, queue recovery, and Clear Yank retaining all records.

These checks ran with a local Dart SDK directly, without substituting fake implementations of the domain code. They do not validate plugin behavior or rendered Flutter layouts.

## Included but not executed

`test/library_repository_test.dart` covers mutation concurrency and storage failure. `test/library_bloc_test.dart` covers rapid double toggles and cancelled downloads. `test/widget_test.dart` checks library/search behavior and layout exceptions at widths 320, 390, and 1440 using an injected audio adapter.

The environment could not download Flutter dependencies. A network escalation was rejected by automatic approval review because sandbox approvals were disabled. Consequently, full `flutter analyze`, `flutter test`, Flutter compilation, and device/browser rendering were not completed. There is no APK, IPA, signed Mac binary, or claimed device screenshot in this archive.

## Run locally

```bash
bash tool/bootstrap.sh
bash tool/verify.sh
```

For the dependency-free core checks alone, invoke the installed Dart binary directly:

```bash
dart tool/domain_checks.dart
dart tool/repository_checks.dart
```

## Device review

Before treating the prototype as visually verified, check the following on a phone-sized viewport and a Mac window:

- Scroll the mixed feed in light and dark modes, including larger system text.
- Filter by kind/source, search archived content, and clear an empty result.
- Yank twice quickly and confirm the original timeline does not move.
- Add link/text/sample media, relaunch, and confirm local metadata survives.
- Archive/delete and Undo; confirm reset requires confirmation.
- Play, pause, seek, replay to completion, and navigate with the mini player.
- Remove a simulated download, cancel its replacement, and try offline mode.
- Open a link, copy text, and invoke system sharing on the actual target platform.
- Check reduced motion, keyboard focus, safe areas, preview sheets, and the wide side preview.

Do not interpret simulated transfer behavior as a tested production cache or synchronization system.
