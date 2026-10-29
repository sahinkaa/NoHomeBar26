#!/bin/sh
set -eu
cd "$(dirname "$0")"
: "${THEOS:?Set THEOS to the RootHide Theos checkout}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build-cache/modules"
mkdir -p validation
case "${1:-all}" in
    all) variants="rootless roothide" ;;
    rootless|roothide) variants=$1 ;;
    *) echo "Usage: sh build.sh [all|rootless|roothide]" >&2;exit 2 ;;
esac
sh tests/run.sh > validation/tests.log 2>&1
cat validation/tests.log
for scheme in $variants;do
    make clean package THEOS_PACKAGE_SCHEME="$scheme"
    if [ "$scheme" = roothide ];then arch=iphoneos-arm64e;else arch=iphoneos-arm64;fi
    package="packages/com.sahinkaa.nohomebar26_1.0_${arch}.deb"
    python3 normalize_package.py "$package"
    python3 validate_package.py "$package" "$scheme" > "validation/package-${scheme}.json"
    mkdir -p "validation/symbols-${scheme}"
    find .theos/obj -type d -name '*.dSYM' -prune -exec cp -R '{}' "validation/symbols-${scheme}/" \;
done
