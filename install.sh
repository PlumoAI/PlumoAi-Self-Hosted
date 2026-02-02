#!/bin/bash
set -e

echo "🔐 Setting up secrets..."

mkdir -p secrets

# Fixed DB name and username — do not change after MySQL is first initialized
echo -n "authdb_prod" > secrets/mysql_db.txt
echo -n "plumoai_user" > secrets/mysql_user.txt

# Random password — only generate if missing (re-running must not overwrite or MySQL and auth will mismatch)
if [ ! -f secrets/mysql_password.txt ]; then
  openssl rand -base64 32 > secrets/mysql_password.txt
  echo "  Created new mysql_password.txt"
else
  echo "  Keeping existing mysql_password.txt (do not overwrite after MySQL is initialized)"
fi

chmod 600 secrets/*

docker compose down
docker volume rm plumoai-self-hosted_mysql_data
echo "🚀 Starting services..."
docker compose up -d

# Domain from .env (no static default)
DOMAIN_NAME=
[ -f .env ] && DOMAIN_NAME=$(grep -E '^DOMAIN_NAME=' .env | head -1 | cut -d= -f2-)
if [ -n "$DOMAIN_NAME" ]; then
  echo "✅ PlumoAI is running at https://${DOMAIN_NAME}"
else
  echo "✅ PlumoAI is running (set DOMAIN_NAME in .env for URL)"
fi
