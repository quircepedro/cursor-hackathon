#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE_DIR="$ROOT_DIR/apps/mobile"

echo "==> Using repo root: $ROOT_DIR"
echo "==> Flutter app dir: $MOBILE_DIR"

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_VERSION="${FLUTTER_VERSION:-}"

FLUTTER_HOME="$ROOT_DIR/.vercel/flutter"
mkdir -p "$FLUTTER_HOME"

download_flutter() {
  local channel="$1"
  local version="$2"

  # Vercel runs on Linux, so we download linux SDK.
  local base="https://storage.googleapis.com/flutter_infra_release/releases"
  local manifest="$base/releases_linux.json"

  echo "==> Resolving Flutter SDK from: $manifest"
  curl -fsSL "$manifest" -o "$ROOT_DIR/.vercel/releases_linux.json"

  local tar
  tar="$(python3 - <<'PY'
import json, os
path = os.path.join(os.environ["ROOT_DIR"], ".vercel", "releases_linux.json")
channel = os.environ["FLUTTER_CHANNEL"]
version = os.environ.get("FLUTTER_VERSION", "").strip()
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

releases = data.get("releases", [])
current = data.get("current_release", {})
target_hash = current.get(channel)
if version:
    # Try match by version in the archive filename (best-effort).
    for r in releases:
        arch = r.get("archive", "")
        if version in arch and ("/linux/" in arch or arch.startswith("linux/")):
            print("https://storage.googleapis.com/flutter_infra_release/releases/" + arch)
            raise SystemExit(0)

for r in releases:
    if r.get("hash") == target_hash:
        arch = r.get("archive", "")
        print("https://storage.googleapis.com/flutter_infra_release/releases/" + arch)
        raise SystemExit(0)

raise SystemExit(f"Could not resolve Flutter archive for channel={channel} version={version or '(latest)'}")
PY
)"

  echo "==> Downloading Flutter SDK: $tar"
  curl -fsSL "$tar" -o "$ROOT_DIR/.vercel/flutter.tar.xz"
  tar -xf "$ROOT_DIR/.vercel/flutter.tar.xz" -C "$ROOT_DIR/.vercel"
  rm -f "$ROOT_DIR/.vercel/flutter.tar.xz"
  rm -f "$ROOT_DIR/.vercel/releases_linux.json"
}

if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$ROOT_DIR/.vercel"
  ROOT_DIR="$ROOT_DIR" FLUTTER_CHANNEL="$FLUTTER_CHANNEL" FLUTTER_VERSION="$FLUTTER_VERSION" \
    download_flutter "$FLUTTER_CHANNEL" "$FLUTTER_VERSION"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "==> Flutter version"
flutter --version

cd "$MOBILE_DIR"

echo "==> flutter pub get"
flutter pub get

defines=()

add_define() {
  local key="$1"
  local val="${!key-}"
  if [[ -n "$val" ]]; then
    defines+=("--dart-define=${key}=${val}")
  fi
}

# App env + backend
add_define "APP_ENV"
add_define "API_BASE_URL"

# Firebase web
add_define "FIREBASE_WEB_API_KEY"
add_define "FIREBASE_WEB_APP_ID"
add_define "FIREBASE_WEB_MESSAGING_SENDER_ID"
add_define "FIREBASE_WEB_PROJECT_ID"
add_define "FIREBASE_WEB_AUTH_DOMAIN"
add_define "FIREBASE_WEB_STORAGE_BUCKET"
add_define "FIREBASE_WEB_MEASUREMENT_ID"

# Google Sign-In
add_define "GOOGLE_WEB_CLIENT_ID"
add_define "GOOGLE_SERVER_CLIENT_ID"

echo "==> flutter build web --release"
flutter build web --release "${defines[@]}"

echo "==> Build output: $MOBILE_DIR/build/web"
