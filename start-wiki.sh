#!/bin/sh
set -e

echo "Configuring Wiki.js..."

cat > /wiki/config.yml << WIKIEOF
port: 3000
bindIP: 0.0.0.0

db:
  type: ${DB_TYPE}
  host: ${DB_HOST}
  port: ${DB_PORT}
  user: ${DB_USER}
  pass: ${DB_PASS}
  db: ${DB_NAME}
  ssl: false

logLevel: info
dataPath: ./data
WIKIEOF

echo "Starting Wiki.js..."
exec node server
