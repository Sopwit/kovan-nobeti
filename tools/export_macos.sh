#!/bin/bash
set -euo pipefail

project_dir="$(cd "${1:-$(dirname "$0")/..}" && pwd)"
output_dir="${2:-$project_dir/build/macos}"
godot="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"

work="$(mktemp -d "${TMPDIR:-/tmp}/kovan-nobeti-macos.XXXXXX")"
trap 'rm -rf "$work"' EXIT
app="$work/KovanNobeti.app"

"$godot" --headless --path "$project_dir" --import
"$godot" --headless --path "$project_dir" --export-release macOS "$app"

# Godot uses the display name for the binary and PCK filenames. The composed
# and decomposed forms of “ö” can disagree in the macOS bundle resource seal.
# Keep the Turkish display name and use stable ASCII names for the two files.
executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
if [[ "$executable" != KovanNobeti ]]; then
    mv "$app/Contents/MacOS/$executable" "$app/Contents/MacOS/KovanNobeti"
    mv "$app/Contents/Resources/$executable.pck" "$app/Contents/Resources/KovanNobeti.pck"
    plutil -replace CFBundleExecutable -string KovanNobeti "$app/Contents/Info.plist"
fi
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
ditto -c -k --keepParent "$app" "$work/KovanNobeti-macOS.zip"

# Replace generated artifacts only after the new bundle has been verified.
if [[ -e "$output_dir/KovanNobeti.app" ]]; then
    mv "$output_dir/KovanNobeti.app" "$work/previous.app"
fi
if ! ditto "$app" "$output_dir/KovanNobeti.app" ||
   ! codesign --verify --deep --strict "$output_dir/KovanNobeti.app"; then
    if [[ -e "$output_dir/KovanNobeti.app" ]]; then
        mv "$output_dir/KovanNobeti.app" "$work/failed.app"
    fi
    if [[ -e "$work/previous.app" ]]; then
        mv "$work/previous.app" "$output_dir/KovanNobeti.app"
    fi
    exit 1
fi
mv -f "$work/KovanNobeti-macOS.zip" "$output_dir/KovanNobeti-macOS.zip"
