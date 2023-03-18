#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_main.sh                                                      #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

# Skript-Code beginnt hier


set -euo pipefail

# Load Menu
sourc backup_menu.sh

# Load backup_logging.sh
source ./backup_logging.sh
# Load User and Group Permissions
source ./backup_user_group_permissions.sh

# Call backup_menu function
backup_menu

# Funktion zur interaktiven Konfiguration
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

# Check if the configuration file exists
if [ ! -f .configs/backup.conf ]; then
  configure_backup
else
  source .configs/backup.conf
fi

# Check if the configuration file exists
if [ ! -f /path/to/log/config/file ]; then
    # If the configuration file doesn't exist, prompt the user to configure the logging options
    echo "Logging configuration not found. Please configure the logging options."
    get_log_config
fi


# Check if the configuration file exists
if [ ! -f /path/to/log/config/file ]; then
    # If the configuration file doesn't exist, prompt the user to configure the logging options
    echo "Logging configuration not found. Please configure the logging options."
    get_log_config
fi

if [ "$1" = "configure-logging" ]; then
    get_log_config
    exit 0
fi


# Get backup parameters interactively
get_backup_parameters_interactive

# Create backup with specified parameters
create_backup "$source_dir" "$target_dir" "$backup_file_name"

# Backup user and group permissions
backup_user_group_permissions "$backup_file_name" "$user_name" "$group_name"


# Call log function
log "info" "This is an information message."

# Funktion zur Protokollierung
logging() {
    # Check if logging settings have been initialized
    if [[ ! -f "$LOGGING_CONF" ]]; then
        echo "Logging options not set. Please select a logging method:"
        echo "1. Use default system logger"
        echo "2. Use custom logger"
        read -p "Enter your choice (1 or 2): " LOGGING_OPTION
        while [[ "$LOGGING_OPTION" != "1" && "$LOGGING_OPTION" != "2" ]]; do
            read -p "Invalid option. Please select 1 or 2: " LOGGING_OPTION
        done

        # Write logging options to config file
        echo "LOGGING_OPTION=$LOGGING_OPTION" >> "$LOGGING_CONF"
    else
        # Read logging options from config file
        source "$LOGGING_CONF"
    fi

    # Set logging method
    if [[ "$LOGGING_OPTION" == "1" ]]; then
        LOGGER="logger"
    else
        read -p "Enter the command for your custom logger: " LOGGER_COMMAND
        echo "LOGGER_COMMAND=$LOGGER_COMMAND" >> "$LOGGING_CONF"
        LOGGER="$LOGGER_COMMAND"
    fi

    # Log message
    $LOGGER "$1"
}

# Konfigurationsdatei für Protokollierung
LOGGING_CONF="$HOME/.backup_sort/logging.conf"

# Protokollierung aktivieren
logging "Backup-Skript gestartet."

# Funktion zur Überprüfung der Root-Rechte
check_root() {
    if [[ $EUID -ne 0 ]]; then
        logging "Dieses Skript muss als root ausgeführt werden." >&2
        exit 1
    fi
}

# Überprüfen der Root-Rechte
check_root



# Function to create a new cron job with the given schedule and command

# Benutzerdefinierte Parameter
backup_user_params() {
    local USER=${1:-root}
    local DIR=${2:-/var/backup}
    local RETENTION=${3:-7}

    # Überprüfen, ob das Verzeichnis existiert
    if [[ ! -d $DIR ]]; then
        backup_log "error" "$DIR existiert nicht"
        exit 1
    fi

    # Überprüfen, ob der Benutzer existiert
    if ! id -u "$USER" >/dev/null 2>&1; then
        backup_log "error" "Benutzer $USER existiert nicht"
        exit 1
    fi

    backup_log "info" "Backup-Verzeichnis ist $DIR für Benutzer $USER mit Aufbewahrung von $RETENTION Tagen"
}

# Überprüfung des freien Speicherplatzes
check_free_space() {
    local DIR="$1"
    local MIN_SPACE="$2"

    local free_space=$(df -P "$DIR" | awk 'NR==2 {print $4}')
    if [[ $free_space -lt $MIN_SPACE ]]; then
        backup_log "error" "Nicht genügend freier Speicherplatz auf $DIR. Benötigt: $MIN_SPACE Bytes, verfügbar: $free_space Bytes"
        exit 1
    fi

    backup_log "info" "Freier Speicherplatz auf $DIR ausreichend"
}


# Funktion zur Auswahl des Backup-Typs
select_backup_type() {
  backup_log "info" "Backup-Typ auswählen"
  echo "Bitte wählen Sie den Backup-Typ:"
  echo "1. Vollständiges Backup"
  echo "2. Inkrementelles Backup"

  read backup_type
  while [[ ! "$backup_type" =~ ^[1-2]$ ]]; do
    echo "Ungültige Eingabe. Bitte wählen Sie 1 für Vollständiges Backup oder 2 für Inkrementelles Backup."
    read backup_type
  done

  if [ "$backup_type" = "1" ]; then
    backup_log "info" "Vollständiges Backup wird erstellt"
    backup_full_incremental.sh full
  else
    backup_log "info" "Inkrementelles Backup wird erstellt"
    backup_full_incremental.sh incremental
  fi
}

# Hauptskript
backup_main() {
    backup_log "info" "Backup-Prozess gestartet"

    backup_user_params
    check_free_space

    # Main script
    echo "Starting backup process..."
    select_backup_type
    echo "Backup process completed."

    backup_log "info" "Backup-Prozess abgeschlossen"
}

# Aufruf der Hauptfunktion
backup_main



# Function to create a full or incremental backup based on the given arguments
create_backup() {
  local src_dir="$1"
  local dest_dir="$2"
  local encrypted="$3"
  local backup_type="$4"  # full or incremental
  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local backup_name="backup_${backup_type}_${timestamp}.tar.gz"

  # If encryption is enabled, add ".enc" to the backup file name
  if [ "$encrypted" = true ]; then
    backup_name="${backup_name}.enc"
  fi

  # Create the backup based on the selected type
  if [ "$backup_type" = "full" ]; then
    tar -czf "$dest_dir/$backup_name" "$src_dir"
  elif [ "$backup_type" = "incremental" ]; then
    # Use rsync to create an incremental backup
    rsync -a --link-dest="$dest_dir/latest_full_backup" "$src_dir" "$dest_dir/$backup_name"
  else
    echo "Invalid backup type: $backup_type. Please specify 'full' or 'incremental'."
    exit 1
  fi

  # If encryption is enabled, encrypt the backup with GPG
  if [ "$encrypted" = true ]; then
    gpg --yes --batch --passphrase="$GPG_PASSPHRASE" --cipher-algo AES256 --symmetric "$dest_dir/$backup_name"
    rm "$dest_dir/$backup_name"
  fi

  log "Created $backup_type backup of $src_dir to $dest_dir/$backup_name"
}

# Set default logging state to on
LOGGING_ENABLED=true
LOG_FILE="/var/log/backup.log"

# Function to enable/disable logging
toggle_logging() {
    if [ "$LOGGING_ENABLED" = true ]; then
        echo "Logging disabled"
        LOGGING_ENABLED=false
    else
        echo "Logging enabled"
        LOGGING_ENABLED=true
    fi
}

# Function for logging messages
log() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d %T")

    if [ "$LOGGING_ENABLED" = true ]; then
        echo "$timestamp $message" | tee -a "$LOG_FILE"
    else
        echo "$timestamp $message"
    fi
}

# Check if the script is being run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root. Please enter the root password:"
    su -c "$0 $*" root
    exit 0
fi

# Function to remove old backups and keep only the latest n backups
remove_old_back



# Prüfe, ob das Skript als Root ausgeführt wird
if [ "$(id -u)" != "0" ]; then
    echo "Das Skript muss als Root ausgeführt werden. Bitte geben Sie das Root-Passwort ein:"
    su -c "$0 $*" root
    exit 0
fi

# Function to create a backup of the specified directory
create_backup() {
  local src_dir="$1"
  local dest_dir="$2"
  local encrypted="$3"
  local backup_type="$4"  # full or incremental
  local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
  local backup_name="backup_${backup_type}_${timestamp}.tar.gz"

  # If encryption is enabled, add ".enc" to the backup file name
  if [ "$encrypted" = true ]; then
    backup_name="${backup_name}.enc"
  fi

  # Create the backup based on the selected type
  if [ "$backup_type" = "full" ]; then
    tar -czf "$dest_dir/$backup_name" "$src_dir"
  elif [ "$backup_type" = "incremental" ]; then
    # Use rsync to create an incremental backup
    rsync -a --link-dest="$dest_dir/latest_full_backup" "$src_dir" "$dest_dir/$backup_name"
  else
    echo "Invalid backup type: $backup_type. Please specify 'full' or 'incremental'."
    exit 1
  fi

  # If encryption is enabled, encrypt the backup with GPG
  if [ "$encrypted" = true ]; then
    gpg --yes --batch --passphrase="$GPG_PASSPHRASE" --cipher-algo AES256 --symmetric "$dest_dir/$backup_name"
    rm "$dest_dir/$backup_name"
  fi

  log "Created $backup_type backup of $src_dir to $dest_dir/$backup_name"
}

remove_old_backups() {
  local backup_dir="/backup"
  local max_backups=10 # Anzahl der maximalen Backups, die beibehalten werden sollen
  local num_backups=$(ls -1 "$backup_dir" | wc -l) # Anzahl der aktuellen Backups

  if [ $num_backups -gt $max_backups ]; then
    local num_to_remove=$((num_backups - max_backups))
    echo "Entferne $num_to_remove alte Backups..."

    # Lösche die ältesten Backups, bis nur noch die maximal erlaubte Anzahl übrig ist
    ls -1t "$backup_dir" | tail -$num_to_remove | xargs -I {} rm -rf "$backup_dir"/{}

    echo "Entfernung abgeschlossen."
  else
    echo "Keine alten Backups zum Entfernen gefunden."
  fi
}

# Funktion zur Überprüfung und Installation von benötigten Tools
check_tools() {
    local tools=(rsync)

    for tool in "${tools[@]}"; do
        if ! command -v $tool > /dev/null; then
            echo "$tool ist nicht installiert. Installieren Sie es jetzt..."
            apt-get install -y $tool
        fi
    done
}

# Funktion zum Ausführen eines einzelnen Skripts
run_script() {
    local script=$1
    if [ -x "$script" ]; then
        echo "Starte $script..."
        "$script"
        echo "$script abgeschlossen."
    else
        echo "Fehler: $script nicht gefunden oder nicht ausführbar."
    fi
}


# Funktion zur Verwendung von Kommandozeilenargumenten

parse_arguments() {
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
        -l|--log)
        toggle_logging
        shift # gehe zum nächsten Argument
        ;;
        -h|--help)
        echo "Hilfe: backup_main.sh [-l|--log] [-h|--help]"
        echo "Optionen:"
        echo "-l, --log         Schaltet das Logging ein oder aus."
        echo "-h, --help        Zeigt diese Hilfe an."
        exit 0
        ;;
        *)    # unbekannte Optionen
        echo "Fehler: Unbekannte Option $key. Führen Sie backup_main.sh -h aus, um Hilfe anzuzeigen."
        exit 1
        ;;
    esac
  done
}

# Aufruf der Funktion zur Verwendung von Kommandozeilenargumenten
parse_arguments "$@"

# Hauptfunktion zum Ausführen der Skripte
run_backup() {
    local scripts=()
    local choice
    local encrypted_choice

    echo "Bitte wählen Sie die auszuführenden Skripte aus (mit der Enter-Taste bestätigen):"
    echo "1) backup_mount.sh"
    echo "2) backup_user_group_permissions.sh"
    echo "3) backup_sort.sh"
    echo "4) backup_full_incremental.sh"
    echo "5) Alle Skripte nacheinander ausführen"
    read -r choice

    echo "Soll das Backup verschlüsselt werden? (Ja/Nein)"
    read -r encrypted_choice

    case ${encrypted_choice,,} in
        j|ja|y|yes) encrypted=true;;
        *) encrypted=false;;
    esac

    case $choice in
        1) scripts+=(backup_mount.sh);;
        2) scripts+=(backup_user_group_permissions.sh);;
        3) scripts+=(backup_sort.sh);;
        4) scripts+=(backup_full_incremental.sh);;
        5) scripts+=(backup_mount.sh backup_user_group_permissions.sh backup_sort.sh backup_full_incremental.sh);;
        *) echo "Fehler: Ungültige Auswahl.";;
    esac

    # Überprüfen und Installieren von benötigten Tools
    check_tools

    # Ausführen der ausgewählten Skripte
    for script in "${scripts[@]}"; do
        if [ "$encrypted" = true ]; then
            run_script "encrypt.sh $script"
        else
            run_script "$script"
        fi
    done

    # Entfernen älterer Backups
    remove_old_backups
}


# Aufruf der Hauptfunktion
run_backup

function update_configuration {
    echo "Do you want to update your backup configuration? (Y/N)"
    read response
    if [ "$response" == "Y" ] || [ "$response" == "y" ]; then
        read -p "Enter the source directory: " source_directory
        read -p "Enter the target directory: " target_directory
        read -p "Enter the log directory: " log_directory

        # Write the configuration to the configuration file
        echo "SOURCE_DIRECTORY=$source_directory" > backup.conf
        echo "TARGET_DIRECTORY=$target_directory" >> backup.conf
        echo "LOG_DIRECTORY=$log_directory" >> backup.conf

        echo "Backup configuration updated."
    fi
}
