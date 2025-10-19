# ubuntu-automation
personal repository to store custom scripts i use for ubuntu

## Scripts

### setup-automatic-release-upgrades.sh

Automates the configuration of automatic Ubuntu release upgrades in a quick and easy way.

**What it does:**
- Configures `/etc/update-manager/release-upgrades` to set `Prompt=normal`
- Installs required packages: `unattended-upgrades`, `update-notifier-common`, `update-manager-core`
- Configures unattended-upgrades via `dpkg-reconfigure`
- Sets up a cron job to run `do-release-upgrade` every Sunday at 5:00 AM

**Usage:**
```bash
sudo ./setup-automatic-release-upgrades.sh
```

**Features:**
- Automatic backups of configuration files
- Colored output for easy reading
- Logging to `/var/log/setup-automatic-release-upgrades.log`
- Error handling and validation
- Idempotent (safe to run multiple times)
