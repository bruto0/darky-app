#!/usr/bin/env bash
# Build the iOS release IPA locally after tools/ios-setup.sh and Xcode signing setup.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

cd "$APP_DIR"
flutter build ipa --release "$@"

echo "IPA artifacts:"
find build/ios/ipa -maxdepth 1 -name '*.ipa' -print 2>/dev/null || true
