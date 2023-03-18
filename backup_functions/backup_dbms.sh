#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_functions/backup_dbms.sh                                     #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Funktionen auslagern
source backup_functions/backup_dbms.sh
source backup_functions/backup_remote.sh

# Menüfunktion
menu() {
    clear
    echo "Welche Option möchten Sie auswählen?"
    echo "1) Backup erstellen"
    echo "2) Konfiguration ändern"
    echo "3) Beenden"
    read -p "Auswahl: " choice

    case "$choice" in
        1 )
            clear
            echo "Welchen Typ von Backup möchten Sie erstellen?"
            echo "1) DBMS-Backup"
            echo "2) Remote-Dateien-Backup"
            read -p "Auswahl: " backup_choice
            
            case "$backup_choice" in
                1 )
                    backup_dbms
                    ;;
                2 )
                    backup_remote
                    ;;
                * )
                    echo "Ungültige Eingabe!"
                    ;;
            esac
            ;;
        2 )
            configure
            ;;
        3 )
            exit 0
            ;;
        * )
            echo "Ungültige Eingabe!"
            ;;
    esac
}
