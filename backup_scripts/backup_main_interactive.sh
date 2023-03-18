#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_main_interactive.sh                                                      #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Laden der Konfiguration
source .configs/backup.conf

# Funktion zum Anzeigen der Anweisungen
usage() {
  echo "Usage: backup_main_interactive.sh [-h | --help]"
}

# Funktion zum Anzeigen des Konfigurationsmenüs
backup_menu() {
  echo "Backup-Konfiguration:"
  echo "1. Logging-Konfiguration"
  echo "2. Backup-Parameter"
  echo "3. Exit"
}

# Funktion zum Ausführen der Logging-Konfiguration
configure_logging() {
  # Logging-Level auswählen
  read -p "Logging-Level (DEBUG, INFO, WARNING, ERROR): " log_level

  # Logging-Konfiguration speichern
  echo "log_level=$log_level" > .configs/logging.conf

  echo "Logging-Konfiguration abgeschlossen."
}

# Funktion zum Ausführen der Backup-Konfiguration
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
  echo "SRC_DIR=$source_dir" > .configs/backup.conf
  echo "DEST_DIR=$target_dir" >> .configs/backup.conf
  echo "BACKUP_FILE_NAME=$backup_file_name" >> .configs/backup.conf
  echo "USER_NAME=$user_name" >> .configs/backup.conf
  echo "GROUP_NAME=$group_name" >> .configs/backup.conf

  echo "Backup-Konfiguration abgeschlossen."
}


# Funktion zum Ausführen der Sortierung
sort_backup() {
  # Laden der Konfiguration
  source .configs/backup.conf

  # Array mit Sortieroptionen
  options=("nur nach Datum" "nach Datum und Größe" "nach Datum und Typ" "mehrere Nutzer-Ordner zusammenlegen")
  select option in "${options[@]}"
  do
    case $option in
      "nur nach Datum")
        sort_command="ls -lt $DEST_DIR"
        break
        ;;
      "nach Datum und Größe")
        sort_command="ls -lrt $DEST_DIR"
        break
        ;;
      "nach Datum und Typ")
        sort_command="ls -lat $DEST_DIR"
        break
        ;;
      "mehrere Nutzer-Ordner zusammenlegen")
        read -p "Nutzername eingeben: " username
        # Zusammenlegen der Ordner des angegebenen Nutzers
        sort_command="find $DEST_DIR -type d -name \"$username*\" -exec tar -cvzf \"$DEST_DIR/$username.tar.gz\" {} +"
        break
# Funktion zum Ausführen der Sortierung
sort_backup() {
  # Laden der Konfiguration
  source .configs/backup.conf

  # Array mit Sortieroptionen
  options=("nur nach Datum" "nach Datum und Größe" "nach Datum und Typ" "mehrere Nutzer-Ordner zusammenlegen")
  select option in "${options[@]}"
  do
    case $option in
      "nur nach Datum")
        sort_command="ls -lt $DEST_DIR"
        break
        ;;
      "nach Datum und Größe")
        sort_command="ls -lrt $DEST_DIR"
        break
        ;;
      "nach Datum und Typ")
        sort_command="ls -lat $DEST_DIR"
        break
        ;;
      "mehrere Nutzer-Ordner zusammenlegen")
        read -p "Nutzername eingeben: " username
        # Zusammenlegen der Ordner des angegebenen Nutzers
        sort_command="find $DEST_DIR -type d -name \"$username*\" -exec tar -cvzf \"$DEST_DIR/$username.tar.gz\" {} +"
        break
        ;;
      *) echo "Ungültige Auswahl, bitte erneut eingeben.";;
    esac
  done

  # Ausgabe des Sortierungsbefehls
  echo "Sortierungsbefehl: $sort_command"

  # Ausführen des Sortierungsbefehls
  eval $sort_command
}
