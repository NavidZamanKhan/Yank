# Design direction

Simple, useful, and quietly distinctive. The approved direction uses warm stone and smoky iris, compact content, and restrained physical feedback. Orange accents, oversized hero areas, board layouts, and decorative gradients are absent.

## Color tokens

| Token | Light | Dark | Purpose |
| --- | --- | --- | --- |
| Canvas | `#F4F3F0` | `#1B1A20` | App background |
| Surface | `#FFFFFF` | `#24232B` | Cards and previews |
| Ink | `#282631` | `#F1EEF6` | Primary text |
| Muted | `#726C7B` | `#B0AAB9` | Metadata and secondary controls |
| Iris | `#6250B5` | `#B4A3F4` | Actions, selection, playback |
| Tint | `#EAE6F5` | `#373046` | Selected surfaces |
| Line | `#E2DFE6` | `#39353F` | Fine borders |
| Search | `#EBE9E7` | `#2C2932` | Input surface |

These tokens live in a `ThemeExtension`; feature widgets read semantic colors from the current theme. The default is light. Dark and system modes are available in Settings.

## Layout and density

Mobile puts the wordmark and settings above search, followed by content filters and a chronological feed. Library and Yank sit in the bottom navigation beside the iris capture button. Archive is accessible through Settings.

The feed targets roughly four to five mixed items in a typical phone viewport, depending on safe areas and text scale. Compact link/file rows sit beside shallow, full-width image previews and playable audio rows. Cards have 14 px corners, 1 px borders, and no elevation. The gap between cards is 9 px. Photo previews in the feed are 118 px tall. Primary controls have touch targets around 44 px or larger.

At 900 px, a 216 px sidebar replaces bottom navigation. The feed stays constrained to 670 px. At 1180 px, selecting an item can open a 370 px side preview. Narrower windows use a bottom sheet. The generated Mac host opens at 1200 × 820.

## Type and content

The wordmark is compact lowercase text with tight tracking. Card titles use 14 px type with a 1.4 line height; metadata uses 11–12 px type. Headings use 20–26 px with modest tracking. The app uses Flutter's platform font defaults and requires no network font loading.

Sample content mixes useful links, short thoughts, a readable brief, original posters, and an instrumental audio sketch. Decorative poster text is part of the artwork; card titles provide the content label. The visual system belongs to the app chrome, while the artwork can carry a little more personality.

## Interaction rules

- Tap a link to open its original. Use the menu or long press for saved details.
- Use the visible pull arrow to keep an item in Yank. Swipe right is the shortcut.
- Library order remains chronological when working-set membership changes.
- Swipe left archives or restores; delete remains an explicit menu action with Undo.
- Search works across saved metadata without fetching or downloading a binary.
- Empty views give one relevant next action: clear filters, add something, or browse Library.

Selection is represented by icon/text semantics and color. Text can scale, preview bodies scroll, and important icon controls have tooltips. Actual device and screen-reader verification remains part of the local validation checklist.
