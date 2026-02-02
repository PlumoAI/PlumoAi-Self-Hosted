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

echo "🚀 Starting services..."
docker compose up -d

echo "✅ PlumoAI is running on port 3000"
