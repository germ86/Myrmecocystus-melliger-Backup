#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_user_group_permissions.sh                                    #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

GERM_USER="germ86"
FABIO_USER="fabio"
STEFFI_USER="steffi"

get_backup_parameters_interactive() {
    read -p "Please enter the source directory: " source_dir
    read -p "Please enter the target directory: " target_dir
    read -p "Please enter the file name for the backup: " backup_file_name
    read -p "Please enter the user name: " user_name
    read -p "Please enter the group name: " group_name
}

function set_permissions() {
    local DIR="$1"
    local USER="$2"
    local GROUP="$3"
    local PERMISSIONS="$4"

    echo "Setting permissions for $DIR"
    sudo chown -R "$USER:$GROUP" "$DIR"
    sudo chmod -R "$PERMISSIONS" "$DIR"
}

function backup_user_group_permissions() {
    echo "Sichern von Benutzer- und Gruppenberechtigungen ..."
    sudo mkdir -p /var/backup/permissions

    # Backup permissions for each user
    for user in $GERM_USER $FABIO_USER $STEFFI_USER; do
        echo "Sichern von Berechtigungen für $user"
        sudo getent group $user | cut -d: -f3 > "/var/backup/permissions/$user.groups"
        sudo getent passwd $user | cut -d: -f4 > "/var/backup/permissions/$user.gids"
    done

    # Backup group memberships for each user
    for user in $GERM_USER $FABIO_USER $STEFFI_USER; do
        echo "Sichern von Gruppenmitgliedschaften für $user"
        sudo groups $user > "/var/backup/permissions/$user.memberships"
    done

    echo "Benutzer- und Gruppenberechtigungen gesichert!"
}


backup_permissions() {
    local path=$1
    local backup_dir=$2
    local backup_file=$(basename $path).$(date +%Y-%m-%d).bak
    cp -a $path $backup_dir/$backup_file
}

backup_group_permissions() {
    local group=$1
    local backup_dir=$2
    local backup_file=${group}_permissions.$(date +%Y-%m-%d).bak
    find / -group $group -printf "%p\n" | while read path; do
        backup_permissions $path $backup_dir/$backup_file
    done
}

function create_backup_directory() {
    local BACKUP_DIR="/var/backup/permissions"

    if [ ! -d "$BACKUP_DIR" ]; then
        echo "Erstelle Backup-Verzeichnis: $BACKUP_DIR"
        sudo mkdir -p "$BACKUP_DIR"
    fi
}

function move_folders() {
    # Find all folders named "Billeder", "Dokumenter", "Hentede filer", "Musik", "Offentlig", and "Videoer"
    # under /home/fabio and move them to the corresponding German folder name under /home/germ86
    for folder in $(find /home/$FABIO_USER -type d \( -name "Billeder" -o -name "Dokumenter" -o -name "Hentede filer" -o -name "Musik" -o -name "Offentlig" -o -name "Videoer" \)); do
        case "$folder" in
            */Billeder/*) target="/home/$GERM_USER/Bilder/$(basename "$folder")" ;;
            */Dokumenter/*) target="/home/$GERM_USER/Dokumente/$(basename "$folder")" ;;
            */Hentede\ filer/*) target="/home/$GERM_USER/Downloads/$(basename "$folder")" ;;
            */Musik/*) target="/home/$GERM_USER/Musik/$(basename "$folder")" ;;
            */Offentlig/*) target="/home/$GERM_USER/Öffentlich/$(basename "$folder")" ;;
            */Videoer/*) target="/home/$GERM_USER/Videos/$(basename "$folder")" ;;
            *) echo "Ignoring folder $folder" ; continue ;;
        esac

        echo "Moving $folder to $target"
        sudo mv "$folder" "$target"
        set_permissions "$target" "$GERM_USER" "$GERM_USER" "755"
    done
}

function rename_folders() {
    # Rename all folders named "Fotos" to "Bilder" under /home/germ86
    for folder in $(find /home/$GERM_USER -type d -name "Fotos"); do
        target="$(dirname "$folder")/Bilder/$(basename "$folder")"
        echo "Renaming $folder to $target"
        sudo mv "$folder" "$target"
        set_permissions "$target" "$GERM_USER" "$GERM_USER" "755"
    done
}

move_folders
rename_folders
backup_user_group_permissions