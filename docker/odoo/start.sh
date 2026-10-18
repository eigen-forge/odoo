#!/usr/bin/env bash
set -euo pipefail

# The official Odoo image runs as user odoo.
# Keep the database-manager password in a local Docker secret.
secret_file=/run/secrets/odoo_master_password
if [[ ! -s "$secret_file" ]]; then
  echo "Missing non-empty Docker secret: $secret_file" >&2
  exit 1
fi

master_password="$(tr -d '\r\n' < "$secret_file")"
if [[ -z "$master_password" || "$master_password" == *[!A-Za-z0-9_-]* ]]; then
  echo 'Odoo master password must contain only letters, digits, underscore or hyphen.' >&2
  exit 1
fi

umask 077
runtime_config="$(mktemp /tmp/odoo-config-XXXXXX)"
sed '/^[[:space:]]*admin_passwd[[:space:]]*=/d' /etc/odoo/odoo.conf > "$runtime_config"
printf '\nadmin_passwd = %s\n' "$master_password" >> "$runtime_config"
unset master_password

# Official entrypoint waits for PostgreSQL and passes connection arguments.
export ODOO_RC="$runtime_config"
exec /entrypoint.sh odoo "$@"
