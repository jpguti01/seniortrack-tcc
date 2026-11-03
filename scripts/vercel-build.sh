#!/usr/bin/env bash
# Gera o app web na Vercel. Variáveis do projeto (Settings > Environment Variables):
#   API_BASE_URL      endereço HTTPS público do backend (obrigatório no deploy)
#   GOOGLE_CLIENT_ID  ID OAuth do Google (sem ele, o botão do Google fica indisponível)
set -euo pipefail

: "${API_BASE_URL:?Defina API_BASE_URL com o endereço HTTPS público do backend antes de publicar.}"
API_BASE_URL="${API_BASE_URL%/}"
case "$API_BASE_URL" in
  https://localhost*|https://127.0.0.1*|https://\[::1\]*)
    echo 'API_BASE_URL precisa apontar para um servidor público, fora do computador local.' >&2
    exit 1
    ;;
  https://*) ;;
  *)
    echo 'API_BASE_URL precisa usar HTTPS no deploy da Vercel.' >&2
    exit 1
    ;;
esac

ARGS=(build web --release --no-pub)
ARGS+=("--dart-define=API_BASE_URL=$API_BASE_URL")
if [ -n "${GOOGLE_CLIENT_ID:-}" ]; then
  ARGS+=("--dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID")
fi
flutter/bin/flutter "${ARGS[@]}"
