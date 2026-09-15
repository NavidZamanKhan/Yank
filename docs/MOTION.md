# Motion

Motion should confirm an action without competing with content.

| Interaction | Implementation | Reason |
| --- | --- | --- |
| Press capture or Yank | Scale to 0.965 in 85 ms; release over 240 ms with `easeOutBack` | A small physical response without shifting adjacent layout |
| Change feed section/type/source | 150 ms fade through `AnimatedSwitcher` | Keep navigation quick and understandable |
| Change theme | 220 ms theme interpolation | Avoid a sudden color flash |
| Audio waveform | Real playback position colors a decorative envelope | Feedback is tied to actual playback |
| Seek audio | Drag locally, dispatch on gesture end | Avoid a queue of native seek calls |
| Simulated transfer | Progress indicator with explicit Cancel | Make waiting and cancellation understandable |

`lib/core/motion/yank_motion.dart` centralizes shared durations and press behavior. Its reserved panel duration is 280 ms; current modal sheets use Flutter's route transitions.

The app combines its Reduce motion preference with the operating system's `disableAnimations` setting. Custom press scaling and feed transitions are removed when reduced motion is active. The app preference also makes theme transitions immediate. Standard Flutter route and control behavior is delegated to the framework; it has not been verified on devices here.

Haptic selection feedback accompanies the card's Yank action, and light feedback accompanies successful capture. Haptics are not the only indication of success: selection state, notices, and navigation provide visible feedback.
