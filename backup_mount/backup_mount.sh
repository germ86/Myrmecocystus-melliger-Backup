#!/bin/bash




##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_mount/backup_mount.sh                                        #
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

# Funktion zum Erstellen des Backup-Mount-Punkts
create_backup_mount_point() {
    if [ ! -d "${BACKUP_MOUNT_POINT}" ]; then
        echo "Creating backup mount point at ${BACKUP_MOUNT_POINT}..."
        sudo mkdir "${BACKUP_MOUNT_POINT}"
    fi
}

# Funktion zum Überprüfen und Mounten der externen Festplatte
check_and_mount_external_disk() {
    # Überprüfen der Root-Rechte
    check_root

    # Überprüfen, ob die externe Festplatte bereits gemountet ist
    if grep -qs "${EXTERNAL_DISK_MOUNT_POINT}" /proc/mounts; then
        echo "External disk already mounted at ${EXTERNAL_DISK_MOUNT_POINT}"
    else
        # Die externe Festplatte ist nicht gemountet, also mounten
        echo "External disk not mounted, attempting to mount..."
        sudo mount "${EXTERNAL_DISK_PATH}" "${EXTERNAL_DISK_MOUNT_POINT}"
        if [ $? -eq 0 ]; then
            echo "External disk mounted successfully at ${EXTERNAL_DISK_MOUNT_POINT}"
        else
            echo "Failed to mount external disk at ${EXTERNAL_DISK_MOUNT_POINT}"
            exit 1
        fi
    fi

    # Mounten der externen Festplatte am Backup-Mount-Punkt
    echo "Mounting external disk at backup mount point ${BACKUP_MOUNT_POINT}..."
    sudo mount --bind "${EXTERNAL_DISK_MOUNT_POINT}" "${BACKUP_MOUNT_POINT}"
    if [ $? -eq 0 ]; then
        echo "External disk mounted at backup mount point successfully"
    else
        echo "Failed to mount external disk at backup mount point"
        exit 1
    fi
}

# Überprüfen und Mounten der externen Festplatte
check_and_mount_external_disk

# Erstellen des Backup-Mount-Punkts
create_backup_mount_point
