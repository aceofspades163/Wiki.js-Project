#!/bin/bash
# Wiki.js Final Project - Quick Setup Script
# Creates all necessary files for the final deployment

set -e

echo "================================================"
echo "Wiki.js Final Project - Setup"
echo "================================================"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p nginx/ssl
mkdir -p backups
mkdir -p docs

echo "✓ Directories created"
echo ""

# Generate SSL certificates
echo "Generating self-signed SSL certificates..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
    2>/dev/null

chmod 600 nginx/ssl/key.pem
chmod 644 nginx/ssl/cert.pem

echo "✓ SSL certificates generated"
echo ""

# Create nginx config
echo "Creating nginx configuration..."
cat > nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    sendfile on;
    keepalive_timeout 65;
    client_max_body_size 50M;

    upstream wikijs {
        server wiki:3000;
    }

    # HTTP - Redirect to HTTPS
    server {
        listen 80;
        return 301 https://$host$request_uri;
    }

    # HTTPS
    server {
        listen 443 ssl;
        
        ssl_certificate /etc/nginx/ssl/cert.pem;
        ssl_certificate_key /etc/nginx/ssl/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;

        location / {
            proxy_pass http://wikijs;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

echo "✓ Nginx configuration created"
echo ""

# Create Wiki.js startup script
echo "Creating Wiki.js startup script..."
cat > start-wiki.sh << 'EOF'
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
EOF

chmod +x start-wiki.sh

echo "✓ Startup script created"
echo ""

# Create Dockerfile for production
echo "Creating production Dockerfile..."
cat > Dockerfile << 'EOF'
FROM alpine:3.19

LABEL maintainer="mayson@example.com"
LABEL version="2.0-final"

ENV WIKI_VERSION=2.5.303 \
    NODE_ENV=production

RUN apk add --no-cache \
    nodejs npm bash curl git python3 make g++ \
    postgresql-client ca-certificates tzdata \
    && rm -rf /var/cache/apk/*

RUN addgroup -g 1000 wiki && \
    adduser -D -u 1000 -G wiki wiki

RUN mkdir -p /wiki && chown wiki:wiki /wiki

USER wiki
WORKDIR /wiki

RUN wget -qO- https://github.com/Requarks/wiki/releases/download/v${WIKI_VERSION}/wiki-js.tar.gz | tar xz

RUN npm install --omit=dev --legacy-peer-deps

COPY --chown=wiki:wiki start-wiki.sh /wiki/start-wiki.sh

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s \
    CMD curl -f http://localhost:3000/healthz || exit 1

CMD ["/wiki/start-wiki.sh"]
EOF

echo "✓ Dockerfile created"
echo ""

# Create docker-compose.yml
echo "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
services:
  database:
    image: postgres:15-alpine
    container_name: wikijs-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: wiki
      POSTGRES_USER: wikijs
      POSTGRES_PASSWORD: wikijsrocks
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - wiki-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U wikijs -d wiki"]
      interval: 10s
      timeout: 5s
      retries: 5

  wiki:
    build: .
    container_name: wikijs-app
    restart: unless-stopped
    depends_on:
      database:
        condition: service_healthy
    environment:
      DB_TYPE: postgres
      DB_HOST: database
      DB_PORT: 5432
      DB_USER: wikijs
      DB_PASS: wikijsrocks
      DB_NAME: wiki
    volumes:
      - wiki-data:/wiki/data
    networks:
      - wiki-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 90s

  nginx:
    image: nginx:alpine
    container_name: wikijs-nginx
    restart: unless-stopped
    depends_on:
      wiki:
        condition: service_started
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
    networks:
      - wiki-network

volumes:
  db-data:
  wiki-data:

networks:
  wiki-network:
    driver: bridge
EOF

echo "✓ docker-compose.yml created"
echo ""

# Create .dockerignore
cat > .dockerignore << 'EOF'
.git
*.md
docs/
backups/
nginx/
docker-compose.yml
.env
EOF

echo "✓ .dockerignore created"
echo ""

echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Project structure created in current directory:"
echo "  - Dockerfile (custom Wiki.js image)"
echo "  - docker-compose.yml (multi-container setup)"
echo "  - start-wiki.sh (Wiki.js startup script)"
echo "  - nginx/nginx.conf (reverse proxy config)"
echo "  - nginx/ssl/ (SSL certificates)"
echo ""
echo "Next steps:"
echo "  1. Review the files created"
echo "  2. Run: docker compose build"
echo "  3. Run: docker compose up -d"
echo "  4. Access: https://localhost"
echo ""
echo "================================================"