#!/bin/bash
# Builds an App Store IPA, uploads it to App Store Connect (TestFlight)
# and uploads Crashlytics symbols.
set -euo pipefail

DRY_RUN=0

usage() {
  echo "Usage: $0 <flavor> [--dry-run]"
  exit 1
}

[ $# -ge 1 ] || usage
FLAVOR="$1"
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    *) usage ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$REPO_ROOT/apps/mobile_app"
PUBSPEC="$APP_DIR/pubspec.yaml"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions-AppStore.plist"
SCHEME="$APP_DIR/ios/Runner.xcodeproj/xcshareddata/xcschemes/$FLAVOR.xcscheme"
ENTRYPOINT="lib/main_$FLAVOR.dart"
PLIST="$APP_DIR/ios/config/$FLAVOR/GoogleService-Info.plist"
SYMBOLS_DIR="$APP_DIR/build/symbols"
ARCHIVE="$APP_DIR/build/ios/archive/Runner.xcarchive"

[ -f "$SCHEME" ] || { echo "Error: unknown flavor '$FLAVOR' (no Xcode scheme at $SCHEME)."; exit 1; }
[ -f "$APP_DIR/$ENTRYPOINT" ] || { echo "Error: entry point $ENTRYPOINT missing for flavor '$FLAVOR'."; exit 1; }
[ -f "$PLIST" ] || { echo "Error: Firebase config missing for flavor '$FLAVOR': $PLIST"; exit 1; }
[ -f "$EXPORT_OPTIONS" ] || { echo "Error: $EXPORT_OPTIONS missing."; exit 1; }

run() {
  echo "+ $*"
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

for tool in flutter xcodebuild git; do
  command -v "$tool" >/dev/null || { echo "Error: '$tool' not found."; exit 1; }
done

cd "$REPO_ROOT"
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: git working tree is not clean."
  exit 1
fi

CURRENT="$(grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' "$PUBSPEC" | head -1 | awk '{print $2}')"
[ -n "$CURRENT" ] || { echo "Error: cannot parse version in $PUBSPEC."; exit 1; }
VERSION_NAME="${CURRENT%+*}"
NEW_BUILD=$(( ${CURRENT##*+} + 1 ))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD"
echo "Version: $CURRENT -> $NEW_VERSION ($FLAVOR, App Store Connect)"

BUMPED=0
UPLOAD_DIR=""
cleanup() {
  [ -z "$UPLOAD_DIR" ] || rm -rf "$UPLOAD_DIR"
  if [ "$BUMPED" -eq 1 ]; then
    echo "Failed, restoring pubspec.yaml"
    git -C "$REPO_ROOT" checkout -- "$PUBSPEC"
  fi
}
trap cleanup EXIT

if [ "$DRY_RUN" -eq 0 ]; then
  sed -i '' -E "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
  BUMPED=1
  rm -rf "$APP_DIR"/build/ios/ipa "$APP_DIR"/build/ios/archive "$APP_DIR"/build/ios/upload "$SYMBOLS_DIR"
fi

cd "$APP_DIR"
run flutter build ipa --release --flavor "$FLAVOR" -t "$ENTRYPOINT" \
  --obfuscate --split-debug-info="$SYMBOLS_DIR" \
  --export-options-plist="$EXPORT_OPTIONS"

# Re-export the same archive with destination=upload; uses the Apple ID signed in to Xcode.
UPLOAD_DIR="$(mktemp -d)"
UPLOAD_OPTIONS="$UPLOAD_DIR/ExportOptions.plist"
cp "$EXPORT_OPTIONS" "$UPLOAD_OPTIONS"
/usr/libexec/PlistBuddy -c "Set :destination upload" "$UPLOAD_OPTIONS"
run xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$UPLOAD_OPTIONS" -exportPath build/ios/upload \
  -allowProvisioningUpdates

# The build number is consumed once App Store Connect accepts it, so keep and commit it.
if [ "$DRY_RUN" -eq 0 ]; then
  BUMPED=0
  git -C "$REPO_ROOT" add "$PUBSPEC"
  git -C "$REPO_ROOT" commit -m "chore: bump build number to $NEW_BUILD"
fi

UPLOAD_SYMBOLS="$(ls -d "$HOME"/Library/Developer/Xcode/DerivedData/Runner-*/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols \
  "$APP_DIR"/ios/Pods/FirebaseCrashlytics/upload-symbols 2>/dev/null | head -1 || true)"
if [ -z "$UPLOAD_SYMBOLS" ]; then
  [ "$DRY_RUN" -eq 1 ] || { echo "Error: Crashlytics upload-symbols binary not found (build $NEW_VERSION is already uploaded and committed)."; exit 1; }
  UPLOAD_SYMBOLS="upload-symbols"
fi
run "$UPLOAD_SYMBOLS" -gsp "$PLIST" -p ios "$ARCHIVE/dSYMs"

echo "Done: $FLAVOR $NEW_VERSION uploaded to App Store Connect; it appears in TestFlight after processing."
