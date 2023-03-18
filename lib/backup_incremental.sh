#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_incremental.sh                                               #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Funktion zur Überprüfung von Root-Rechten
check_root() {
    if [[ $(id -u) != 0 ]]; then
        echo "Dieses Skript muss mit Root-Rechten ausgeführt werden."
        exit 1
    fi
}

# Überprüfen der Root-Rechte
check_root

# Load configuration from central configuration file
source /etc/backup.conf

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

# Function to create a differential backup
create_differential_backup() {
  local src_dir="$1"
  local dest_dir="$2"
  local encrypted="$3"
  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local backup_name="backup_differential_${timestamp}.tar.gz"

  # If encryption is enabled, add ".enc" to the backup file name
  if [ "$encrypted" = true ]; then
    backup_name="${backup_name}.enc"
  fi

  # Use rsync to create a differential backup
  rsync -a --link-dest="$dest_dir/latest_full_backup" --exclude-from="$EXCLUDE_FILE" "$src_dir" "$dest_dir/$backup_name"

  # If encryption is enabled, encrypt the backup with GPG
  if [ "$encrypted" = true ]; then
    gpg --yes --batch --passphrase="$GPG_PASSPHRASE" --cipher-algo AES256 --symmetric "$dest_dir/$backup_name"
    rm "$dest_dir/$backup_name"
  fi

  # Check the integrity of the backup
  if [ "$CHECK_INTEGRITY" = true ]; then
    echo "Verifying backup integrity..."
    tar -tzf "$dest_dir/$backup_name" >/dev/null
    if [ "$?" = "0" ]; then
      echo "Backup integrity verified."
    else
      echo "Error: Backup integrity check failed."
      exit 1
    fi
  fi

  log "Created differential backup of $src_dir to $dest_dir/$backup_name"
}

# Main script
echo "Starting differential backup process..."

# Check if there is a latest_full_backup, if not exit
if [ ! -d "$BACKUP_DIR/latest_full_backup" ]; then
  echo "Error: latest_full_backup not found."
  exit 1
fi

# Create the differential backup
create_differential_backup "$SRC_DIR" "$BACKUP_DIR" "$ENCRYPT_BACKUP"

echo "Differential backup process completed."