# Wiki.js Documentation Server - Build Documentation

## Project Information
**Course Project:** Container-Based Wiki.js Deployment  
**Phase:** Midterm - Single Container Implementation  
**Base Image:** Alpine Linux 3.19  
**Date:** December 2025

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Project Structure](#project-structure)
3. [Building the Container](#building-the-container)
4. [Running the Container](#running-the-container)
5. [Accessing Wiki.js](#accessing-wikijs)
6. [Troubleshooting](#troubleshooting)
7. [Testing Checklist](#testing-checklist)

---

## Prerequisites

Before building and deploying the Wiki.js container, ensure you have:

- **Docker installed** (version 20.10 or higher)
  - Check with: `docker --version`
  - Install from: https://docs.docker.com/get-docker/
  
- **Minimum system requirements:**
  - 2 GB RAM
  - 10 GB free disk space
  - Linux, macOS, or Windows with WSL2

- **Basic command line knowledge**

- **Internet connection** (for downloading base images and dependencies)

---

## Project Structure

```
wiki-documentation-server/
├── Dockerfile                    # Main container definition
├── BUILD_DOCUMENTATION.md        # This file - build instructions
├── USER_GUIDE.md                # End-user deployment guide
├── MAINTENANCE_CHECKLIST.md     # System administrator checklist
├── .dockerignore                # Files to exclude from build context
└── README.md                    # Project overview
```

---

## Building the Container

### Step 1: Create Project Directory

```bash
mkdir wiki-documentation-server
cd wiki-documentation-server
```

### Step 2: Create the Dockerfile

Create a file named `Dockerfile` with the provided container definition (see main Dockerfile artifact).

### Step 3: Build the Image

Build the Docker image with the following command:

```bash
docker build -t custom-wikijs:1.0 .
```

**Explanation of flags:**
- `-t custom-wikijs:1.0` - Tags the image with name and version
- `.` - Uses current directory as build context

**Expected output:**
```
[+] Building 45.2s (12/12) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load .dockerignore
 => [1/7] FROM docker.io/library/alpine:3.19
 => [2/7] RUN apk add --no-cache nodejs npm bash curl...
 => [3/7] RUN addgroup -g 1000 wiki && adduser -D...
 => [4/7] RUN mkdir -p /wiki/data /wiki/config...
 => [5/7] RUN wget -qO- https://github.com/Requarks/wiki/...
 => [6/7] RUN npm install --only=production
 => [7/7] RUN cp config.sample.yml config.yml
 => exporting to image
 => => writing image sha256:abc123...
 => => naming to docker.io/library/custom-wikijs:1.0
```

### Step 4: Verify the Build

Check that your image was created successfully:

```bash
docker images | grep custom-wikijs
```

Expected output:
```
custom-wikijs    1.0    abc123def456    2 minutes ago    350MB
```

---

## Running the Container

### Basic Run Command

Start the Wiki.js container with persistent storage:

```bash
docker run -d \
  --name wikijs \
  -p 3000:3000 \
  -v wiki-data:/wiki/data \
  -v wiki-config:/wiki/config \
  custom-wikijs:1.0
```

**Explanation of flags:**
- `-d` - Run in detached mode (background)
- `--name wikijs` - Assign a friendly name to the container
- `-p 3000:3000` - Map port 3000 (host:container)
- `-v wiki-data:/wiki/data` - Create persistent volume for database
- `-v wiki-config:/wiki/config` - Create persistent volume for configuration
- `custom-wikijs:1.0` - The image to run

### Check Container Status

Verify the container is running:

```bash
docker ps
```

Expected output:
```
CONTAINER ID   IMAGE              STATUS         PORTS                    NAMES
abc123def456   custom-wikijs:1.0  Up 2 minutes   0.0.0.0:3000->3000/tcp  wikijs
```

### View Container Logs

Monitor the startup process:

```bash
docker logs -f wikijs
```

Look for successful startup messages:
```
Loading configuration from /wiki/config.yml...
Database connection established successfully
Wiki.js is running on port 3000
```

Press `Ctrl+C` to stop following logs.

---

## Accessing Wiki.js

### Initial Setup

1. **Open your web browser** and navigate to:
   ```
   http://localhost:3000
   ```

2. **First-time setup wizard** will appear:
   - Choose your administrator email
   - Set administrator password (minimum 8 characters)
   - Configure site URL (use `http://localhost:3000` for testing)
   - Click "Install"

3. **Wait for initialization** (30-60 seconds)

4. **Login** with your administrator credentials

5. **Create your first page** to verify everything works

### Default Access Information

- **URL:** http://localhost:3000
- **Admin Account:** Set during first-time setup
- **Database:** SQLite (stored in `/wiki/data/database.sqlite`)

---

## Container Management Commands

### Stop the Container
```bash
docker stop wikijs
```

### Start the Container (after stopping)
```bash
docker start wikijs
```

### Restart the Container
```bash
docker restart wikijs
```

### Remove the Container
```bash
docker stop wikijs
docker rm wikijs
```

### View Container Resource Usage
```bash
docker stats wikijs
```

### Execute Commands Inside Container
```bash
docker exec -it wikijs /bin/bash
```

---

## Data Persistence

The container uses Docker volumes to persist data across restarts and updates:

### List Volumes
```bash
docker volume ls | grep wiki
```

### Inspect Volume
```bash
docker volume inspect wiki-data
```

### Backup Data Volume
```bash
docker run --rm -v wiki-data:/data -v $(pwd):/backup alpine tar czf /backup/wiki-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore Data Volume
```bash
docker run --rm -v wiki-data:/data -v $(pwd):/backup alpine tar xzf /backup/wiki-backup-YYYYMMDD.tar.gz -C /
```

---

## Troubleshooting

### Problem: Container Fails to Start

**Check logs:**
```bash
docker logs wikijs
```

**Common causes:**
- Port 3000 already in use
- Insufficient permissions
- Corrupted volume data

**Solutions:**
```bash
# Use different port
docker run -p 8080:3000 ...

# Check for conflicting containers
docker ps -a | grep 3000
```

### Problem: Cannot Access http://localhost:3000

**Verify container is running:**
```bash
docker ps
```

**Check port mapping:**
```bash
docker port wikijs
```

**Test from inside container:**
```bash
docker exec wikijs curl -I http://localhost:3000
```

### Problem: Database Errors

**Reset database (WARNING: loses all data):**
```bash
docker stop wikijs
docker volume rm wiki-data
docker start wikijs
```

### Problem: Out of Memory

**Check container resources:**
```bash
docker stats wikijs
```

**Increase memory limit:**
```bash
docker run --memory="2g" ...
```

### Problem: Permission Errors

**Issue:** Container cannot write to volumes

**Solution:** Volumes are created with correct permissions automatically. If issues persist:
```bash
docker exec -u root wikijs chown -R wiki:wiki /wiki/data
```

---

## Testing Checklist

Use this checklist to verify your build is successful:

- [ ] Docker image builds without errors
- [ ] Image size is reasonable (<500MB)
- [ ] Container starts successfully
- [ ] Port 3000 is accessible
- [ ] Web interface loads at http://localhost:3000
- [ ] Setup wizard completes successfully
- [ ] Can create an admin account
- [ ] Can login with admin credentials
- [ ] Can create a new page
- [ ] Can edit and save content
- [ ] Search functionality works
- [ ] Container survives restart (data persists)
- [ ] Health check passes: `docker inspect wikijs | grep -A 5 Health`
- [ ] Logs show no errors: `docker logs wikijs`
- [ ] No security warnings in build process

---

## Build Process Explanation

### Why Alpine Linux?

Alpine Linux was chosen as the base image for several reasons:

1. **Minimal Size:** Base image is only ~5MB
2. **Security:** Smaller attack surface, security-focused design
3. **Performance:** Fast startup times, minimal resource usage
4. **Package Manager:** APK is simple and efficient

### What Gets Installed?

The Dockerfile installs the following:

1. **Node.js & NPM:** Runtime environment for Wiki.js
2. **Build Tools:** python3, make, g++ for compiling native dependencies
3. **Utilities:** bash, curl, git for operations
4. **Database:** SQLite for single-container setup
5. **Wiki.js Application:** Downloaded directly from GitHub releases

### Security Measures

1. **Non-root user:** Container runs as user `wiki` (UID 1000)
2. **Minimal packages:** Only essential software installed
3. **Health checks:** Automatic monitoring of service health
4. **Volume isolation:** Data stored in managed volumes

---

## Performance Optimization

### Image Size
- Current build: ~350MB
- Could be reduced further by using multi-stage builds (future improvement)

### Startup Time
- Cold start: 30-60 seconds
- Warm start: 5-10 seconds

### Resource Usage
- **RAM:** 150-300MB (idle)
- **CPU:** <5% (idle), varies with usage
- **Disk:** 100MB application + database growth

---

## Next Steps (For Final Project)

The midterm uses a single container with SQLite. For the final project, we will:

1. **Add PostgreSQL container** for production-grade database
2. **Use Docker Compose** to orchestrate multiple containers
3. **Add reverse proxy** (nginx) for SSL/TLS
4. **Implement proper networking** between containers
5. **Add backup container** for automated backups
6. **Configure environment variables** for easier deployment

---

## Additional Resources

- **Wiki.js Documentation:** https://docs.requarks.io/
- **Docker Documentation:** https://docs.docker.com/
- **Alpine Linux Packages:** https://pkgs.alpinelinux.org/
- **Node.js Best Practices:** https://github.com/goldbergyoni/nodebestpractices

---

## Questions or Issues?

If you encounter problems not covered in this documentation:

1. Check Docker logs: `docker logs wikijs`
2. Review container health: `docker inspect wikijs`
3. Verify volumes: `docker volume ls`
4. Test connectivity: `curl http://localhost:3000`