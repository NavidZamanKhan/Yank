# Architecture

The app separates feature state, UI, and storage so the interface can be reused when real integrations are added.

## State ownership

| Boundary | Responsibility |
| --- | --- |
| `YankApp` | Inject repositories; own feature BLoCs; compose theme and navigation |
| `LibraryBloc` | Section, filters, search, item actions, selected preview, notices, simulated local availability |
| `CaptureBloc` | Input, validation, submitting, errors, and a successful local capture |
| `AudioBloc` | One active track, playback commands, position, duration, and errors |
| `SettingsBloc` | Persisted appearance and reduced motion |
| Widgets | Layout and transient pointer, text-controller, focus, and scrub state |

Feature state changes go through events. Widgets do not mutate library records directly. Stateful widgets only retain short-lived presentation state.

## Library and device availability

`YankItem` is independent of Flutter and plugins. It holds content metadata, `createdAt`, working-set membership through nullable `yankedAt`, and archive/deletion flags. `createdAt` always controls the main timeline. Yanking creates no duplicate record and changes no capture timestamp.

`LibraryProjection` derives immutable views. Normal Library excludes archived items; a text search includes them. Yank excludes archived and deleted items and sorts by the most recent `yankedAt`. Equal timestamps have a stable ID tie-break. Source chips are derived from the current section's links.

The device map lives separately in `LibraryState`, indexed by item ID. It is intentionally absent from item JSON. Removing a local copy changes only this map. The demo uses cancellable timers to illustrate downloads; it does not claim to manage actual files or cache capacity.

## Persistence and concurrency

`LibraryRepository` exposes snapshots, changes, item updates, Clear Yank, and reset. `DemoLibraryRepository` implements it over a `MetadataStore`. The app uses `PreferencesMetadataStore`; checks use `MemoryMetadataStore`.

The repository serializes mutations because Capture and Library can save concurrently. Each operation derives its next list from the current snapshot inside the queue, persists it, and only then publishes it. A failed write preserves the previous snapshot and leaves the queue usable. Library event handling is sequential too, which makes a rapid double toggle behave like two ordered actions. Repository notifications refresh from the latest snapshot to avoid replaying an obsolete queued update.

Preferences are appropriate here for small demo records, not a production capture journal or a database for large libraries. There is no remote durability guarantee. Captured text/URLs and sample metadata are local to this installation. No binaries are serialized into preferences.

Archive/delete notices carry an undo snapshot. Delete is a soft deletion in this demo store. A reset replaces the sample library after confirmation; appearance is independent. Startup offers retry and a confirmed reset if local metadata cannot be read.

## Audio and lifecycle

`AudioRepository` isolates the player plugin. `AssetAudioRepository` wraps `audioplayers`; the widget test injects a silent adapter. Audio events are serialized and player frames carry an item ID, so frames from another track are ignored. Scrubbing commits one seek when the gesture ends.

Download timers and stream subscriptions are cancelled on disposal. Removing a playing item or its simulated local copy stops the player. Archive can keep playing because the item remains available. A capture already submitted to the repository can finish if the sheet is dismissed.

## Replacing the demo adapters

Keep the widgets and projections. Replace `LibraryRepository` with a local database-backed implementation and a separate synchronization layer. Treat the existing metadata model as a starting point; production ownership, MIME types, sync timestamps, binary references, and migrations still need design.

Introduce a device cache repository for real local paths, transfers, protected uploads, and eviction. Its state must stay separate from synchronized item metadata. Add native capture adapters at the capture boundary. The current sample-media capture branch should be replaced with platform pickers or share intake when that phase is authorized.

`LibraryRepository.reset()` is explicitly a demo convenience. Do not map it to a destructive production account action. No Firebase configuration, credentials, native sharing extensions, or production cache policies are included.
