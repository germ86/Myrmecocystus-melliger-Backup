#!/bin/bash

##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_logging.sh                                                   #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Set up logging
source .configs/backup_logging.conf

function get_log_config() {
    echo "How do you want to log the backup process?"
    echo "1. Simple logging (default)"
    echo "2. Detailed logging"
    read -p "Enter your choice [1-2]: " choice
    case $choice in
        2)
            echo "Detailed logging selected."
            echo "LOG_FORMAT=detailed" > /path/to/log/config/file
            ;;
        *)
            echo "Simple logging selected."
            echo "LOG_FORMAT=simple" > /path/to/log/config/file
            ;;
    esac

    echo "Do you want to receive email notifications? [y/n]"
    read send_email
    if [ "$send_email" = "y" ]; then
        read -p "Enter email address to receive notifications: " email
        echo "SEND_EMAIL=true" >> /path/to/log/config/file
        echo "EMAIL_ADDRESS=$email" >> /path/to/log/config/file
    else
        echo "SEND_EMAIL=false" >> /path/to/log/config/file
    fi
}

# Function to send email
send_mail() {
    local subject="$1"
    local body="$2"

    # Use mailx to send the email
    echo "$body" | mailx -s "$subject" "$EMAIL_ADDRESS"
}

# Log an error message and send an email
log_error() {
    local message="$1"

    # Log the error
    log "error" "$message"

    # Send an email
    local subject="[ERROR] Backup failed"
    local body="An error occurred during the backup:\n\n$message"
    send_mail "$subject" "$body"
}

# Log function
log() {
    # Get the logging level from the first argument
    case $1 in
        debug)
            level=$DEBUG
            ;;
        info)
            level=$INFO
            ;;
        warning)
            level=$WARNING
            ;;
        error)
            level=$ERROR
            ;;
        *)
            # Default to info level if an invalid level is provided
            level=$INFO
            ;;
    esac

    # Get the log message from the second argument
    message="$2"

    # Write the log message to the appropriate log file based on the logging level
    case $level in
        $DEBUG)
            echo "$(date) [DEBUG] $message" >> $DEBUG_LOG_FILE
            ;;
        $INFO)
            echo "$(date) [INFO] $message" >> $INFO_LOG_FILE
            ;;
        $WARNING)
            echo "$(date) [WARNING] $message" >> $WARNING_LOG_FILE
            ;;
        $ERROR)
            echo "$(date) [ERROR] $message" >> $ERROR_LOG_FILE
            # Send an email on error
            local subject="[ERROR] Backup failed"
            local body="An error occurred during the backup:\n\n$message"
            send_mail "$subject" "$body"
            ;;
    esac
}

# Function to read configuration file
read_config() {
    local file="$1"

    # Check if file exists
    if [[ ! -f "$file" ]]; then
        log_error "Config file $file not found"
        exit 1
    fi

    # Read config file
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^# || "$line" =~ ^[[:space:]]*$ ]]; then
            continue
        fi
        # Get variable name and value
        var_name=$(echo "$line" | cut -d= -f1)
        var_value=$(echo "$line" | cut -d= -f2-)
        # Export variable
        export "$var_name"="$var_value"
    done < "$file"
}

# Read configuration file
read_config .configs/backup_logging.conf

# Send an email on backup completion
send_mail "Backup completed successfully" "The backup has completed successfully."

# Log a message at the info level
log "info" "Backup completed successfully"
