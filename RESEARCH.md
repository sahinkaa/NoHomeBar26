# iOS 26 inspection and hook scope

The reference is the local Xcode DeviceSupport symbol set for iPhone12,5 running iOS 26.0.1 (23A355). No Apple binary is included in the source or package. All addresses below are research references only; the runtime resolves class and method names rather than using executable addresses.

## Native visual factories

SpringBoard's `SBHomeGrabberView` creates the app/system home indicator visuals through:

- `_newPillView` at `0x21d570758`.
- `_newHomeAffordanceView` at `0x21d5708d8`.

CoverSheet's `CSHomeAffordanceView` creates the lock-screen variants through:

- `_newHomeAffordanceView` at `0x21d338148`.
- `_newStaticColorPillView` at `0x21d3381a4`.
- `_newLumaDodgePillView` at `0x21d3381e8`.
- `_newAlwaysOnHomeAffordancePillView` at `0x21d33822c`.

All six reference method encodings are `@16@0:8`. The reference `-[UIView(Rendering) setAlpha:]` encoding is `v24@0:8d16`. The runtime checks return and argument types before installing each hook.

The factory originals are called once. A nonnil UIView result gets a private associated-object marker and alpha 0. Nil and unexpected result types pass through. An off-main factory invocation leaves the returned view unchanged. The real view object, its ownership and its geometry remain native.

## Persistent visual suppression

`setAlpha:` is hooked on four concrete visual classes: `MTLumaDodgePillView`, `MTStaticColorPillView`, `CSAlwaysOnHomeAffordancePillView` and `SBFHomeAffordanceView`. Only marked results from the six home-indicator factories are clamped to 0. Unmarked objects receive their original alpha arguments unchanged.

Each concrete class has its own typed original pointer and replacement wrapper. This avoids recursive original lookup when a visual class inherits from another hooked class. UIKit's UIView implementation is not globally replaced. No CALayer hook or per-instance class swapping is used.

The parent home gesture containers are never hidden. The tweak changes no safe area, frame, gesture recognizer, edge protection, hit-test method, home indicator auto-hide preference or size setting. Native animations and lifecycle methods are not skipped. This design is intended to preserve gestures, but that needs device verification.

## Loading and overhead

Injection is limited to SpringBoard. It is not loaded into every app or into a daemon. Hook installation is idempotent. An image-load callback schedules retries on the main queue outside dyld's loader lock if classes become available later.

There is no Settings pane, preference read, polling loop or recurring timer. The visual setter checks one associated marker then forwards one original setter call. Diagnostics are written at hook installation and on the first visual returned by each factory, rather than on each layout or opacity update. Battery impact is not benchmarked.

Historical tweaks such as [NoClutter](https://github.com/QuixThe2nd/NoClutter/blob/master/Tweak.xm) modify shared MaterialKit size settings to hide the bar. This implementation is independently written around the inspected indicator factories and does not change those shared dimensions.

## Device status

This release targets iOS 26.0 or later. The Mac fixtures and package checks passed. Home Screen, apps, app switcher, keyboard, lock screen, rotations, unlocking and navigation gestures still need checking on the user's device. No broad compatibility claim is made.
