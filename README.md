# Wiki.js Documentation Server — Project Development & Final Deliverables

**Student:** Mayson Novillo  
**Course:** IT601 / Container Technologies  
**Project:** Wiki.js Documentation Server  
**Project Progression:** Midterm → Final Deliverables

---

## Project Overview

This document combines the development process documented for the **midterm single-container deployment** with the changes and final deliverables completed for the **final multi-container deployment**.

The project began as a custom Wiki.js container built from Alpine Linux. The midterm focused on demonstrating the fundamentals of Docker containerization: building an image from a base operating system, configuring the application, managing persistent storage, running as a non-root user, and documenting deployment and maintenance.

The final project expanded that foundation into a more complete deployment architecture. Wiki.js remained a custom Alpine-based application container, but the database was separated into PostgreSQL, Docker Compose was introduced for orchestration, and Nginx was added as a reverse proxy providing HTTPS access.

The result is a clear progression from a working educational container to a multi-container application architecture.

---

# Part I — Midterm Development Process

## 1. Project Goals

The original project goal was to build a custom Docker container for Wiki.js rather than relying on a pre-built Wiki.js image.

The midterm implementation demonstrated:

- A custom-built container based on Alpine Linux 3.19
- Wiki.js running in a single container
- SQLite as the database
- Persistent Docker volumes
- Health monitoring
- Automatic restart capabilities
- Non-root container execution
- Complete technical, user, and maintenance documentation

The midterm specifically emphasized learning the fundamentals of containerization rather than building a production-scale architecture.

---

## 2. Selecting Wiki.js

Wiki.js was selected as the application because it provides a self-hosted documentation platform with:

- A clean web interface
- Search capabilities
- Version control for content
- Multiple authentication methods
- Markdown and visual editing
- Organization and tagging
- Complete ownership of documentation data

This made it suitable for demonstrating application deployment while still providing useful functionality beyond a simple test application.

---

## 3. Choosing Alpine Linux

Alpine Linux 3.19 was selected as the base image.

The documented reasons were:

1. **Minimal footprint** — Alpine's base image is approximately 5 MB.
2. **Security-focused design** — A smaller base reduces the number of installed components.
3. **Fast builds** — Fewer packages and layers reduce build overhead.
4. **Production-oriented usage** — Alpine is commonly used for lightweight container workloads.

The midterm documentation compared this custom approach with using a pre-built `requarks/wiki` image. Building the image manually provided more control and demonstrated how the application's components work together.

---

## 4. Building the Midterm Container

The midterm container was built from `alpine:3.19`.

The image installed the required runtime and build dependencies, including:

- Node.js
- NPM
- Bash
- Curl
- Git
- Python
- Make
- G++
- SQLite-related components

A dedicated `wiki` user was created with UID/GID 1000 so the application could run without root privileges.

The application was installed into `/wiki`, with persistent application data stored separately using Docker volumes.

The resulting image was documented as approximately 350 MB.

---

## 5. Midterm Container Architecture

The original architecture was intentionally simple:

```text
Browser
   |
   | HTTP :3000
   v
+-----------------------------+
| Wiki.js Container            |
|                             |
| Alpine Linux 3.19           |
| Node.js / Wiki.js           |
| SQLite                      |
| Non-root wiki user          |
+-----------------------------+
   |
   +--> /wiki/data
   +--> /wiki/config
   +--> /wiki/repo
```

Everything required for Wiki.js was contained within the single application container.

### Database

SQLite was selected for the midterm because:

- No separate database container was required.
- Configuration was simple.
- It worked well for a small deployment.
- The database was easy to back up.
- It satisfied the single-container project requirement.

The midterm documentation explicitly identified PostgreSQL as a planned improvement for the final project.

---

## 6. Midterm Deployment Process

The documented deployment process was:

### Build the image

```bash
docker build -t custom-wikijs:1.0 .
```

### Run the container

```bash
docker run -d \
  --name wikijs \
  --restart unless-stopped \
  -p 3000:3000 \
  -v wiki-data:/wiki/data \
  -v wiki-config:/wiki/config \
  custom-wikijs:1.0
```

### Access Wiki.js

The application was accessed at:

```text
http://localhost:3000
```

The initial setup wizard was then used to create the administrator account and configure the Wiki.js instance.

---

## 7. Persistent Storage

Persistent Docker volumes were an important part of the midterm implementation.

The deployment used volumes for:

- `/wiki/data`
- `/wiki/config`
- `/wiki/repo`

This allowed application data to survive container restarts and replacement.

The project also documented backup and restore procedures using an Alpine helper container and `tar`.

Example:

```bash
docker run --rm \
  -v wiki-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/wiki-backup-$(date +%Y%m%d).tar.gz /data
```

---

## 8. Health Monitoring

The midterm implementation included health monitoring so the container could be checked automatically.

Testing included:

```bash
docker inspect wikijs | grep -A 5 '"Health"'
```

The project also documented checks for:

- Successful image builds
- Container startup
- Web access
- Setup wizard completion
- Administrator login
- Page creation
- Page editing
- Search
- Data persistence
- Container health
- Error-free logs

---

## 9. Midterm Troubleshooting Process

The midterm documentation included troubleshooting for several common problems.

### Container fails to start

```bash
docker logs wikijs
```

### Port conflict

If port 3000 was already in use, a different host port could be mapped:

```bash
docker run -p 8080:3000 ...
```

### Web interface unavailable

The documentation recommended checking:

```bash
docker ps
docker port wikijs
docker exec wikijs curl -I http://localhost:3000
```

### Data loss after restart

The documented cause was failure to use persistent volumes.

The solution was to consistently use volume mappings such as:

```bash
-v wiki-data:/wiki/data
-v wiki-config:/wiki/config
```

### Memory problems

Container resource usage could be inspected with:

```bash
docker stats wikijs
```

---

## 10. Midterm Maintenance Process

The maintenance documentation expanded the project beyond simply getting the container running.

Routine maintenance included:

- Reviewing container logs
- Monitoring CPU, memory, and disk usage
- Verifying backups
- Reviewing storage growth
- Auditing user access
- Monitoring performance
- Reviewing security configuration
- Checking for image and dependency updates

Example resource check:

```bash
docker stats wikijs --no-stream
```

The maintenance process established a foundation for the operational concerns addressed more directly by the final architecture.

---

# Part II — What Changed for the Final

## 11. The Main Architectural Change

The largest change was moving from a **single-container architecture** to a **three-container architecture**.

### Midterm

```text
Browser
   |
   v
Wiki.js + SQLite
(single container)
```

### Final

```text
Browser
   |
 HTTPS :443
   |
   v
+-------------------+
| Nginx             |
| Reverse Proxy     |
| SSL/TLS           |
+---------+---------+
          |
          | HTTP :3000
          v
+-------------------+
| Wiki.js           |
| Custom Alpine     |
| Application       |
+---------+---------+
          |
          | PostgreSQL :5432
          v
+-------------------+
| PostgreSQL        |
| Database          |
+-------------------+
```

This separation made each service responsible for one primary function.

---

## 12. Database Change: SQLite → PostgreSQL

### Midterm

The Wiki.js application and SQLite database existed inside the same container.

### Final

The database became its own PostgreSQL container:

```yaml
database:
  image: postgres:15-alpine
```

The final deployment gives PostgreSQL its own persistent volume:

```yaml
volumes:
  - db-data:/var/lib/postgresql/data
```

The database is connected to the Wiki.js application through the Docker network rather than being exposed directly to the host.

### Why the Change Was Made

The final documentation identifies PostgreSQL as preferable for the expanded deployment because it:

- Supports multiple concurrent users
- Provides stronger scalability
- Is a production-oriented relational database
- Separates database responsibilities from the application container

This was the natural progression from the midterm's intentionally simple SQLite implementation.

---

## 13. Docker Compose Was Added

The midterm used individual Docker commands such as:

```bash
docker build ...
docker run ...
```

The final deployment uses Docker Compose.

The three services are:

```text
database
wiki
nginx
```

Docker Compose manages:

- Container creation
- Startup order
- Service dependencies
- Environment variables
- Volumes
- Networking
- Health checks
- Restart policies
- Port mappings

The final deployment can therefore be started with:

```bash
docker compose up -d
```

instead of manually starting each container.

---

## 14. Database Health Dependency

The final Compose configuration added an explicit dependency between PostgreSQL and Wiki.js.

PostgreSQL has a health check:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U wikijs -d wiki"]
  interval: 10s
  timeout: 5s
  retries: 5
```

Wiki.js waits for the database to become healthy:

```yaml
depends_on:
  database:
    condition: service_healthy
```

This improves startup reliability by preventing Wiki.js from attempting to connect to a database that has not finished initializing.

---

## 15. Nginx Reverse Proxy Was Added

The final project added an Nginx container.

Its responsibilities include:

- Receiving browser traffic
- Redirecting HTTP to HTTPS
- Terminating SSL/TLS
- Forwarding requests to Wiki.js
- Keeping Wiki.js's application port internal

The final public access point changed from:

```text
http://localhost:3000
```

to:

```text
https://localhost
```

Port 3000 remains the internal Wiki.js application port.

---

## 16. HTTPS and SSL/TLS

The final deployment generates self-signed certificates through `setup-final.sh`.

The script creates:

```text
nginx/ssl/key.pem
nginx/ssl/cert.pem
```

The Nginx configuration then uses those certificates for HTTPS.

HTTP traffic is redirected:

```nginx
server {
    listen 80;
    return 301 https://$host$request_uri;
}
```

HTTPS is served on port 443:

```nginx
server {
    listen 443 ssl;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
}
```

The certificates are self-signed, so a browser warning is expected during local development.

The final documentation identifies Let's Encrypt as the appropriate future direction for production certificates.

---

## 17. Network Isolation

The final project introduced a dedicated Docker bridge network:

```yaml
networks:
  wiki-network:
    driver: bridge
```

All three services join this network.

The application can therefore communicate with the database using the service name:

```text
database
```

Nginx communicates with Wiki.js through:

```text
wiki:3000
```

The database and Wiki.js application are not directly exposed to the host.

Only Nginx publishes ports:

```yaml
ports:
  - "80:80"
  - "443:443"
```

This changes the external access model from direct application access to a reverse-proxy architecture.

---

## 18. Final Wiki.js Image

The custom Wiki.js image remained based on Alpine Linux:

```dockerfile
FROM alpine:3.19
```

The final Dockerfile was updated to support PostgreSQL:

```dockerfile
postgresql-client
```

It also defines:

```dockerfile
ENV WIKI_VERSION=2.5.303 \
    NODE_ENV=production
```

The application continues to run as the non-root `wiki` user.

The final image also contains a health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s \
    CMD curl -f http://localhost:3000/healthz || exit 1
```

Thus, the original custom-image work from the midterm was retained rather than replaced with a pre-built Wiki.js image.

---

## 19. Environment-Based Database Configuration

The final deployment introduced a startup script that creates the Wiki.js configuration using environment variables.

The relevant values include:

```text
DB_TYPE
DB_HOST
DB_PORT
DB_USER
DB_PASS
DB_NAME
```

The resulting configuration points Wiki.js toward PostgreSQL rather than SQLite.

This allows the application container to remain separate from the database implementation.

---

## 20. Final Automated Setup

The final project introduced:

```text
setup-final.sh
```

The setup script automates much of the initial deployment preparation.

It:

1. Creates the directory structure.
2. Creates the Nginx SSL directory.
3. Creates the backup directory.
4. Generates self-signed certificates.
5. Creates the Nginx configuration.
6. Creates the Wiki.js startup script.
7. Creates the production Dockerfile.
8. Creates the Docker Compose configuration.
9. Creates the `.dockerignore` file.
10. Provides the final deployment commands.

This reduces the amount of manual setup required compared with the midterm.

---

# Part III — Final Deployment Process

## 21. Final Project Structure

The final deliverables contain:

```text
Final Deliverables/
├── Dockerfile
├── docker-compose.yml
├── setup-final.sh
├── start-wiki.sh
├── .dockerignore
├── BuildDeploy.md
├── Final_User_Guide.md
├── FINAL_SUBMISSION.md
├── Maintenance_Checklist.md
├── docs/
├── backups/
└── nginx/
    ├── nginx.conf
    └── ssl/
        ├── cert.pem
        └── key.pem
```

---

## 22. Final Deployment Steps

### Step 1 — Run setup

```bash
chmod +x setup-final.sh
./setup-final.sh
```

This prepares the required configuration, certificates, scripts, and directory structure.

### Step 2 — Build

```bash
docker compose build
```

### Step 3 — Start

```bash
docker compose up -d
```

### Step 4 — Verify

```bash
docker compose ps
```

The expected services are:

```text
wikijs-app
wikijs-db
wikijs-nginx
```

### Step 5 — Access the Application

Open:

```text
https://localhost
```

Because the project uses a self-signed certificate, the browser may display a certificate warning.

---

# Part IV — Final Deliverables and Documentation

## 23. Final User Guide

The final user guide expanded the midterm deployment instructions to cover the complete three-container environment.

It documents:

- Docker and Docker Compose prerequisites
- Automated setup
- Building the application
- Starting all containers
- Verifying container health
- Accessing Wiki.js through HTTPS
- Initial administrator setup
- Creating and organizing pages
- Editing content
- Searching
- User administration
- Appearance customization
- Container management
- Backups
- Restoration
- Troubleshooting
- Port changes
- Resource limits
- Architecture
- Maintenance
- Uninstallation

The main access URL is now:

```text
https://localhost
```

rather than the midterm's:

```text
http://localhost:3000
```

---

## 24. Backup and Restore Improvements

The final deployment separates the database into a persistent PostgreSQL volume:

```text
db-data
```

The final guide documents database backups using:

```bash
docker compose exec database \
  pg_dump -U wikijs wiki > backups/wiki-$(date +%Y%m%d).sql
```

It also documents full volume backup using an Alpine container.

Restoration is performed through PostgreSQL:

```bash
cat backups/wiki-YYYYMMDD.sql | \
docker compose exec -T database psql -U wikijs wiki
```

This is a significant change from the midterm's SQLite file/volume backup approach.

---

## 25. Final Container Management

Instead of managing one container individually, the final project uses Compose-level commands.

### Check status

```bash
docker compose ps
```

### View logs

```bash
docker compose logs -f
```

### Stop services

```bash
docker compose stop
```

### Start services

```bash
docker compose start
```

### Restart services

```bash
docker compose restart
```

### View resource usage

```bash
docker stats
```

This reflects the final project's shift toward managing an application stack rather than a single container.

---

# Part V — Midterm vs. Final Comparison

## 26. Architecture Comparison

| Area | Midterm | Final |
|---|---|---|
| Application | Wiki.js | Wiki.js |
| Base image | Alpine Linux 3.19 | Alpine Linux 3.19 |
| Application container | One | One |
| Database | SQLite | PostgreSQL 15 |
| Database location | Inside application container | Separate container |
| Orchestration | Docker CLI | Docker Compose |
| Reverse proxy | None | Nginx |
| External protocol | HTTP | HTTPS |
| External port | 3000 | 443 |
| Application port | 3000 | Internal only |
| Networking | Direct host mapping | Dedicated Docker network |
| Persistence | Docker volumes | Docker volumes |
| Health checks | Application container | Database + application |
| Restart policy | Container-level | All services |
| SSL/TLS | None | Nginx + self-signed certificates |
| Setup | Manual Docker commands | Automated setup script + Compose |
| Database backup | SQLite volume | PostgreSQL dump / volume |
| Intended architecture | Educational single-container | Multi-container production-style |

---

## 27. What Stayed the Same

The final project did not discard the work completed for the midterm.

The following components were carried forward:

- Wiki.js as the application
- Alpine Linux as the base image
- Custom Docker image construction
- Non-root `wiki` user
- Persistent Docker storage
- Health monitoring
- Troubleshooting documentation
- User-focused deployment instructions
- Maintenance planning
- Docker/container fundamentals

The final project therefore represents an expansion of the midterm rather than an entirely separate implementation.

---

## 28. What Was Added or Replaced

### Added

- PostgreSQL container
- Nginx container
- Docker Compose
- Dedicated Docker network
- HTTPS
- SSL certificates
- Automated setup script
- PostgreSQL health check
- Multi-service startup dependencies
- PostgreSQL backup/restore procedures
- Final multi-container architecture documentation

### Replaced

- SQLite → PostgreSQL
- Direct port 3000 access → Nginx HTTPS access
- Individual `docker run` commands → Docker Compose
- Single-container architecture → three-service architecture

### Retained

- Alpine Linux
- Custom Wiki.js image
- Non-root execution
- Persistent storage
- Health monitoring
- Documentation and maintenance practices

---

# Part VI — Final Architecture Walkthrough

## 29. Request Flow

A normal request now follows this path:

```text
1. User opens https://localhost
                |
                v
2. Nginx receives HTTPS request
                |
                v
3. Nginx terminates SSL/TLS
                |
                v
4. Nginx forwards request to wiki:3000
                |
                v
5. Wiki.js processes the request
                |
                v
6. Wiki.js communicates with database:5432
                |
                v
7. PostgreSQL returns requested data
                |
                v
8. Wiki.js generates response
                |
                v
9. Nginx sends HTTPS response
                |
                v
10. Browser displays Wiki.js
```

This makes the responsibilities of the three services explicit.

---

## 30. Service Responsibilities

### Nginx

- Public entry point
- HTTPS termination
- HTTP → HTTPS redirect
- Reverse proxy
- Forwards requests to Wiki.js

### Wiki.js

- Web application
- Documentation management
- User authentication
- Page creation and editing
- Search
- Communication with PostgreSQL

### PostgreSQL

- Persistent relational database
- Documentation data
- User and configuration data
- Database health monitoring

---

# Part VII — Final Testing and Verification

## 31. Final Verification Checklist

The final deployment should be verified in the following order.

### Build

```bash
docker compose build
```

Confirm the custom Wiki.js image builds successfully.

### Start

```bash
docker compose up -d
```

Confirm all required services start.

### Container status

```bash
docker compose ps
```

Verify:

- `wikijs-db` is healthy
- `wikijs-app` is healthy
- `wikijs-nginx` is running

### Database health

```bash
docker compose exec database pg_isready -U wikijs
```

### Wiki.js health

```bash
docker compose exec wiki \
  curl -f http://localhost:3000/healthz
```

### Nginx access

```bash
curl -k https://localhost
```

### Application test

Verify through the browser that:

- The setup page loads.
- An administrator can be created.
- Login works.
- Pages can be created.
- Pages can be edited.
- Pages can be saved.
- Search works.
- Data persists after a restart.

---

# Part VIII — Final Project Result

## 32. Final State

The project progressed from a working custom single-container Wiki.js deployment into a multi-container architecture consisting of:

```text
                    Browser
                       |
                  HTTPS :443
                       |
                       v
                +-------------+
                |    Nginx    |
                | Reverse     |
                | Proxy / SSL |
                +------+------+
                       |
                  HTTP :3000
                       |
                       v
                +-------------+
                |   Wiki.js   |
                | Alpine 3.19 |
                +------+------+
                       |
                 PostgreSQL
                    :5432
                       |
                       v
                +-------------+
                | PostgreSQL  |
                | 15-alpine   |
                +-------------+
```

The final architecture adds service separation, database separation, network isolation, HTTPS, automated orchestration, and expanded operational documentation while preserving the custom containerization work established during the midterm.

---

## 33. Lessons Demonstrated

### Container Fundamentals

- Building containers from base images
- Installing application dependencies
- Managing image layers
- Running applications as non-root users
- Persistent volume management
- Container health checks

### Orchestration

- Docker Compose
- Service dependencies
- Health-based startup
- Environment configuration
- Multi-container networking

### System Architecture

- Reverse proxy design
- Database separation
- Network isolation
- SSL/TLS termination
- Service-specific responsibilities

### Operations

- Logging
- Monitoring
- Backups
- Restore procedures
- Troubleshooting
- Maintenance planning

### Documentation

- Technical build documentation
- End-user instructions
- Administrative maintenance procedures
- Architecture explanation
- Final project comparison

---

# 34. Final Deliverables Summary

The completed final project contains the following major deliverables:

- **`Dockerfile`** — Custom Alpine-based Wiki.js application image
- **`docker-compose.yml`** — Three-service orchestration
- **`start-wiki.sh`** — Runtime Wiki.js configuration
- **`setup-final.sh`** — Automated project setup
- **`nginx/nginx.conf`** — HTTPS reverse proxy configuration
- **`nginx/ssl/`** — Local SSL certificates
- **`BuildDeploy.md`** — Build and deployment documentation
- **`Final_User_Guide.md`** — User and administrator guide
- **`Maintenance_Checklist.md`** — Maintenance and operational procedures
- **`FINAL_SUBMISSION.md`** — Final architecture and project explanation

---

# 35. Conclusion

The Wiki.js project developed in two major stages.

The **midterm** established the core containerization skills: a custom Alpine-based Wiki.js image, SQLite database, persistent volumes, health monitoring, non-root execution, testing, troubleshooting, and supporting documentation.

The **final project** built directly on that foundation. SQLite was separated into PostgreSQL, Docker Compose was introduced to orchestrate the services, Nginx was added as a reverse proxy, HTTPS was implemented, networking was isolated, startup dependencies were defined through health checks, and the deployment process was automated.

The final deliverable therefore demonstrates the progression from a basic single-container application to a structured multi-container deployment while preserving the original work and showing how each major architectural change addresses a limitation or requirement of the earlier implementation.

---

## Quick Reference

### Midterm

```bash
docker build -t custom-wikijs:1.0 .
docker run -d \
  --name wikijs \
  --restart unless-stopped \
  -p 3000:3000 \
  -v wiki-data:/wiki/data \
  -v wiki-config:/wiki/config \
  custom-wikijs:1.0
```

Access:

```text
http://localhost:3000
```

### Final

```bash
chmod +x setup-final.sh
./setup-final.sh
docker compose build
docker compose up -d
docker compose ps
```

Access:

```text
https://localhost
```
