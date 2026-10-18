#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077

if ! command -v openssl >/dev/null 2>&1; then
  echo 'OpenSSL is required to generate local credentials.' >&2
  exit 1
fi

mkdir -p secrets
for name in postgresql_password odoo_master_password; do
  file="secrets/$name"
  if [[ -d "$file" ]]; then
    printf '%s is a directory, not a secret file. Check before removing it.\n' "$file" >&2
    exit 1
  fi
  if [[ ! -e "$file" ]]; then
    openssl rand -hex 32 > "$file"
    printf 'Created: %s\n' "$file"
  elif [[ ! -s "$file" ]]; then
    printf 'Existing file is empty: %s\n' "$file" >&2
    exit 1
  fi
  chmod 600 "$file"
done

if [[ -d .env ]]; then
  printf '.env is a directory, not a file.\n' >&2
  exit 1
fi
if [[ ! -e .env ]]; then
  cp .env.example .env
  printf 'Created: .env\n'
fi

echo 'Ready. Local credentials are ignored by Git.'
