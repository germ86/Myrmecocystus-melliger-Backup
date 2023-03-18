#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_db_connect.sh                                                #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

if [ ! -f ~/.my.cnf ]; then
    echo "Bitte geben Sie die Informationen zur Datenbankverbindung ein:"
    read -p "Datenbank-Hostname: " db_host
    read -p "Datenbank-Benutzername: " db_user
    read -s -p "Datenbank-Passwort: " db_pass
    echo ""
    read -p "Datenbank-Name: " db_name
    read -p "Datenbank-Port (standardmäßig 3306): " db_port

    if [ -z "$db_port" ]; then
        db_port=3306
    fi

    echo "[client]" > ~/.my.cnf
    echo "host=\"$db_host\"" >> ~/.my.cnf
    echo "user=\"$db_user\"" >> ~/.my.cnf
    echo "password=\"$db_pass\"" >> ~/.my.cnf
    echo "database=\"$db_name\"" >> ~/.my.cnf
    echo "port=\"$db_port\"" >> ~/.my.cnf

    echo ""
    echo "Datenbankverbindung erfolgreich konfiguriert"
else
    echo "Datenbankverbindung ist bereits konfiguriert"
fi
