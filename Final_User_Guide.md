# Wiki.js Final Project - User Guide

**Quick Start Guide for Deployment and Usage**

---

## What You're Deploying

A complete documentation platform with:
- Wiki.js for creating and managing documentation
- PostgreSQL for storing data
- Nginx for secure HTTPS access

**Access:** `https://localhost` (not port 3000 anymore!)

---

## Prerequisites

- Docker installed (20.10+)
- Docker Compose installed (2.0+)
- 4GB RAM available
- 20GB disk space

**Check versions:**
```bash
docker --version
docker compose version
```

---

## Quick Deployment (5 Minutes)

### Step 1: Setup Project

```bash
# Run the setup script
chmod +x setup-final.sh
./setup-final.sh
```

**What this creates:**
- Dockerfile for Wiki.js
- docker-compose.yml for orchestration
- Nginx configuration
- SSL certificates
- All necessary directories

### Step 2: Build and Deploy

```bash
# Build the custom Wiki.js image
docker compose build

# Start all containers
docker compose up -d
```

**Wait 30-60 seconds** for everything to start.

### Step 3: Verify Deployment

```bash
# Check all containers are running
docker compose ps
```

**Expected output:**
```
NAME            STATUS
wikijs-app      Up (healthy)
wikijs-db       Up (healthy)
wikijs-nginx    Up
```

### Step 4: Access Wiki.js

1. Open browser to: **`https://localhost`**
2. You'll see SSL warning (this is normal for self-signed certificates)
3. Click **"Advanced"** → **"Proceed to localhost"**
4. Wiki.js setup wizard appears!

---

## Initial Setup

### First-Time Configuration

**Step 1: Administrator Account**
- Email: your-email@example.com
- Password: Choose strong password (8+ characters)
- Confirm password

**Step 2: Site Settings**
- Site URL: `https://localhost`
- Site Title: "My Documentation"
- Description: Optional

**Step 3: Install**
- Click "Install"
- Wait 30-60 seconds
- Redirects to login page

**Step 4: Login**
- Use email and password from Step 1
- You're in! 🎉

---

## Using Wiki.js

### Creating Pages

1. Click **"Create"** button (top right)
2. Choose path: `/getting-started` or `/team/docs`
3. Select editor: **Markdown** (recommended)
4. Write content
5. Click **"Create"**

### Organizing Content

**Use paths for structure:**
```
/getting-started/installation
/guides/user-manual
/team/engineering/onboarding
```

**Add tags:**
- tutorial
- api-docs
- internal

### Editing Pages

1. Navigate to page
2. Click **"Edit"** button (pencil icon)
3. Make changes
4. Click **"Save"**

### Searching

- Use search bar in navigation
- Search by title or content
- Filter by tags

---

## Administration

### Add Users

1. Click profile icon → **"Administration"**
2. Go to **"Users"**
3. Click **"New User"**
4. Enter details and assign role:
   - **Admin:** Full access
   - **Editor:** Create and edit
   - **Viewer:** Read only

### Customize Appearance

1. **Administration** → **"Theme"**
2. Choose theme
3. Upload logo
4. Customize colors

---

## Container Management

### Check Status

```bash
# View all containers
docker compose ps

# View logs
docker compose logs -f

# View specific container
docker compose logs wiki
```

### Stop/Start

```bash
# Stop everything
docker compose stop

# Start everything
docker compose start

# Restart everything
docker compose restart
```

### View Resource Usage

```bash
docker stats
```

---

## Backup and Restore

### Manual Backup

```bash
# Create backup directory
mkdir -p backups

# Backup database
docker compose exec database pg_dump -U wikijs wiki > backups/wiki-$(date +%Y%m%d).sql

# Or backup entire volume
docker run --rm \
  -v final-deliverables_db-data:/data \
  -v $(pwd)/backups:/backup \
  alpine tar czf /backup/db-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore from Backup

```bash
# Stop Wiki.js
docker compose stop wiki

# Restore database
cat backups/wiki-YYYYMMDD.sql | docker compose exec -T database psql -U wikijs wiki

# Start Wiki.js
docker compose start wiki
```

---

## Troubleshooting

### Can't Access https://localhost

**Check containers:**
```bash
docker compose ps
```

All should show "Up". If not:
```bash
docker compose up -d
```

**Check nginx logs:**
```bash
docker compose logs nginx
```

### Database Connection Errors

```bash
# Check database health
docker compose exec database pg_isready -U wikijs

# Restart database
docker compose restart database
```

### SSL Certificate Warning

This is **normal** for self-signed certificates. Click:
- Chrome: "Advanced" → "Proceed to localhost"
- Firefox: "Advanced" → "Accept Risk and Continue"
- Safari: "Show Details" → "Visit this website"

**For production:** Use Let's Encrypt for real certificates.

### Pages Not Loading/Saving

```bash
# Check logs for errors
docker compose logs wiki

# Restart Wiki.js
docker compose restart wiki
```

### Forgot Admin Password

```bash
# Access Wiki.js container
docker compose exec wiki /bin/sh

# Reset password (inside container)
node server user:reset-password admin@example.com
```

---

## Common Tasks

### Change Passwords

**In .env file** (before first deployment):
```bash
POSTGRES_PASSWORD=your_secure_password
```

**After deployment:** Best to recreate with new password.

### Use Different Port

**Edit docker-compose.yml:**
```yaml
nginx:
  ports:
    - "8080:80"
    - "8443:443"
```

Access at: `https://localhost:8443`

### Add More Memory

**Edit docker-compose.yml:**
```yaml
wiki:
  deploy:
    resources:
      limits:
        memory: 2G
```

---

## Understanding the Architecture

### What Each Container Does

**Nginx (Port 80/443):**
- Your browser connects here
- Handles HTTPS encryption
- Forwards requests to Wiki.js

**Wiki.js (Internal Port 3000):**
- The application server
- Handles page creation, editing, searching
- Talks to PostgreSQL for data

**PostgreSQL (Internal Port 5432):**
- Stores all your documentation
- User accounts and settings
- Not directly accessible from outside

### Why Not Access Port 3000 Directly?

**Security!**
- Port 3000 is internal only
- All traffic goes through Nginx
- Nginx adds HTTPS encryption
- Professional setup

---

## Best Practices

### Content Organization

✅ **Do:**
- Use clear paths: `/team/engineering/setup`
- Add descriptive titles
- Use tags for categorization
- Include table of contents for long pages

❌ **Don't:**
- Put spaces in paths
- Use special characters
- Make extremely long pages
- Forget to save drafts

### Security

✅ **Do:**
- Use strong passwords
- Limit admin access
- Regular backups
- Keep Wiki.js updated

❌ **Don't:**
- Share admin credentials
- Leave default passwords
- Expose port 3000 directly
- Skip backups

### Performance

✅ **Do:**
- Restart monthly
- Monitor disk space
- Optimize images before upload
- Clean up unused pages

❌ **Don't:**
- Upload huge files (>50MB)
- Create thousands of pages without cleanup
- Ignore resource warnings

---

## Maintenance

### Weekly

```bash
# Check status
docker compose ps

# Check logs for errors
docker compose logs --tail 100 | grep -i error

# Backup database
docker compose exec database pg_dump -U wikijs wiki > backups/weekly-$(date +%Y%m%d).sql
```

### Monthly

```bash
# Restart containers
docker compose restart

# Check updates
docker compose pull
docker compose up -d

# Clean up old backups
find backups/ -name "*.sql" -mtime +30 -delete
```

---

## Uninstalling

### Remove Containers (Keep Data)

```bash
docker compose down
```

Data remains in volumes. Redeploy anytime with:
```bash
docker compose up -d
```

### Complete Removal (Delete Everything)

⚠️ **WARNING: This deletes all data!**

```bash
# Stop and remove everything
docker compose down -v

# Remove images
docker rmi final-deliverables-wiki

# Remove backup files
rm -rf backups/
```

---

## Getting Help

### Check Logs

```bash
# All containers
docker compose logs

# Specific container
docker compose logs wiki
docker compose logs database
docker compose logs nginx

# Follow logs in real-time
docker compose logs -f
```

### Common Error Messages

**"Connection refused"**
→ Database not ready, wait 30 seconds

**"Port already in use"**
→ Another service using port 80/443, change ports

**"Out of memory"**
→ Increase Docker memory limits

### Resources

- Wiki.js Docs: https://docs.requarks.io/
- Docker Docs: https://docs.docker.com/
- PostgreSQL Docs: https://www.postgresql.org/docs/

---

## Quick Reference

### Essential Commands

```bash
# Deploy
docker compose up -d

# Stop
docker compose stop

# Restart
docker compose restart

# Status
docker compose ps

# Logs
docker compose logs -f

# Backup
docker compose exec database pg_dump -U wikijs wiki > backup.sql

# Remove (keep data)
docker compose down
```

### Access URLs

- **Main:** https://localhost
- **Admin:** Click profile → Administration
- **Logs:** `docker compose logs -f`

### Default Credentials

- **Database User:** wikijs
- **Database Password:** wikijsrocks (change in production!)
- **Wiki Admin:** Set during first setup

---

## Summary

✅ **What You Have:**
- Professional documentation platform
- Secure HTTPS access
- Production database
- Easy container management

✅ **What You Can Do:**
- Create and organize documentation
- Manage users and permissions
- Backup and restore data
- Scale as needed

✅ **What You Learned:**
- Multi-container deployment
- Docker Compose
- Reverse proxy configuration
- Production best practices

---

**Need More Help?**

Check the FINAL_SUBMISSION.md for technical details and architecture explanation.

**Happy Documenting!**