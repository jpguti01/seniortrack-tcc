#!/bin/sh
# Inicia a API no container. Sem DB_URL, usa a conexao que a Vercel cria ao ligar
# um banco Postgres (Neon) ao projeto, no formato postgresql://usuario:senha@host/banco?params.
set -e
if [ -z "$DB_URL" ]; then
  url="${DATABASE_URL_UNPOOLED:-${DATABASE_URL:-${POSTGRES_URL_NON_POOLING:-$POSTGRES_URL}}}"
  if [ -n "$url" ]; then
    resto="${url#*://}"
    credenciais="${resto%%@*}"
    export DB_URL="jdbc:postgresql://${resto#*@}"
    export DB_USERNAME="${credenciais%%:*}"
    export DB_PASSWORD="${credenciais#*:}"
  fi
fi
exec java -XX:MaxRAMPercentage=75 -XX:TieredStopAtLevel=1 -jar /app/app.jar --server.port="${PORT:-80}"
