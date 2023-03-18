#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: .configs/backup_config_setup.sh                                     #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################


set -euo pipefail

# Include functions
source .configs/backup_utils.sh

configure_backup() {
  echo "Willkommen zur Backup-Konfiguration."
  echo "Bitte geben Sie die folgenden Informationen ein:"

  # Quellverzeichnis
  read -p "Quellverzeichnis: " source_dir

  # Zielverzeichnis
  read -p "Zielverzeichnis: " target_dir

  # Backup-Dateiname
  read -p "Backup-Dateiname: " backup_file_name

  # Benutzername für die Benutzer- und Gruppenberechtigungen des Backups
  read -p "Benutzername für Berechtigungen: " user_name

  # Gruppenname für die Benutzer- und Gruppenberechtigungen des Backups
  read -p "Gruppenname für Berechtigungen: " group_name

  # Schreibweisen der Konfiguration in die Datei
  echo "source_dir=$source_dir" > .configs/backup.conf
  echo "target_dir=$target_dir" >> .configs/backup.conf
  echo "backup_file_name=$backup_file_name" >> .configs/backup.conf
  echo "user_name=$user_name" >> .configs/backup.conf
  echo "group_name=$group_name" >> .configs/backup.conf

  echo "Backup-Konfiguration abgeschlossen."
}

# Führe die Konfiguration nur aus, wenn die Konfigurationsdatei nicht existiert
if [ ! -f .configs/backup.conf ]; then
  configure_backup
else
  echo "Eine Konfigurationsdatei existiert bereits. Überspringe die Konfiguration."
fi


# Führe die Konfiguration nur aus, wenn die Konfigurationsdatei nicht existiert
if [ ! -f .configs/backup.conf ]; then
  configure_backup
else
  echo "Eine Konfigurationsdatei existiert bereits. Überspringe die Konfiguration."
fi
