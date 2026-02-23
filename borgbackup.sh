#!/bin/bash
set -euo pipefail

########################
# CONFIGURATION BLOCK #
########################

# Parse command line arguments
DRY_RUN=false
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            if [ -z "$CONFIG_FILE" ]; then
                CONFIG_FILE="$1"
            fi
            shift
            ;;
    esac
done

# Check if config file was provided
if [ -z "$CONFIG_FILE" ]; then
    echo "Usage: $0 [--dry-run] <config-file>"
    echo "Example: $0 /etc/borgbackup/mydevice.conf"
    echo "Example: $0 --dry-run /etc/borgbackup/mydevice.conf"
    exit 1
fi

# Verify config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[ERROR] Config file not found: $CONFIG_FILE"
    exit 1
fi

# Source the configuration file
source "$CONFIG_FILE"

# Validate required variables
for var in BORG_REPO BACKUP_PATHS KEEP_DAILY KEEP_WEEKLY KEEP_MONTHLY; do
    if [ -z "${!var:-}" ]; then
        echo "[ERROR] Required variable '$var' not set in config file"
        exit 1
    fi
done

# Initialize container array if not set
DOCKER_STOP_CONTAINERS=("${DOCKER_STOP_CONTAINERS[@]:-}")

# Temp file to store containers (unique per invocation)
STATE_FILE="/tmp/borg-running-containers-$(date +%s).txt"

########################
# END CONFIG SECTION #
########################

export BORG_REPO
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

echo "== Starting Borg backup at $timestamp =="
if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN MODE] No changes will be made"
fi
echo "[INFO] Using config: $CONFIG_FILE"
echo "[INFO] Backup repository: $BORG_REPO"

# Stop specific Docker containers (if list is defined)
if [ ${#DOCKER_STOP_CONTAINERS[@]} -gt 0 ]; then
    echo "[INFO] Docker containers to stop: ${DOCKER_STOP_CONTAINERS[*]}"
    
    for container in "${DOCKER_STOP_CONTAINERS[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "[ACTION] Stopping container: $container"
            if [ "$DRY_RUN" = "false" ]; then
                docker stop "$container" >/dev/null 2>&1
            fi
            echo "$container" >> "$STATE_FILE"
        else
            echo "[WARNING] Container '$container' is not running"
        fi
    done
else
    echo "[INFO] No Docker containers to stop. Proceeding with backup."
fi

# Run backup
echo "[INFO] Starting backup..."
BORG_OPTS="--compression lz4 --stats"
if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] Running borg with --dry-run to show what would be backed up..."
    BORG_OPTS="--dry-run $BORG_OPTS"
fi

borg create \
    $BORG_OPTS \
    "$BORG_REPO::borgbackup-$timestamp" \
    ${BACKUP_PATHS[@]}

echo "== Backup completed =="

# Apply retention (skip during dry-run since no actual backup was created)
if [ "$DRY_RUN" = "false" ]; then
    echo "== Pruning old backups =="
    borg prune \
        --keep-daily="$KEEP_DAILY" \
        --keep-weekly="$KEEP_WEEKLY" \
        --keep-monthly="$KEEP_MONTHLY" \
        "$BORG_REPO"
else
    echo "[DRY-RUN] Skipping prune step (no actual backup was created)"
fi

# Restore stopped Docker containers
if [ -s "$STATE_FILE" ]; then
    echo "[INFO] Restarting containers..."
    while read -r container; do
        if [ -n "$container" ]; then
            echo "[ACTION] Starting container: $container"
            if [ "$DRY_RUN" = "false" ]; then
                docker start "$container" >/dev/null 2>&1
            fi
        fi
    done < "$STATE_FILE"
fi

rm -f "$STATE_FILE"
echo "== Borg backup task finished =="
echo "Next backup scheduled in 24 hours."
