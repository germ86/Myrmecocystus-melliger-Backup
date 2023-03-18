#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_differential.sh                                                      #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Load configuration from central configuration file
source /etc/backup.conf

# Load backup functions
source ./lib/backup_functions.sh

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



...

# Log backup filename
log "Backup created: $backup_file"

...

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

log "

