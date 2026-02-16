#!/bin/bash
################################################################################
# Jenkins Restore Script
# Purpose: Restore Jenkins configuration, jobs, and plugins from backup
# Usage: sudo bash restore-jenkins.sh <backup-file.tar.gz>
################################################################################

set -e

# Configuration
JENKINS_HOME="/var/lib/jenkins"
BACKUP_FILE="$1"
RESTORE_DIR="/tmp/jenkins-restore"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins Restore Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Check if backup file provided
if [ -z "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Please provide backup file${NC}"
    echo "Usage: sudo bash restore-jenkins.sh <backup-file.tar.gz>"
    exit 1
fi

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# Stop Jenkins service
echo -e "${YELLOW}Stopping Jenkins service...${NC}"
systemctl stop jenkins || true
sleep 5

# Create restore directory
echo -e "${YELLOW}Extracting backup archive...${NC}"
rm -rf "$RESTORE_DIR"
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR"

# Find the backup directory
BACKUP_DIR=$(find "$RESTORE_DIR" -maxdepth 1 -type d -name "jenkins-backup-*" | head -n 1)

if [ -z "$BACKUP_DIR" ]; then
    echo -e "${RED}Error: Invalid backup archive${NC}"
    exit 1
fi

# Display backup metadata
if [ -f "$BACKUP_DIR/backup-metadata.txt" ]; then
    echo ""
    echo -e "${YELLOW}Backup Metadata:${NC}"
    cat "$BACKUP_DIR/backup-metadata.txt"
    echo ""
fi

# Confirm restore
echo -e "${YELLOW}WARNING: This will overwrite current Jenkins configuration!${NC}"
read -p "Continue with restore? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Backup current Jenkins home (just in case)
echo -e "${YELLOW}Creating safety backup of current Jenkins...${NC}"
SAFETY_BACKUP="/tmp/jenkins-safety-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$SAFETY_BACKUP" -C "$(dirname $JENKINS_HOME)" "$(basename $JENKINS_HOME)" 2>/dev/null || true
echo "Safety backup: $SAFETY_BACKUP"

# Restore configuration files
echo -e "${YELLOW}Restoring Jenkins configuration...${NC}"
cp -f "$BACKUP_DIR/config.xml" "$JENKINS_HOME/" 2>/dev/null || echo "No config.xml to restore"
cp -f "$BACKUP_DIR"/*.xml "$JENKINS_HOME/" 2>/dev/null || true

# Restore jobs
echo -e "${YELLOW}Restoring Jenkins jobs...${NC}"
if [ -d "$BACKUP_DIR/jobs" ]; then
    rm -rf "$JENKINS_HOME/jobs"
    cp -r "$BACKUP_DIR/jobs" "$JENKINS_HOME/"
    echo "Jobs restored: $(ls -1 $JENKINS_HOME/jobs 2>/dev/null | wc -l)"
fi

# Restore users
echo -e "${YELLOW}Restoring Jenkins users...${NC}"
if [ -d "$BACKUP_DIR/users" ]; then
    rm -rf "$JENKINS_HOME/users"
    cp -r "$BACKUP_DIR/users" "$JENKINS_HOME/"
fi

# Restore secrets
echo -e "${YELLOW}Restoring secrets...${NC}"
mkdir -p "$JENKINS_HOME/secrets"
cp -f "$BACKUP_DIR/master.key" "$JENKINS_HOME/secrets/" 2>/dev/null || echo "No master.key to restore"
cp -f "$BACKUP_DIR/hudson.util.Secret" "$JENKINS_HOME/secrets/" 2>/dev/null || echo "No hudson.util.Secret to restore"

# Restore credentials
echo -e "${YELLOW}Restoring credentials...${NC}"
cp -f "$BACKUP_DIR/credentials.xml" "$JENKINS_HOME/" 2>/dev/null || echo "No credentials to restore"

# Fix permissions
echo -e "${YELLOW}Fixing permissions...${NC}"
chown -R jenkins:jenkins "$JENKINS_HOME"
chmod -R 755 "$JENKINS_HOME"

# Start Jenkins service
echo -e "${YELLOW}Starting Jenkins service...${NC}"
systemctl start jenkins

# Wait for Jenkins to start
echo -e "${YELLOW}Waiting for Jenkins to start...${NC}"
sleep 10

# Check Jenkins status
if systemctl is-active --quiet jenkins; then
    echo -e "${GREEN}Jenkins service is running${NC}"
else
    echo -e "${RED}Warning: Jenkins service may not be running properly${NC}"
fi

# Cleanup
rm -rf "$RESTORE_DIR"

# Display summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Restore Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Jenkins Home: $JENKINS_HOME"
echo "Backup File: $BACKUP_FILE"
echo "Safety Backup: $SAFETY_BACKUP"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Verify Jenkins is accessible"
echo "2. Check all jobs are present"
echo "3. Test a sample job"
echo "4. Verify user accounts"
echo ""

exit 0
