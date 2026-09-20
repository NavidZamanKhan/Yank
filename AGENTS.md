# Yank Project Operating Rules

These rules are strictly enforced for all development tasks in the yank workspace:

1. STRICT NO CODING WITHOUT EXPLICIT COMMAND:
   - Absolutely NO writing, editing, or deleting code without an explicit user command containing "code".
   - When the user asks questions, reports bugs, pastes logs, or asks why something is failing, perform ONLY an investigation.
   - Never assume permission to code. Always stop after investigation or planning and wait for explicit user clearance ("code").

2. Branch & Push Policy:
   - All code changes, commits, and pushes must ALWAYS target the playground branch.
   - Push to playground after each implementation.
   - Never push directly to main.

3. Merge Policy:
   - Only merge playground into main when the user explicitly instructs to merge.

4. "investigate" Trigger:
   - When the user says "investigate", do NOT write or modify code under any circumstances.
   - Perform an exhaustive, deep-dive root cause investigation with thorough analysis and evidence.

5. "no code" Trigger:
   - When the user says "no code", do NOT write code.
   - Provide a breakdown of possible problems along with actionable solution paths.

6. Formatting & Commit Style Standard:
   - Absolutely zero emojis across documentation, commit messages, code comments, and chat responses.
   - Absolutely zero em dashes. Use standard hyphens and colons only.
   - Commit Message Conventional Style:
     Follow Conventional Commits style with lowercase indicators prefixing the commit subject:
     - feat: (new features, UI capabilities, or major functionality)
     - fix: (bug fixes, defect corrections, edge cases)
     - refactor: (code restructuring without behavioral changes)
     - perf: (performance enhancements and optimizations)
     - style: (visual styling, spacing, colors, animation adjustments)
     - docs: (documentation, README, roadmap updates)
     - test: (unit, widget, or integration tests)
     - chore: (dependencies, configuration, tooling)
     Format: `<indicator>: <description in imperative lowercase>`
     Examples:
     - feat: add support for capturing and restoring local file references in clipboard history
     - perf: optimize image decoding memory footprint and eliminate paste latency
     - style: adjust card depth recession to translateY 55 and smooth reverse closing animation
     - docs: update README to reflect new keyboard shortcuts and search functionality

7. Cost Constraint ($0 Infrastructure Budget):
   - Strictly enforce a $0 infrastructure budget.
   - Rely exclusively on free tiers: Firebase Authentication, Cloud Firestore offline-enabled streams, Cloud Storage for Firebase, and local device processing.

8. State Management Standard:
   - State management must exclusively use BLoC (flutter_bloc / bloc).
   - Clean Separation: Event -> Bloc -> State for all interactive features and modules with unidirectional data flow.

9. Modularity & Reusability Standard:
   - Code must ALWAYS be modular, concise, and reusable.
   - Strictly prohibit monolithic files.
   - Break down every feature into dedicated directories:
     - bloc/ (Events, States, Bloc)
     - views/ (Main page / view container)
     - widgets/ (Isolated sub-widgets, cards, headers, inputs)
     - models/ (Data schemas)
     - repositories/ (Data sources & Firebase communication)
   - Generic/shared UI components must reside in lib/core/widgets/ (e.g. YankButton, YankCard, YankBadge, YankInput).

10. Workspace & Project Context:
    - Target mobile and desktop app codebase is yank, a cross-device universal capture inbox for links, photos, audio, files, and text across iOS, Android, and macOS.
    - Built with Flutter, Dart, BLoC, Firebase (Auth, Firestore, Cloud Storage), and local database persistence.
    - Prototype Reference: A design prototype dummy Flutter app will be placed into the workspace for design and architectural inspiration.

11. Simulator & Device Session Policy:
    - Never terminate, stop, relaunch, or execute flutter run on the user's active simulator or physical device without explicit permission.
    - If a task genuinely demands interacting with or relaunching the active simulator, ask for explicit permission first before proceeding.
    - Automated verification must otherwise run exclusively via headless command-line tests (flutter test) without disturbing active application sessions.

12. Core Architecture and Data Safety Rules:
    - The library belongs to the account. The cache belongs to the device. Never confuse these concepts.
    - Device cache target is approximately 500 MB, with an upper cleanup watermark around 600 MB.
    - When cleanup starts, reclaim space safely toward 480-500 MB using an LRU-like policy.
    - NEVER evict unsynced content. A binary is eligible for eviction only when uploadState == confirmedRemote.
    - Global library ordering is canonical and chronological. Cache state must never affect global sort order.
    - Capture comes first. Local persistence is mandatory before cloud upload. Capture must work seamlessly offline.
    - Working set "Yank": semantic working set ordered by yankedAt descending. Unyank removes from working set without deleting or reordering the main library.
    - Search is local, offline-capable, cross-content, and does not require downloading binary payloads.
    - File transfers: stream directly to and from disk. Never load large files (e.g. 400 MB) entirely into RAM.

13. Absolute Rule Enforcement:
    - Every rule defined in this document must be strictly obeyed at all costs without exception.
    - Never bypass, skip, relax, or deprioritize any rule under any circumstance.
    - When user queries ask questions, propose ideas, or request feedback, answer and discuss first. Never write code without explicit, unambiguous clearance.
    - Zero tolerance for rule violations.
