#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_functions.sh                                                 #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

# Function to check for root permissions
check_root() {
    if [[ $(id -u) != 0 ]]; then
        echo "This script must be run with root privileges."
        exit 1
    fi
}

# Function to check available disk space
check_disk_space() {
    local required_space=$(du -sb "$HOME_DIR" $LINUX_DIRS | awk '{total += $1} END {print total}')
    local available_space=$(df -B 1 "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    if [ "$required_space" -gt "$available_space" ]; then
        echo "Error: Not enough disk space available for backup."
        exit 1
    fi
}

# Function to upload backup files to a remote server or the cloud
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
