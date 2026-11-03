#!/usr/bin/env bash
# Instala o Flutter na máquina de build da Vercel, que não traz o SDK.
# A versão acompanha a usada no desenvolvimento; troque com FLUTTER_VERSION.
set -euo pipefail

VERSAO="${FLUTTER_VERSION:-3.47.9}"
if [ ! -x flutter/bin/flutter ]; then
  git clone --depth 1 --branch "$VERSAO" https://github.com/flutter/flutter.git flutter
fi
flutter/bin/flutter config --no-analytics --enable-web
flutter/bin/flutter pub get
