#!/usr/bin/env bash
set -euo pipefail

flutter_version=3.50.1
flutter_sdk="${FARMA_FLUTTER_SDK:-$PWD/.flutter-sdk}"

if [[ ! -x "$flutter_sdk/bin/flutter" ]]; then
  git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$flutter_sdk"
fi

export CI=true
"$flutter_sdk/bin/flutter" pub get --enforce-lockfile
"$flutter_sdk/bin/flutter" build web --release --no-pub
