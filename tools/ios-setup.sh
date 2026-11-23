#!/usr/bin/env bash
# Prepare the Flutter iOS project for local development on macOS.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

command -v flutter >/dev/null 2>&1 || {
  echo "flutter is not installed or is not on PATH" >&2
  exit 1
}
command -v pod >/dev/null 2>&1 || {
  echo "CocoaPods is not installed. Install it with: sudo gem install cocoapods" >&2
  exit 1
}

cd "$APP_DIR"
flutter --version
flutter pub get

cd ios
pod install --repo-update
cd ..

flutter analyze
flutter test

cat <<EOF
iOS project is ready.

Open the workspace in Xcode:
  open "$APP_DIR/ios/Runner.xcworkspace"

Then select the Runner target and configure Signing & Capabilities:
  - Team
  - Bundle Identifier: ru.darky.dance
  - Signing style: Automatic (for local Xcode signing)
EOF
