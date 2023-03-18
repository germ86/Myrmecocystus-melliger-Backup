#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_sort_dynamic.sh                                              #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Array mit Dateiformaten und zugehörigen Zielordnern einlesen
source backup_sort.conf

# Funktion zur Überprüfung von Root-Rechten
check_root() {
    if [[ $(id -u) != 0 ]]; then
        echo "Dieses Skript muss mit Root-Rechten ausgeführt werden."
        exit 1
    fi
}

# Überprüfen der Root-Rechte
check_root

# Funktion zur Sortierung der Dateien
sortieren() {
    for i in "$1"/*; do
        if [[ -d "$i" ]]; then
            sortieren "$i"
        elif [[ -f "$i" ]]; then
            # Dateiformat ermitteln
            extension="${i##*.}"
            # Zielordner ermitteln
            zielordner=""
            for format in "${file_formats[@]}"; do
                if [[ $format == *"$extension"* ]]; then
                    zielordner="${format#*:}"
                    break
                fi
            done
            if [[ -z "$zielordner" ]]; then
                # Dateiformat nicht bekannt, überspringen
                continue
            fi
            # Zielordner erstellen, falls nicht vorhanden
            mkdir -p "/home/$zieluser/$zielordner"
            # Duplikate finden und entfernen
            if [[ -f "/home/$zieluser/$zielordner/$(basename $i)" ]]; then
                if [[ $(stat -c%s "$i") -eq $(stat -c%s "/home/$zieluser/$zielordner/$(basename $i)") ]]; then
                    echo "Lösche Duplikat: $i"
                    rm "$i"
                fi
            else
                echo "Verschiebe $i nach /home/$zieluser/$zielordner"
                mv "$i" "/home/$zieluser/$zielordner"
            fi
        fi
    done
}

# Funktion zum Aufruf der Sortierfunktion für jeden User
sortieren_fuer_user() {
    if [[ -d "/home/$1" ]]; then
        zieluser="$1"
        sortieren "/home/$1"
    fi
}

# Sortieren für jeden User aufrufen
sortieren_fuer_user "germ86"
sortieren_fuer_user "fabio"
sortieren_fuer_user "steffi"
sortieren_fuer_user "johndoe"
sortieren_fuer_user "janedoe"
