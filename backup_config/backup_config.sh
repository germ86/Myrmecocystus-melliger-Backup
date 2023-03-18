#!/bin/bash

#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: .configs/backup_config.sh                                           #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

set -euo pipefail

# Include functions
source "$(dirname "$0")/.configs/backup_utils.sh"

usage() {
  echo "Usage: $0 [-h] [-c] [-d]"
  echo "Configure and run backup script"
  echo ""
  echo "Options:"
  echo "  -h    Show help message"
  echo "  -c    Configure backup settings"
  echo "  -d    Run backup script with existing settings"
}

configure_backup() {
  echo "Welcome to the backup configuration."
  echo "Please enter the following information:"

  # Source directory
  read -p "Source directory: " source_dir

  # Target directory
  read -p "Target directory: " target_dir

  # Backup file name
  read -p "Backup file name: " backup_file_name

  # Username for backup file permissions
  read -p "Username for permissions: " user_name

  # Group name for backup file permissions
  read -p "Group name for permissions: " group_name

  # Write configuration to file
  echo "source_dir=$source_dir" > "$(dirname "$0")/.configs/backup.conf"
  echo "target_dir=$target_dir" >> "$(dirname "$0")/.configs/backup.conf"
  echo "backup_file_name=$backup_file_name" >> "$(dirname "$0")/.configs/backup.conf"
  echo "user_name=$user_name" >> "$(dirname "$0")/.configs/backup.conf"
  echo "group_name=$group_name" >> "$(dirname "$0")/.configs/backup.conf"

  echo "Backup configuration completed."
}

run_backup() {
  # Check if configuration file exists
  if [ ! -f "$(dirname "$0")/.configs/backup.conf" ]; then
    echo "Configuration file does not exist. Please run with -c option to configure."
    exit 1
  fi

  # Load configuration
  source "$(dirname "$0")/.configs/backup.conf"

  # Run backup
  backup_files "$source_dir" "$target_dir" "$backup_file_name" "$user_name" "$group_name"
}

# Parse options
while getopts "hcd" opt; do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    c)
      configure_backup
      exit 0
      ;;
    d)
      run_backup
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

# Default behavior: show usage
usage