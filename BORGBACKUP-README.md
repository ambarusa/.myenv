# Borg Backup Script - Generic Configuration Guide

## Overview
The refactored `borgbackup.sh` script is now generic and reusable across multiple devices. Configuration is handled via `.conf` files instead of hardcoding values in the script.

## Quick Start

1. **Copy the template** to create your configuration:
   ```bash
   cp borgbackup.conf.template mydevice.conf
   ```

2. **Edit the configuration** file with your settings:
   ```bash
   nano mydevice.conf
   ```

3. **Run the backup** with your configuration:
   ```bash
   ./borgbackup.sh mydevice.conf
   ```

4. **Test with dry-run** before running the actual backup:
   ```bash
   ./borgbackup.sh --dry-run mydevice.conf
   ```

## Configuration File Structure

See `borgbackup.conf.template` for a fully commented template. Here's the minimal required setup:

```bash
#!/bin/bash

# Required: Borg repository path
BORG_REPO="/mnt/backup-storage"

# Required: Paths to backup (array format)
BACKUP_PATHS=(
    "/home/username/.config"
    "/home/username/documents"
)

# Required: Retention policy
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12

# Optional: Docker containers to stop before backup (only if needed)
DOCKER_STOP_CONTAINERS=("mariadb" "postgres")
```

## Features

### Basic Usage
```bash
./borgbackup.sh mydevice.conf              # Run backup
./borgbackup.sh --dry-run mydevice.conf    # Test without making changes
```

### Dry-Run Mode
The `--dry-run` flag is useful for testing your configuration:
- Shows all files and folders that would be backed up (via `borg --dry-run`)
- Lists Docker containers that would be stopped/restarted
- Does not create actual backups or prune old archives
- Perfect for validating paths and retention policies before production use

### Multi-Device Setup
Create separate `.conf` files for each device:
- `prod-server.conf` - for production server
- `backup-server.conf` - for backup server
- `workstation.conf` - for personal workstation

### Docker Integration
- Define `DOCKER_STOP_CONTAINERS` with a list of container names to stop before backup
- Useful for databases (MariaDB, PostgreSQL, MongoDB) to ensure safe shutdown and flush operations
- Leave empty or omit to skip Docker management and treat folders as regular data

### Retention Policies
Define how many backups to keep:
- `KEEP_DAILY=7` - Keep 7 daily backups
- `KEEP_WEEKLY=4` - Keep 4 weekly backups
- `KEEP_MONTHLY=12` - Keep 12 monthly backups
- Set to `0` to disable that period

### Backup Paths
Define multiple directories to backup:
```bash
BACKUP_PATHS=(
    "/home/adam/.docker"
    "/home/adam/.config"
    "/etc/myapp"
    "/var/www"
)
```

## Advanced Configuration

The script sources your `.conf` file, so you can set any Borg environment variables:

```bash
# Set Borg passphrase
export BORG_PASSPHRASE="your-secure-passphrase"

# SSH key for remote repositories
export BORG_RSH='ssh -i /home/user/.ssh/backup_key'

# Custom Borg options
BORG_ARGS="--compression lz4 --exclude-from=/home/user/.borgignore"
```

## Validation

The script automatically validates required variables:
- `BORG_REPO` - Repository location
- `BACKUP_PATHS` - Paths array
- `KEEP_DAILY`, `KEEP_WEEKLY`, `KEEP_MONTHLY` - Retention values

If any are missing, the script will exit with an error.

## Scheduling

Use cron to schedule regular backups. For example, to backup daily at 2 AM:

```bash
0 2 * * * /path/to/borgbackup.sh /path/to/configs/mydevice.conf >> /var/log/borgbackup.log 2>&1
```

## File Structure

```
borgbackup.sh                    # Main script (generic)
borgbackup.conf.template         # Template with all options documented
borgbackup.conf.example          # Simple example config
BORGBACKUP-README.md             # This guide
```

## Examples

### Example 1: Backup database volumes with safe shutdown
```bash
BORG_REPO="/mnt/backups"
BACKUP_PATHS=(
    "/var/lib/docker/volumes/mariadb_data/_data"
)
DOCKER_STOP_CONTAINERS=("mariadb")
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12
```

### Example 2: Backup multiple databases
```bash
BORG_REPO="/mnt/backups"
BACKUP_PATHS=(
    "/var/lib/docker/volumes/postgres_data/_data"
    "/var/lib/docker/volumes/mongo_data/_data"
)
DOCKER_STOP_CONTAINERS=("postgres" "mongodb")
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12
```

### Example 3: Backup entire home directory (no Docker)
```bash
BORG_REPO="/mnt/backups"
BACKUP_PATHS=(
    "/home/username"
)
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12
```

### Example 4: Mixed setup with selective container management
```bash
BORG_REPO="/mnt/backups"
BACKUP_PATHS=(
    "/home/username/.docker"
    "/home/username/projects"
    "/etc/configs"
)
DOCKER_STOP_CONTAINERS=("mariadb")
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12
```

## Troubleshooting

- **Config file not found**: Check the file path is correct
- **Required variable not set**: Verify all required variables are in your `.conf` file
- **Permission denied**: Ensure the script is executable: `chmod +x borgbackup.sh`
- **Container not found warning**: The container name in `DOCKER_STOP_CONTAINERS` may not be running or may have a different name. Check with `docker ps`
- **Backup fails after stopping containers**: Ensure containers are properly stopped and your backup paths are accessible

## Tips

1. Create a `configs/` directory to organize multiple device configurations
2. Use descriptive names: `backup-prod.conf`, `backup-home.conf`, etc.
3. Test with a small backup first before scheduling production backups
4. Keep backups in multiple locations for redundancy
5. Regularly test restores to ensure backups are working
