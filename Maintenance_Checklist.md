# Wiki.js Server - System Administrator Maintenance Checklist

## Overview

This maintenance checklist is designed for system administrators responsible for keeping the Wiki.js documentation server running smoothly. Regular maintenance ensures optimal performance, security, and data integrity.

**Server Type:** Wiki.js Documentation Server  
**Deployment:** Docker Single Container  
**Database:** SQLite  
**Update Frequency:** See individual sections below

---

## Daily Maintenance Tasks (5 minutes)

### Health Check Verification

**Task:** Verify the server is running and accessible

```bash
# Check container status
docker ps | grep wikijs

# Check container health
docker inspect wikijs | grep -A 5 '"Health"'

# Quick HTTP check
curl -I http://localhost:3000
```

**Expected Results:**
- Container status: "Up"
- Health status: "healthy"
- HTTP response: 200 OK

**Action if Failed:**
- [ ] Check container logs: `docker logs --tail 100 wikijs`
- [ ] Restart container: `docker restart wikijs`
- [ ] If restart fails, check disk space: `df -h`
- [ ] Escalate if issue persists after restart

---

### Log Review

**Task:** Review logs for errors or warnings

```bash
# View last 50 lines of logs
docker logs --tail 50 wikijs

# Search for errors
docker logs wikijs 2>&1 | grep -i error | tail -20

# Search for warnings
docker logs wikijs 2>&1 | grep -i warning | tail -20
```

**What to Look For:**
- Database connection errors
- Authentication failures (possible security issue)
- Disk space warnings
- Memory allocation errors
- Unusual access patterns

**Action Items:**
- [ ] Document any errors in incident log
- [ ] Investigate authentication failures
- [ ] Address disk space warnings immediately
- [ ] Review memory usage if allocation errors appear

---

### Resource Utilization Check

**Task:** Monitor CPU, memory, and disk usage

```bash
# Container resource usage
docker stats wikijs --no-stream

# Disk usage
docker system df

# Volume size
docker volume inspect wiki-data | grep Mountpoint
# Then: du -sh <mountpoint>
```

**Normal Ranges:**
- CPU: 0-10% (idle), 10-50% (active use)
- Memory: 150-300MB (idle), 300-500MB (active)
- Disk: Grows with content, monitor growth rate

**Action if Exceeded:**
- [ ] If CPU >80% sustained: Investigate slow queries
- [ ] If Memory >1GB: Consider restart or upgrade
- [ ] If Disk >80% full: Clean up or expand storage

---

### Backup Verification

**Task:** Verify last backup completed successfully

```bash
# Check latest backup file
ls -lh ~/wikijs-backups/ | head -10

# Verify backup is recent (within 24 hours)
find ~/wikijs-backups/ -name "wiki-backup-*.tar.gz" -mtime -1
```

**Expected Results:**
- Backup file exists from within last 24 hours
- File size is reasonable (not 0 bytes)

**Action if Failed:**
- [ ] Manually trigger backup
- [ ] Check backup script is scheduled correctly
- [ ] Verify backup destination has space
- [ ] Test restore process if multiple backups fail

---

## Weekly Maintenance Tasks (15-30 minutes)

### Comprehensive Backup

**Task:** Create verified backup and test restore

```bash
# Create weekly backup with verification
DATE=$(date +%Y%m%d-%H%M%S)
docker run --rm \
  -v wiki-data:/data \
  -v ~/wikijs-backups/weekly:/backup \
  alpine tar czf /backup/wiki-weekly-$DATE.tar.gz /data

# Verify backup integrity
tar tzf ~/wikijs-backups/weekly/wiki-weekly-$DATE.tar.gz > /dev/null
echo "Backup verification: $?"  # Should output 0
```

**Checklist:**
- [ ] Weekly backup created successfully
- [ ] Backup file integrity verified
- [ ] Previous week's backup exists for redundancy
- [ ] Backup size is consistent with expected growth
- [ ] Document backup location and date

---

### Storage Usage Analysis

**Task:** Analyze storage trends and plan capacity

```bash
# Database size
docker exec wikijs ls -lh /wiki/data/database.sqlite

# Total volume usage
docker system df -v | grep wiki

# Growth rate calculation (compare to last week)
echo "Previous week size: [RECORD SIZE]"
echo "Current size: [RECORD SIZE]"
echo "Growth: [CALCULATE]"
```

**Analysis:**
- [ ] Record current database size: _____ MB
- [ ] Calculate weekly growth rate: _____ MB/week
- [ ] Estimate time until 80% capacity: _____ weeks
- [ ] Plan storage expansion if needed

---

### User Access Audit

**Task:** Review user accounts and permissions

**Via Web Interface:**
1. Login as administrator
2. Go to **Administration** → **Users**
3. Review user list

**Checklist:**
- [ ] Verify all active users should have access
- [ ] Remove accounts for departed employees
- [ ] Check for unused accounts (no recent login)
- [ ] Verify admin accounts are appropriate
- [ ] Review failed login attempts

**Action Items:**
- [ ] Disable/remove: [List usernames]
- [ ] Investigate suspicious activity: [Details]
- [ ] Reset passwords if compromised: [List users]

---

### Performance Monitoring

**Task:** Analyze performance metrics

```bash
# Response time test
time curl -s http://localhost:3000 > /dev/null

# Container uptime
docker inspect wikijs | grep StartedAt

# Check for memory leaks (compare to baseline)
docker stats wikijs --no-stream
```

**Benchmarks:**
- Page load time: <2 seconds (cold), <500ms (cached)
- API response: <1 second
- Search query: <3 seconds

**Action if Degraded:**
- [ ] Restart container to clear memory
- [ ] Check for database bloat
- [ ] Review recent changes
- [ ] Consider performance optimization

---

### Security Review

**Task:** Review security configuration and logs

```bash
# Check for security updates (Docker image)
docker pull alpine:3.19
docker images | grep alpine

# Review authentication logs
docker logs wikijs 2>&1 | grep -i "auth\|login\|password" | tail -50

# Check container security
docker scan custom-wikijs:1.0  # If Docker scan available
```

**Checklist:**
- [ ] No failed login attempts exceeding threshold
- [ ] No unauthorized access attempts
- [ ] Container base image is up to date
- [ ] No known vulnerabilities in dependencies
- [ ] SSL/TLS configured (if applicable)

---

## Monthly Maintenance Tasks (1-2 hours)

### Full System Backup & Restore Test

**Task:** Perform complete backup and test restore procedure

```bash
# Create monthly archive
DATE=$(date +%Y%m)
BACKUP_DIR=~/wikijs-backups/monthly

# Backup all volumes
docker run --rm \
  -v wiki-data:/data \
  -v wiki-config:/config \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/wiki-full-$DATE.tar.gz /data /config

# Test restore in temporary volume
docker volume create wiki-test
docker run --rm \
  -v wiki-test:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar xzf /backup/wiki-full-$DATE.tar.gz -C /
docker volume rm wiki-test
```

**Checklist:**
- [ ] Full backup created successfully
- [ ] Backup size: _____ MB
- [ ] Restore test completed without errors
- [ ] Store backup offsite (external drive, cloud)
- [ ] Verify offsite backup accessibility
- [ ] Update disaster recovery documentation

---

### Software Updates

**Task:** Check for and apply updates

```bash
# Check current Wiki.js version
docker exec wikijs node -e "console.log(require('./package.json').version)"

# Check for new Wiki.js releases
curl -s https://api.github.com/repos/Requarks/wiki/releases/latest | grep tag_name

# Check base image updates
docker pull alpine:3.19
```

**Update Process:**
1. [ ] Review release notes for breaking changes
2. [ ] Create full backup before updating
3. [ ] Update Dockerfile with new version
4. [ ] Rebuild image: `docker build -t custom-wikijs:1.1 .`
5. [ ] Test in non-production environment
6. [ ] Stop old container: `docker stop wikijs`
7. [ ] Start new version: `docker run ... custom-wikijs:1.1`
8. [ ] Verify functionality
9. [ ] Monitor for issues over 24 hours
10. [ ] Keep old image as rollback option

**Rollback Plan:**
- Keep previous image: `custom-wikijs:1.0`
- Restore from backup if data issues
- Document update in change log

---

### Database Maintenance

**Task:** Optimize database and check integrity

```bash
# Database size before optimization
docker exec wikijs ls -lh /wiki/data/database.sqlite

# SQLite integrity check
docker exec wikijs sqlite3 /wiki/data/database.sqlite "PRAGMA integrity_check;"

# Vacuum database (optimize)
docker exec wikijs sqlite3 /wiki/data/database.sqlite "VACUUM;"

# Database size after optimization
docker exec wikijs ls -lh /wiki/data/database.sqlite
```

**Checklist:**
- [ ] Integrity check passed: yes/no
- [ ] Database size before: _____ MB
- [ ] Database size after: _____ MB
- [ ] Space reclaimed: _____ MB
- [ ] No errors during vacuum

**Action if Integrity Check Fails:**
- [ ] Stop container immediately
- [ ] Restore from most recent backup
- [ ] Investigate cause of corruption
- [ ] Document incident

---

### Capacity Planning

**Task:** Analyze trends and plan resources

**Data to Collect:**
- [ ] Total pages: _____ (from Wiki.js admin)
- [ ] Total users: _____ (from Wiki.js admin)
- [ ] Database size: _____ MB
- [ ] Average daily page views: _____
- [ ] Storage growth rate: _____ MB/month
- [ ] Memory usage average: _____ MB
- [ ] CPU usage average: _____ %

**Projections:**
- Months until storage 80% full: _____
- Months until memory upgrade needed: _____
- Recommended action timeline: _____

**Planning Actions:**
- [ ] Schedule storage expansion if <6 months
- [ ] Plan migration to PostgreSQL if >10 users
- [ ] Consider multi-container setup for scaling
- [ ] Budget for hardware/cloud upgrades

---

### Documentation Review

**Task:** Update system documentation

**Items to Review:**
- [ ] Backup procedures are current
- [ ] Disaster recovery plan is tested
- [ ] Contact information is up to date
- [ ] Network diagrams reflect current setup
- [ ] Maintenance logs are complete
- [ ] Incident response procedures documented

**Updates Needed:**
- [List documentation updates required]

---

## Quarterly Maintenance Tasks (2-4 hours)

### Disaster Recovery Drill

**Task:** Full disaster recovery simulation

**Scenario:** Complete system failure, must restore from backup

**Procedure:**
1. [ ] Stop production container
2. [ ] Delete all volumes (in test environment!)
3. [ ] Restore from backup
4. [ ] Verify all data is accessible
5. [ ] Test user login
6. [ ] Verify search functionality
7. [ ] Check all integrations
8. [ ] Document time to recovery: _____ minutes
9. [ ] Note any issues encountered
10. [ ] Update DR procedures based on findings

**Success Criteria:**
- Full restore in <30 minutes
- All data intact
- No functionality loss
- Documentation is sufficient for any admin to follow

---

### Security Audit

**Task:** Comprehensive security review

**Access Control:**
- [ ] Review all user accounts
- [ ] Verify MFA is enabled (if available)
- [ ] Check password policies
- [ ] Review admin access logs
- [ ] Audit API keys and tokens

**Network Security:**
- [ ] Verify firewall rules
- [ ] Check for unnecessary open ports
- [ ] Review SSL/TLS configuration
- [ ] Scan for vulnerabilities
- [ ] Update security documentation

**Container Security:**
- [ ] Run security scan: `docker scan custom-wikijs:1.0`
- [ ] Check for vulnerable dependencies
- [ ] Verify non-root user execution
- [ ] Review volume permissions
- [ ] Check for sensitive data exposure

**Findings:**
- [Document security issues found]
- [Prioritize by severity]
- [Create remediation plan]

---

### Performance Baseline

**Task:** Establish performance benchmarks

**Tests to Run:**
1. [ ] Page load time (homepage)
2. [ ] Page load time (large document)
3. [ ] Search query response time
4. [ ] Login time
5. [ ] Document save time
6. [ ] Image upload time

**Record Results:**
| Test | Time (ms) | Baseline | Status |
|------|-----------|----------|--------|
| Homepage Load | | <2000ms | |
| Large Doc Load | | <3000ms | |
| Search Query | | <3000ms | |
| Login | | <1000ms | |
| Doc Save | | <1000ms | |
| Image Upload | | <5000ms | |

**Action Items:**
- [ ] Investigate any results >2x baseline
- [ ] Document performance trends
- [ ] Plan optimization if degrading

---

## Annual Maintenance Tasks (4-8 hours)

### Complete System Review

**Task:** Comprehensive audit of entire system

**Infrastructure:**
- [ ] Review hosting environment
- [ ] Evaluate resource allocation
- [ ] Assess scaling needs
- [ ] Review backup strategy
- [ ] Evaluate disaster recovery plan

**Usage Analysis:**
- [ ] Total pages created: _____
- [ ] Active users: _____
- [ ] Storage used: _____ GB
- [ ] Year-over-year growth: _____ %
- [ ] Most accessed content: _____

**Planning:**
- [ ] Budget for next year
- [ ] Hardware/software upgrades needed
- [ ] Training requirements
- [ ] Documentation improvements
- [ ] Process optimization opportunities

---

### Migration Planning

**Task:** Evaluate need for upgraded deployment

**Consider Migration If:**
- [ ] >20 concurrent users regularly
- [ ] Database size >5GB
- [ ] Performance consistently slow
- [ ] High availability required
- [ ] Advanced features needed

**Migration Options:**
- PostgreSQL database (more performant)
- Multi-container setup (better scaling)
- Kubernetes deployment (enterprise)
- Cloud hosting (managed service)

**Action:**
- [ ] Create migration plan
- [ ] Budget for migration
- [ ] Schedule migration window
- [ ] Develop testing plan
- [ ] Train team on new system

---

## Incident Response Procedures

### Service Down

**Immediate Actions:**
1. Check container status: `docker ps -a`
2. Review logs: `docker logs --tail 100 wikijs`
3. Check disk space: `df -h`
4. Attempt restart: `docker restart wikijs`
5. If restart fails, check database integrity
6. Restore from backup if necessary

**Escalation:** If service not restored in 30 minutes

---

### Data Corruption

**Immediate Actions:**
1. Stop container immediately: `docker stop wikijs`
2. Do not restart until issue identified
3. Create forensic backup of current state
4. Check database integrity
5. Restore from last known good backup
6. Analyze logs for corruption cause

**Escalation:** Immediate notification to management

---

### Security Breach

**Immediate Actions:**
1. Isolate container: `docker network disconnect wikijs`
2. Stop container if actively compromised
3. Preserve logs: `docker logs wikijs > incident-$(date +%s).log`
4. Change all passwords
5. Review access logs
6. Scan for malware
7. Restore from clean backup if compromised

**Escalation:** Immediate notification to security team and management

---

## Maintenance Log Template

### Monthly Log Entry

**Date:** _______________  
**Administrator:** _______________  
**Maintenance Window:** _______________ to _______________

**Tasks Completed:**
- [ ] Daily checks reviewed
- [ ] Weekly backups verified
- [ ] Monthly backup created
- [ ] Software updates checked
- [ ] Database optimized
- [ ] Security review completed

**Findings:**
- [List any issues found]
- [Performance metrics]
- [Security concerns]
- [User feedback]

**Actions Taken:**
- [List remediation steps]
- [Updates applied]
- [Configuration changes]

**Follow-up Required:**
- [Items needing further attention]
- [Scheduled maintenance]
- [Upgrade planning]

**Next Review:** _______________

---

## Contact Information

### Escalation Chain

**Primary Administrator:**  
Name: _______________  
Email: _______________  
Phone: _______________

**Secondary Administrator:**  
Name: _______________  
Email: _______________  
Phone: _______________

**Management Contact:**  
Name: _______________  
Email: _______________  
Phone: _______________

### Vendor Support

**Wiki.js Community:**  
- GitHub: https://github.com/Requarks/wiki
- Discussions: https://github.com/Requarks/wiki/discussions
- Documentation: https://docs.requarks.io/

**Docker Support:**  
- Documentation: https://docs.docker.com/
- Community: https://forums.docker.com/

---

## Notes

Use this section for environment-specific information:

**Server Details:**
- Hostname: _______________
- IP Address: _______________
- Docker Version: _______________
- OS Version: _______________

**Customizations:**
- [Note any custom configurations]
- [Special requirements]
- [Integration details]

**Known Issues:**
- [Document recurring problems]
- [Workarounds]
- [Long-term solutions planned]