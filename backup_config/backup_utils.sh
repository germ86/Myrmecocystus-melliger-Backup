#!/bin/bash

# Zentrale Konfigurationsdatei
source /etc/backup/backup.conf

# Funktion zur Überprüfung der verfügbaren Speicherkapazität
check_disk_space() {
    local required_space=$(du -sb "$HOME_DIR" $LINUX_DIRS | awk '{total += $1} END {print total}')
    local available_space=$(df -B 1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    if [ "$required_space" -gt "$available_space" ]; then
        echo "Error: Not enough disk space available for backup."
        exit 1
    fi
}

# Funktion zum Hochladen von Backup-Dateien auf einen entfernten Server oder in die Cloud
upload_backup() {
    local backup_file="$1"
    local remote_server="$2"
    scp "$backup_file" "$remote_server:$REMOTE_DIR"
}