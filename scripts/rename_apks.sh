#!/usr/bin/env bash
# Rename Flutter APK outputs to match index.html expectations:
#   Cmap-arm64-v8a.apk, Cmap-armeabi-v7a.apk, Cmap-x86_64.apk, Cmap-release.apk
#
# Usage: ./scripts/rename_apks.sh [build_dir]
# Default build_dir: build/app/outputs/flutter-apk

set -euo pipefail

BUILD_DIR="${1:-build/app/outputs/flutter-apk}"

if [ ! -d "$BUILD_DIR" ]; then
  echo "Error: Directory not found: $BUILD_DIR"
  exit 1
fi

renamed=0

cd "$BUILD_DIR"

# Split-per-ABI builds: app-<abi>-release.apk → Cmap-<abi>.apk
for apk in app-*-release.apk; do
  [ -f "$apk" ] || continue
  # Extract ABI from filename: app-arm64-v8a-release.apk → arm64-v8a
  abi=$(echo "$apk" | sed 's/^app-\(.*\)-release\.apk$/\1/')
  new_name="Cmap-${abi}.apk"
  if [ "$apk" != "$new_name" ]; then
    mv "$apk" "$new_name"
    echo "Renamed: $apk → $new_name"
    renamed=$((renamed + 1))
  fi
done

# Universal/fat build: app-release.apk → Cmap-release.apk
if [ -f "app-release.apk" ]; then
  mv "app-release.apk" "Cmap-release.apk"
  echo "Renamed: app-release.apk → Cmap-release.apk"
  renamed=$((renamed + 1))
fi

# Single-target-platform build: app-release.apk already handled above
# Also handle app-<abi>-release.apk pattern from --target-platform (no split)
# e.g., when using --target-platform android-arm64, output is still app-release.apk

if [ "$renamed" -eq 0 ]; then
  echo "No APKs found to rename in $BUILD_DIR"
  ls -la *.apk 2>/dev/null || echo "(no .apk files)"
else
  echo "Done. Renamed $renamed APK(s)."
  ls -lh Cmap-*.apk 2>/dev/null
fi
