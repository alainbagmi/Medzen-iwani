#!/bin/bash
# Setup Script for Automated Backups
# Created: 2025-11-11
# Purpose: Configure cron job for automated daily backups

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Setup Automated Backups${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if backup script exists
BACKUP_SCRIPT="$HOME/backup-medzen-auto.sh"

if [ ! -f "$BACKUP_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Automated backup script not found at: $BACKUP_SCRIPT${NC}"
    echo "Please ensure the script exists before running this setup."
    exit 1
fi

echo -e "${GREEN}✓${NC} Found backup script: $BACKUP_SCRIPT"
echo ""

# Show current crontab
echo "Current cron jobs:"
echo "-------------------"
crontab -l 2>/dev/null || echo "(No cron jobs configured)"
echo ""

# Check if already configured
if crontab -l 2>/dev/null | grep -q "backup-medzen-auto.sh"; then
    echo -e "${YELLOW}⚠️  Backup cron job already exists!${NC}"
    echo ""
    read -p "Do you want to reconfigure it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting setup."
        exit 0
    fi

    # Remove existing backup job
    crontab -l 2>/dev/null | grep -v "backup-medzen-auto.sh" | crontab - || true
    echo -e "${GREEN}✓${NC} Removed existing backup job"
    echo ""
fi

# Suggest backup schedule
echo "Select backup schedule:"
echo "1) Daily at 2:00 AM"
echo "2) Daily at 3:00 AM"
echo "3) Every 12 hours (2:00 AM and 2:00 PM)"
echo "4) Custom schedule"
echo ""
read -p "Enter choice (1-4): " -n 1 -r SCHEDULE_CHOICE
echo ""
echo ""

case $SCHEDULE_CHOICE in
    1)
        CRON_SCHEDULE="0 2 * * *"
        DESCRIPTION="Daily at 2:00 AM"
        ;;
    2)
        CRON_SCHEDULE="0 3 * * *"
        DESCRIPTION="Daily at 3:00 AM"
        ;;
    3)
        CRON_SCHEDULE="0 2,14 * * *"
        DESCRIPTION="Every 12 hours (2:00 AM and 2:00 PM)"
        ;;
    4)
        echo "Enter custom cron schedule (e.g., '0 2 * * *' for daily at 2 AM):"
        read -p "Schedule: " CRON_SCHEDULE
        DESCRIPTION="Custom: $CRON_SCHEDULE"
        ;;
    *)
        echo "Invalid choice. Aborting."
        exit 1
        ;;
esac

# Add new cron job
echo -e "${YELLOW}Adding cron job...${NC}"

# Get existing crontab and add new job
(crontab -l 2>/dev/null || true; echo "# MedZen Iwani Automated Backup - $DESCRIPTION"; echo "$CRON_SCHEDULE $BACKUP_SCRIPT") | crontab -

echo -e "${GREEN}✓${NC} Cron job added successfully!"
echo ""

# Show updated crontab
echo "Updated cron jobs:"
echo "-------------------"
crontab -l
echo ""

# Test backup script
echo -e "${YELLOW}Testing backup script...${NC}"
if "$BACKUP_SCRIPT"; then
    echo -e "${GREEN}✓${NC} Backup script test passed!"
else
    echo -e "${YELLOW}⚠️  Backup script test failed. Check logs at: $HOME/backups-medzen/backup.log${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "Schedule:     ${GREEN}$DESCRIPTION${NC}"
echo -e "Script:       ${GREEN}$BACKUP_SCRIPT${NC}"
echo -e "Backup Dir:   ${GREEN}$HOME/backups-medzen/${NC}"
echo -e "Log File:     ${GREEN}$HOME/backups-medzen/backup.log${NC}"
echo -e "Keep Days:    ${GREEN}30 days${NC}"
echo ""
echo "To view backup log:"
echo "  tail -f $HOME/backups-medzen/backup.log"
echo ""
echo "To list backups:"
echo "  ls -lh $HOME/backups-medzen"
echo ""
echo "To remove automated backups:"
echo "  crontab -e  (then delete the backup line)"
echo ""
