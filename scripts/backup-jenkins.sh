#!/bin/bash
################################################################################
# Jenkins Backup Script
# Purpose: Backup Jenkins configuration, jobs, and plugins
# Usage: sudo bash backup-jenkins.sh [backup-location]
################################################################################

set -e

# Configuration
JENKINS_HOME="/var/lib/jenkins"
BACKUP_DIR="${1:-/tmp/jenkins-backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jenkins-backup-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Jenkins Backup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Check if Jenkins home exists
if [ ! -d "$JENKINS_HOME" ]; then
    echo -e "${RED}Error: Jenkins home directory not found: $JENKINS_HOME${NC}"
    exit 1
fi

# Create backup directory
echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p "$BACKUP_PATH"

# Backup Jenkins configuration
echo -e "${YELLOW}Backing up Jenkins configuration...${NC}"
cp -r "$JENKINS_HOME/config.xml" "$BACKUP_PATH/" 2>/dev/null || echo "No config.xml found"
cp -r "$JENKINS_HOME/*.xml" "$BACKUP_PATH/" 2>/dev/null || true

# Backup jobs
echo -e "${YELLOW}Backing up Jenkins jobs...${NC}"
if [ -d "$JENKINS_HOME/jobs" ]; then
    mkdir -p "$BACKUP_PATH/jobs"
    cp -r "$JENKINS_HOME/jobs" "$BACKUP_PATH/"
    echo "Jobs backed up: $(ls -1 $JENKINS_HOME/jobs | wc -l)"
else
    echo "No jobs directory found"
fi

# Backup users
echo -e "${YELLOW}Backing up Jenkins users...${NC}"
if [ -d "$JENKINS_HOME/users" ]; then
    mkdir -p "$BACKUP_PATH/users"
    cp -r "$JENKINS_HOME/users" "$BACKUP_PATH/"
fi

# Backup plugins list
echo -e "${YELLOW}Backing up plugins list...${NC}"
if [ -d "$JENKINS_HOME/plugins" ]; then
    ls -1 "$JENKINS_HOME/plugins" | grep -v ".jpi.pinned" | sed 's/.jpi$//' > "$BACKUP_PATH/plugins.txt"
    echo "Plugins backed up: $(cat $BACKUP_PATH/plugins.txt | wc -l)"
fi

# Backup secrets
echo -e "${YELLOW}Backing up secrets...${NC}"
cp "$JENKINS_HOME/secrets/master.key" "$BACKUP_PATH/" 2>/dev/null || echo "No master.key found"
cp "$JENKINS_HOME/secrets/hudson.util.Secret" "$BACKUP_PATH/" 2>/dev/null || echo "No hudson.util.Secret found"

# Backup credentials
echo -e "${YELLOW}Backing up credentials...${NC}"
if [ -d "$JENKINS_HOME/credentials.xml" ]; then
    cp "$JENKINS_HOME/credentials.xml" "$BACKUP_PATH/"
fi

# Create metadata file
echo -e "${YELLOW}Creating backup metadata...${NC}"
cat > "$BACKUP_PATH/backup-metadata.txt" << EOF
Backup Date: $(date)
Jenkins Home: $JENKINS_HOME
Hostname: $(hostname)
Jenkins Version: $(cat $JENKINS_HOME/config.xml | grep -oP '(?<=<version>)[^<]+' || echo "Unknown")
Backup Size: $(du -sh $BACKUP_PATH | cut -f1)
EOF

# Create compressed archive
echo -e "${YELLOW}Creating compressed archive...${NC}"
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
ARCHIVE_SIZE=$(du -sh "${BACKUP_NAME}.tar.gz" | cut -f1)

# Remove uncompressed backup
rm -rf "$BACKUP_NAME"

# Display summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Backup Completed Successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Backup Location: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo "Archive Size: $ARCHIVE_SIZE"
echo "Timestamp: $TIMESTAMP"
echo ""
echo -e "${YELLOW}To restore this backup, use:${NC}"
echo "sudo bash restore-jenkins.sh ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo ""

# Optional: Upload to GCS (uncomment if needed)
# echo -e "${YELLOW}Uploading to Google Cloud Storage...${NC}"
# gsutil cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" gs://your-backup-bucket/jenkins-backups/
# echo "Uploaded to: gs://your-backup-bucket/jenkins-backups/${BACKUP_NAME}.tar.gz"

exit 0
