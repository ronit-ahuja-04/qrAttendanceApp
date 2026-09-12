#!/bin/bash
echo "Installing Flutter for Vercel Build..."
if test -d flutter; then
  echo "Flutter directory already exists."
else
  git clone https://github.com/flutter/flutter.git -b stable
fi
export PATH="$PATH:`pwd`/flutter/bin"
flutter/bin/flutter precache
flutter/bin/flutter clean
flutter/bin/flutter pub get
flutter/bin/flutter build web --release
