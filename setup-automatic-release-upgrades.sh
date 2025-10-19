#!/bin/bash

###############################################################################
# Setup Automatic Release Upgrades for Ubuntu
# This script automates the configuration of automatic Ubuntu release upgrades
###############################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/setup-automatic-release-upgrades.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE" > /dev/null
    echo -e "$1"
}

# Function to check if script is run as root or with sudo
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run with sudo or as root${NC}"
        echo "Usage: sudo $0"
        exit 1
    fi
}

# Function to backup a file
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_message "${GREEN}✓${NC} Backed up $file"
    fi
}

# Function to configure release-upgrades
configure_release_upgrades() {
    log_message "${YELLOW}Step 1: Configuring /etc/update-manager/release-upgrades${NC}"
    
    local config_file="/etc/update-manager/release-upgrades"
    
    # Create directory if it doesn't exist
    if [ ! -d "/etc/update-manager" ]; then
        mkdir -p /etc/update-manager
        log_message "${GREEN}✓${NC} Created /etc/update-manager directory"
    fi
    
    # Backup existing file
    backup_file "$config_file"
    
    # Check if file exists and modify it, or create new one
    if [ -f "$config_file" ]; then
        # Replace or add Prompt=normal
        if grep -q "^Prompt=" "$config_file"; then
            sed -i 's/^Prompt=.*/Prompt=normal/' "$config_file"
            log_message "${GREEN}✓${NC} Updated Prompt=normal in $config_file"
        else
            echo "Prompt=normal" >> "$config_file"
            log_message "${GREEN}✓${NC} Added Prompt=normal to $config_file"
        fi
    else
        # Create new file with default content
        cat > "$config_file" << EOF
# Default behavior for the release upgrader.

[DEFAULT]
# Default prompting and upgrade behavior, valid options:
#
#  never  - Never check for, or allow upgrading to, a new release.
#  normal - Check to see if a new release is available.  If more than one new
#           release is found, the release upgrader will attempt to upgrade to
#           the supported release that immediately succeeds the
#           currently-running release.
#  lts    - Check to see if a new LTS release is available.  The upgrader
#           will attempt to upgrade to the first LTS release available after
#           the currently-running one.  Note that if this option is used and
#           the currently-running release is not itself an LTS release the
#           upgrader will assume prompt was meant to be normal.
Prompt=normal
EOF
        log_message "${GREEN}✓${NC} Created $config_file with Prompt=normal"
    fi
}

# Function to install required packages
install_packages() {
    log_message "${YELLOW}Step 2: Installing required packages${NC}"
    
    # Update package list
    log_message "Updating package list..."
    apt-get update -qq
    
    # Install unattended-upgrades and update-notifier-common
    log_message "Installing unattended-upgrades and update-notifier-common..."
    if DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades update-notifier-common; then
        log_message "${GREEN}✓${NC} Installed unattended-upgrades and update-notifier-common"
    else
        log_message "${RED}✗${NC} Failed to install unattended-upgrades and update-notifier-common"
        return 1
    fi
    
    # Install update-manager-core
    log_message "Installing update-manager-core..."
    if DEBIAN_FRONTEND=noninteractive apt-get install -y update-manager-core; then
        log_message "${GREEN}✓${NC} Installed update-manager-core"
    else
        log_message "${RED}✗${NC} Failed to install update-manager-core"
        return 1
    fi
}

# Function to configure unattended-upgrades
configure_unattended_upgrades() {
    log_message "${YELLOW}Step 3: Configuring unattended-upgrades${NC}"
    
    # Reconfigure unattended-upgrades
    if DEBIAN_FRONTEND=noninteractive dpkg-reconfigure --priority=low unattended-upgrades; then
        log_message "${GREEN}✓${NC} Configured unattended-upgrades"
    else
        log_message "${RED}✗${NC} Failed to configure unattended-upgrades"
        return 1
    fi
}

# Function to setup cron job
setup_cron_job() {
    log_message "${YELLOW}Step 4: Setting up cron job for automatic release upgrades${NC}"
    
    local cron_entry="0 5 * * 0 /usr/bin/do-release-upgrade -f DistUpgradeViewNonInteractive"
    
    # Check if cron entry already exists
    if crontab -l 2>/dev/null | grep -q "do-release-upgrade"; then
        log_message "${YELLOW}⚠${NC} Cron job for do-release-upgrade already exists"
    else
        # Add cron job (runs every Sunday at 5:00 AM)
        if (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -; then
            log_message "${GREEN}✓${NC} Added cron job: $cron_entry"
            log_message "    Runs every Sunday at 5:00 AM"
        else
            log_message "${RED}✗${NC} Failed to add cron job"
            return 1
        fi
    fi
}

# Main function
main() {
    log_message "=================================================="
    log_message "Starting Automatic Release Upgrades Setup"
    log_message "=================================================="
    
    # Check if running as root
    check_root
    
    # Execute setup steps
    configure_release_upgrades || exit 1
    install_packages || exit 1
    configure_unattended_upgrades || exit 1
    setup_cron_job || exit 1
    
    log_message ""
    log_message "${GREEN}=================================================="
    log_message "Setup completed successfully!"
    log_message "==================================================${NC}"
    log_message ""
    log_message "Summary:"
    log_message "  - Release upgrade prompt: normal"
    log_message "  - Unattended upgrades: enabled"
    log_message "  - Automatic release upgrade cron: Sundays at 5:00 AM"
    log_message ""
    log_message "You can manually trigger a release upgrade with:"
    log_message "  sudo do-release-upgrade"
    log_message ""
    log_message "Log file: $LOG_FILE"
}

# Run main function
main
