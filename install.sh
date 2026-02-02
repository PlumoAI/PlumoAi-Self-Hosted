#!/bin/bash
set -e

echo "🔐 Generating secrets..."

mkdir -p secrets

openssl rand -base64 16 > secrets/mysql_user.txt
openssl rand -base64 32 > secrets/mysql_password.txt
echo -n "authdb_prod" > secrets/mysql_db.txt

chmod 600 secrets/*

echo "🚀 Starting services..."
docker compose up -d

echo "✅ PlumoAI is running on port 3000"
