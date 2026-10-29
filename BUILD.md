# Build and validation

Local toolchain: Xcode 27.1 (27A9275), Apple clang 21, iPhoneOS 27.1 SDK, ldid and RootHide Theos at commit `cfba89a53a05b4a1b822121158acc3669c20602f` from `https://github.com/roothide/theos.git`.

Use full Xcode with its command-line tools, Python 3 and ldid. The RootHide Theos checkout needs its normal submodules for headers, hook stubs and native RootHide libraries. No Apple private headers or framework binaries are bundled.

From this source directory:

```sh
export THEOS=/absolute/path/to/roothide/theos
sh build.sh all
```

Use `sh build.sh rootless` or `sh build.sh roothide` to build one variant. The script runs host checks then cleans and compiles each scheme independently, signs the binary, normalizes package ownership and validates the output. It does not convert or relabel an existing package.

- Standard rootless: `iphoneos-arm64` package with arm64 and modern arm64e slices. Installed files are under `/var/jb` and substrate uses the rootless library search paths.
- Native RootHide: `iphoneos-arm64e` package with a modern arm64e slice and native libroothide dependencies.

Both use deployment target iOS 26.0. User data logs use `/var/mobile/Library/Logs` on standard rootless and the native `jbroot` mapping on RootHide. No settings bundle or preference file is shipped.

Output:

```text
packages/com.sahinkaa.nohomebar26_1.0_iphoneos-arm64.deb
packages/com.sahinkaa.nohomebar26_1.0_iphoneos-arm64e.deb
validation/tests.log
validation/package-rootless.json
validation/package-roothide.json
validation/symbols-rootless/
validation/symbols-roothide/
```

Keep the matching debug symbols when investigating a crash.

## Runtime ownership

`Engine/Runtime.m` intentionally uses manual reference counting. The private `_new...` methods belong to Objective-C's new method family and return owned objects. Each replacement returns the original object with the same ownership. It does not release, autorelease or substitute nil for that view. This is relevant when changing compiler flags or refactoring the hook functions.

## Checks

The host suite compiles the actual runtime with AddressSanitizer and UndefinedBehaviorSanitizer against isolated macOS Foundation view doubles. No real UIKit class is hooked. It checks all six factory paths, exactly-once original calls, object lifetimes, clamping marked visual views, inherited hooks without recursion or superclass mutation, preservation of unmarked views and gesture-owner fields, unchanged geometry, nil and unexpected results, rejection of incompatible signatures, missing classes, deferred installation, idempotence and the off-main fallback. A 1,000-object create/release loop checks the owned factory result lifetime.

These fixtures verify control flow and ownership. They cannot prove swipe gestures or visual coverage on a device.

The package validator checks archive inventory and ownership, an exact two-file payload, SpringBoard-only filtering, absence of a Settings bundle, absence of the forbidden gesture/layout selector strings, package metadata, iOS deployment target, expected CPU slices and library paths. It verifies every signed code-page hash in each CodeDirectory.

Validate an existing package with:

```sh
python3 validate_package.py packages/com.sahinkaa.nohomebar26_1.0_iphoneos-arm64e.deb roothide
python3 validate_package.py packages/com.sahinkaa.nohomebar26_1.0_iphoneos-arm64.deb rootless
```

Structural package validation does not certify device trust or compatibility. Device testing is still required.
