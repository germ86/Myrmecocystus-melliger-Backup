#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_menu.sh                                                      #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

# Define menu options
options=("Logging configuration" "Backup parameters" "Exit")

# Define function to print menu
print_menu() {
    echo "Please choose an option:"
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[$i]}"
    done
}

# Define function to handle menu choices
handle_choice() {
    case "$1" in
        1) echo "You chose 'Logging configuration'";;
        2) echo "You chose 'Backup parameters'";;
        3) echo "Goodbye!"; exit 0;;
        *) echo "Invalid choice. Please try again.";;
    esac
}

# Display menu and handle choices
while true; do
    print_menu
    read -p "Enter your choice: " choice
    handle_choice "$choice"
    echo ""
done
