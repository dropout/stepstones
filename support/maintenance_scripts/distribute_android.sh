#!/bin/bash
# Builds a release Android APK, distributes it via Firebase App Distribution
# to the android_testers group, and uploads Crashlytics symbols.
set -euo pipefail

TESTER_GROUP="android_testers"
NOTES=""
DRY_RUN=0

usage() {
  echo "Usage: $0 <dev|qa|staging|prod> [--notes <text>] [--dry-run]"
  exit 1
}

[ $# -ge 1 ] || usage
FLAVOR="$1"
shift
while [ $# -gt 0 ]; do
  case "$1" in
    --notes) NOTES="${2:?}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) usage ;;
  esac
done

case "$FLAVOR" in
  dev) ENTRYPOINT="lib/main_dev.dart"; APPLICATION_ID_SUFFIX=".dev" ;;
  qa) ENTRYPOINT="lib/main_test.dart"; APPLICATION_ID_SUFFIX=".test" ;;
  staging) ENTRYPOINT="lib/main_staging.dart"; APPLICATION_ID_SUFFIX=".staging" ;;
  prod) ENTRYPOINT="lib/main_prod.dart"; APPLICATION_ID_SUFFIX=".prod" ;;
  *) echo "Error: unknown Android flavor '$FLAVOR'."; usage ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$REPO_ROOT/apps/mobile_app"
PUBSPEC="$APP_DIR/pubspec.yaml"
FIREBASE_CONFIG="$APP_DIR/android/app/src/$FLAVOR/google-services.json"
EXPECTED_PACKAGE="com.stepstonesapp.stepstones$APPLICATION_ID_SUFFIX"
SYMBOLS_DIR="$APP_DIR/build/symbols"
APK="$APP_DIR/build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"

[ -f "$APP_DIR/$ENTRYPOINT" ] || { echo "Error: entry point $ENTRYPOINT missing for flavor '$FLAVOR'."; exit 1; }
[ -f "$FIREBASE_CONFIG" ] || { echo "Error: Firebase config missing for flavor '$FLAVOR': $FIREBASE_CONFIG"; exit 1; }

run() {
  echo "+ $*"
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

for tool in flutter firebase git python3; do
  command -v "$tool" >/dev/null || { echo "Error: '$tool' not found."; exit 1; }
done

cd "$REPO_ROOT"
if [ -n "$(git status --porcelain)" ]; then
  echo "Error: git working tree is not clean."
  exit 1
fi

FIREBASE_VALUES="$(python3 - "$FIREBASE_CONFIG" "$EXPECTED_PACKAGE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as config_file:
    config = json.load(config_file)

matches = [
    client for client in config.get("client", [])
    if client.get("client_info", {}).get("android_client_info", {}).get("package_name")
    == sys.argv[2]
]
if len(matches) != 1:
    raise SystemExit(f"Error: expected one Firebase Android app for package {sys.argv[2]}.")

project = config.get("project_info", {}).get("project_id")
app_id = matches[0].get("client_info", {}).get("mobilesdk_app_id")
if not project or not app_id:
    raise SystemExit(f"Error: Firebase project or app id missing from {sys.argv[1]}.")

print(project)
print(app_id)
PY
)"
PROJECT="${FIREBASE_VALUES%%$'\n'*}"
APP_ID="${FIREBASE_VALUES#*$'\n'}"
APP_ID="${FIREBASE_ANDROID_APP_ID:-$APP_ID}"

CURRENT="$(grep -E '^version: [0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$' "$PUBSPEC" | head -1 | awk '{print $2}')"
[ -n "$CURRENT" ] || { echo "Error: cannot parse version in $PUBSPEC."; exit 1; }
VERSION_NAME="${CURRENT%+*}"
NEW_BUILD=$(( ${CURRENT##*+} + 1 ))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD"
echo "Version: $CURRENT -> $NEW_VERSION ($FLAVOR: project $PROJECT, app id $APP_ID)"

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
  rm -rf "$APP_DIR/build/app/outputs/flutter-apk" "$SYMBOLS_DIR"
fi

cd "$APP_DIR"
run flutter build apk --release --flavor "$FLAVOR" -t "$ENTRYPOINT" \
  --obfuscate --split-debug-info="$SYMBOLS_DIR"

if [ "$DRY_RUN" -eq 0 ] && [ ! -f "$APK" ]; then
  echo "Error: APK not found at $APK."
  exit 1
fi
if [ "$DRY_RUN" -eq 0 ] && ! find "$SYMBOLS_DIR" -type f -print -quit | grep -q .; then
  echo "Error: Dart symbol files not found in $SYMBOLS_DIR."
  exit 1
fi
[ -n "$NOTES" ] || NOTES="Build $NEW_VERSION"

run firebase crashlytics:symbols:upload --app "$APP_ID" "$SYMBOLS_DIR"
run firebase appdistribution:distribute "$APK" \
  --app "$APP_ID" --project "$PROJECT" \
  --groups "$TESTER_GROUP" --release-notes "$NOTES"

if [ "$DRY_RUN" -eq 0 ]; then
  BUMPED=0
  git -C "$REPO_ROOT" add "$PUBSPEC"
  git -C "$REPO_ROOT" commit -m "chore: bump build number to $NEW_BUILD" \
    -m "Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
fi

echo "Done: $FLAVOR $NEW_VERSION distributed to $TESTER_GROUP in $PROJECT."
