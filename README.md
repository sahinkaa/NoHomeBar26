# No Home Bar 26

Hide the home indicator throughout iOS while keeping swipe gestures.

Version 1.0 by sahinkaa. Requires iOS 26.0 or later.

[Download version 1.0](https://github.com/sahinkaa/NoHomeBar26/releases/tag/v1.0)

Device behavior has not yet been confirmed. Both packages passed the host control-flow checks and offline package validation. Those checks do not establish device compatibility.

There is no settings pane. Installing enables the feature. Uninstalling restores the native indicator after a respring.

## Install

1. For a clean test, turn off Lynx's home bar feature or uninstall Lynx. This avoids having two tweaks change the same indicator.
2. Install the package matching your jailbreak through Sileo:
   - Native RootHide: `com.sahinkaa.nohomebar26_1.0_iphoneos-arm64e.deb`. Install directly without RootHide Patcher.
   - Standard rootless: `com.sahinkaa.nohomebar26_1.0_iphoneos-arm64.deb`.
3. Respring once to load the tweak into SpringBoard.

The first intended setup is iPhone 11 Pro Max running iOS 26.0.1 with Dopamine 3 RootHide. Both packages target iOS 26.0 or later. This is a deployment target rather than a compatibility guarantee. Older iOS versions are outside this build's scope.

## Device check

Check that the home indicator stays hidden on the Home Screen, lock screen, inside several apps and in the app switcher. Repeat in portrait and landscape, with the keyboard visible, after locking/unlocking and while presenting and dismissing a full-screen app or video.

Confirm that swiping home, opening the app switcher, switching between apps and unlocking still work. If you use Reachability or the home indicator's Siri interaction, check those too. The implementation preserves the gesture containers and their geometry, but real device behavior remains unverified.

Only the visual indicator is targeted. App safe areas, bottom spacing, keyboard padding and gesture settings remain native. Other rounded indicators such as search pills or window-resize handles are left alone. App-drawn decorations that resemble a home bar are outside the scope.

## Rollback

Uninstall **No Home Bar 26** through Sileo then respring. It installs no preference files or daemon and replaces no Apple files. If SpringBoard enters Safe Mode during testing, remove this package there then respring.

## Diagnostics

If the indicator remains visible, describe the screen and orientation then share `NoHomeBar26-SpringBoard.plist` from `/var/mobile/Library/Logs`. On RootHide, use the corresponding directory inside the current `.jbroot`; on standard rootless, use the ordinary `/var/mobile` directory.

The log contains the build number, hook installation status and the first visual class returned by each indicator factory. It records no app contents or personal data. There is no continuous polling or per-frame file logging. CPU and battery impact have not been benchmarked.

Source code and build instructions are included. See [BUILD.md](BUILD.md) and [RESEARCH.md](RESEARCH.md).
