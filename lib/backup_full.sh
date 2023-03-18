#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_full.sh                                                      #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

# Load configuration from central configuration file
source /etc/backup/backup.conf

# Load backup functions
source ./lib/backup_functions.sh

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -d|--directory)
    BACKUP_DIR="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--remote-server)
    REMOTE_SERVER="$2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Usage: backup_full.sh [OPTIONS]"
    echo "  -d, --directory DIR     Set the backup directory (default: $BACKUP_DIR)"
    echo "  -r, --remote-server URL Set the remote backup server (optional)"
    echo "  -h, --help              Show this help message"
    exit 0
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    exit 1
    ;;
esac
done

# Interactive menu
if [ -z "$BACKUP_DIR" ]; then
    read -p "Enter the backup directory path (default: /backup): " BACKUP_DIR
    BACKUP_DIR=${BACKUP_DIR:-/backup}
fi

if [ -z "$REMOTE_SERVER" ]; then
    read -p "Enter the remote backup server URL (optional): " REMOTE_SERVER
fi

# Main script
echo "Starting full backup process..."

# Check for root permissions
check_root

# Check disk space
check_disk_space

# Create backup archive
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
backup_file="${BACKUP_DIR}/backup_full_${timestamp}.tar.gz"
tar -czvf "$backup_file" "$HOME_DIR" $LINUX_DIRS

# Log backup filename
log "Backup created: $backup_file"

# Perform local backup
if [ -z "$REMOTE_SERVER" ]; then
    perform_local_backup "$backup_file" "$BACKUP_DIR"
# Perform remote backup
else
    perform_remote_backup "$backup_file" "$REMOTE_SERVER"
fi

# Exit successfully
exit 0

