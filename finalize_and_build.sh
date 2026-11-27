#!/system/bin/sh
set -u

APP_DIR="${APP_DIR:-/mnt/sdcard/opencode/build-vault/fortress_studio_app}"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"
BUILD_MODE="${BUILD_MODE:-release}"

if [ ! -d "$APP_DIR" ]; then
  echo "ERROR: App directory not found: $APP_DIR"
  exit 1
fi

if ! command -v "$FLUTTER_CMD" >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found. Set FLUTTER_CMD or add flutter to PATH."
  exit 1
fi

cd "$APP_DIR" || exit 1

backup_and_atomic_replace() {
  src="$1"
  dst="$2"
  if [ ! -f "$src" ]; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")" || return 1
  if [ -f "$dst" ]; then
    cp -f "$dst" "${dst}.bak" || return 1
  fi
  tmp="${dst}.tmp.$$"
  cp -f "$src" "$tmp" || return 1
  mv -f "$tmp" "$dst" || return 1
}

if [ -d "${APP_DIR}/.staging" ]; then
  find "${APP_DIR}/.staging" -type f | while IFS= read -r staged_file; do
    rel_path="${staged_file#${APP_DIR}/.staging/}"
    backup_and_atomic_replace "$staged_file" "${APP_DIR}/${rel_path}" || {
      echo "ERROR: Atomic replace failed for ${rel_path}"
      exit 1
    }
  done
fi

"$FLUTTER_CMD" pub get
PUB_STATUS=$?
if [ "$PUB_STATUS" -ne 0 ]; then
  echo "ERROR: flutter pub get failed with exit code $PUB_STATUS"
  exit "$PUB_STATUS"
fi

"$FLUTTER_CMD" analyze lib/
ANALYZE_STATUS=$?
if [ "$ANALYZE_STATUS" -ne 0 ]; then
  echo "ERROR: flutter analyze failed with exit code $ANALYZE_STATUS"
  exit "$ANALYZE_STATUS"
fi

if [ "$BUILD_MODE" = "debug" ]; then
  "$FLUTTER_CMD" build apk --debug
else
  "$FLUTTER_CMD" build apk --release
fi
BUILD_STATUS=$?
if [ "$BUILD_STATUS" -ne 0 ]; then
  echo "ERROR: flutter build apk failed with exit code $BUILD_STATUS"
  exit "$BUILD_STATUS"
fi

ls -la build/app/outputs/flutter-apk/
