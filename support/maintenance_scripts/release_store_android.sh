#!/bin/bash
# Builds an upload-key-signed Android App Bundle for Google Play
# and uploads Crashlytics symbols. Upload the AAB in Play Console.
set -euo pipefail

DRY_RUN=0

usage() {
  echo "Usage: $0 <dev|qa|staging|prod> [--dry-run]"
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

case "$FLAVOR" in
  dev) ENTRYPOINT="lib/main_dev.dart" ;;
  qa) ENTRYPOINT="lib/main_test.dart" ;;
  staging) ENTRYPOINT="lib/main_staging.dart" ;;
  prod) ENTRYPOINT="lib/main_prod.dart" ;;
  *) echo "Error: unknown Android flavor '$FLAVOR'."; usage ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$REPO_ROOT/apps/mobile_app"
PUBSPEC="$APP_DIR/pubspec.yaml"
FIREBASE_CONFIG="$APP_DIR/android/app/src/$FLAVOR/google-services.json"
KEY_PROPERTIES="$APP_DIR/android/key.properties"
SYMBOLS_DIR="$APP_DIR/build/symbols"
AAB="$APP_DIR/build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"

[ -f "$APP_DIR/$ENTRYPOINT" ] || { echo "Error: entry point $ENTRYPOINT missing for flavor '$FLAVOR'."; exit 1; }
[ -f "$FIREBASE_CONFIG" ] || { echo "Error: Firebase config missing for flavor '$FLAVOR': $FIREBASE_CONFIG"; exit 1; }
[ -f "$KEY_PROPERTIES" ] || { echo "Error: $KEY_PROPERTIES missing; Play rejects debug-signed bundles (see key.properties.example)."; exit 1; }

run() {
  echo "+ $*"
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

for tool in flutter firebase git keytool python3; do
  command -v "$tool" >/dev/null || { echo "Error: '$tool' not found."; exit 1; }
done

cd "$REPO_ROOT"
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: git working tree is not clean."
  exit 1
fi

APP_ID="${FIREBASE_ANDROID_APP_ID:-$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['client'][0]['client_info']['mobilesdk_app_id'])" "$FIREBASE_CONFIG")}"

CURRENT="$(grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' "$PUBSPEC" | head -1 | awk '{print $2}')"
[ -n "$CURRENT" ] || { echo "Error: cannot parse version in $PUBSPEC."; exit 1; }
VERSION_NAME="${CURRENT%+*}"
NEW_BUILD=$(( ${CURRENT##*+} + 1 ))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD"
echo "Version: $CURRENT -> $NEW_VERSION ($FLAVOR, Google Play, app id $APP_ID)"

BUMPED=0
cleanup() {
  if [ "$BUMPED" -eq 1 ]; then
    echo "Failed, restoring pubspec.yaml"
    git -C "$REPO_ROOT" checkout -- "$PUBSPEC"
  fi
}
trap cleanup EXIT

if [ "$DRY_RUN" -eq 0 ]; then
  sed -i '' -E "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC"
  BUMPED=1
  rm -rf "$APP_DIR/build/app/outputs/bundle" "$SYMBOLS_DIR"
fi

cd "$APP_DIR"
run flutter build appbundle --release --flavor "$FLAVOR" -t "$ENTRYPOINT" \
  --obfuscate --split-debug-info="$SYMBOLS_DIR"

if [ "$DRY_RUN" -eq 0 ]; then
  [ -f "$AAB" ] || { echo "Error: AAB not found at $AAB."; exit 1; }
  # Gradle silently falls back to the debug key when key.properties is unusable.
  # Captured first so a keytool failure aborts instead of passing the check.
  CERT="$(keytool -printcert -jarfile "$AAB")"
  if grep -q "CN=Android Debug" <<<"$CERT"; then
    echo "Error: $AAB is signed with the debug key; check $KEY_PROPERTIES."
    exit 1
  fi
fi

run firebase crashlytics:symbols:upload --app "$APP_ID" "$SYMBOLS_DIR"

# Play rejects a reused version code, so keep and commit the bump.
if [ "$DRY_RUN" -eq 0 ]; then
  BUMPED=0
  git -C "$REPO_ROOT" add "$PUBSPEC"
  git -C "$REPO_ROOT" commit -m "chore: bump build number to $NEW_BUILD"
fi

echo "Done: $FLAVOR $NEW_VERSION bundle at $AAB; upload it to a testing track in Play Console."
