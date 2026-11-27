#!/system/bin/sh
set -u

APP_DIR="/mnt/sdcard/opencode/build-vault/fortress_studio_app"
FLUTTER_CMD="${FLUTTER_CMD:-flutter}"

if ! command -v "$FLUTTER_CMD" >/dev/null 2>&1; then
  echo "ERROR: Flutter SDK not found. Install Flutter and set FLUTTER_CMD env var."
  exit 1
fi

cd "$APP_DIR" || exit 1

echo "=== Step 1: flutter pub get ==="
timeout 120 "$FLUTTER_CMD" pub get
if [ $? -ne 0 ]; then
  echo "ERROR: flutter pub get failed"
  exit 1
fi

echo "=== Step 2: flutter analyze ==="
timeout 120 "$FLUTTER_CMD" analyze lib/
if [ $? -ne 0 ]; then
  echo "ERROR: flutter analyze failed"
  exit 1
fi

echo "=== Step 3: flutter build apk ==="
timeout 300 "$FLUTTER_CMD" build apk --release
if [ $? -ne 0 ]; then
  echo "ERROR: flutter build apk failed"
  exit 1
fi

echo "=== Build complete ==="
ls -la build/app/outputs/flutter-apk/ 2>/dev/null || echo "APK output not found"
