#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.3}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/${FLUTTER_ARCHIVE}"
FLUTTER_HOME="$PWD/.flutter-sdk"
FLUTTER_BIN="$FLUTTER_HOME/bin/flutter"

if [ ! -x "$FLUTTER_BIN" ]; then
  echo "Downloading Flutter SDK ${FLUTTER_VERSION} (${FLUTTER_CHANNEL})..."
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$FLUTTER_HOME"
  curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.tar.xz
  tar -xJf /tmp/flutter.tar.xz -C "$FLUTTER_HOME" --strip-components=1
fi

# Vercel builds can run as root; mark SDK dir as safe for git commands used by Flutter tool.
git config --global --add safe.directory "$FLUTTER_HOME" || true

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter pub get
flutter build web --release
