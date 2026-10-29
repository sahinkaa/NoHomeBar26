#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
nhb_temp=$(mktemp -d "${TMPDIR:-/tmp}/nohomebar26.XXXXXX")
trap 'rm -rf "$nhb_temp"' EXIT HUP INT TERM
xcrun --sdk macosx clang -g -fno-objc-arc -fblocks -fstack-protector-strong \
 -fsanitize=address,undefined -Wall -Wextra -Wno-unused-parameter -Wno-unused-function \
 -Itests -framework Foundation -framework CoreGraphics tests/runtime.m -o "$nhb_temp/runtime"
"$nhb_temp/runtime" "$nhb_temp/logs/NoHomeBar26-SpringBoard.plist"
