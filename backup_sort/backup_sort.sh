#!/bin/bash


##############################################################################
# fuzzy-journey-backup - Backup-Manager für lokale und Remote-Backups        #
#                                                                            #
# Autoren: Fabio Schmeil                                                     #
# Erstellungsdatum: 18.03.2023                                               #
# Version: 1.0.0-alpha                                                       #
# Datei: backup_sort.sh                                              #
# Beschreibung:                                                              #
# Dieses Skript löscht und sortiert Daten, löscht Duplikate, erstellt und    #
# verwaltet lokale und Remote-Backups sowie Backups von DBMS.                #
##############################################################################

set -euo pipefail

# Lese Konfigurationsdatei
source ./configs/backup_sort.conf

backup_files() {
    for file in "${file_formats[@]}"; do
        format=$(echo "$file" | cut -d':' -f1)
        target_folder=$(echo "$file" | cut -d':' -f2)
        files=$(find . -maxdepth 1 -type f -name "*.$format")

        if [ -n "$files" ]; then
            mkdir -p "$target_folder"
            mv $files "$target_folder"
            echo "$(date) - $format-Dateien in $target_folder gesichert" | logger -t $LOG_DAEMON
        fi
    done
}

# Funktion zur Überprüfung von Root-Rechten
check_root() {
    if [[ $(id -u) != 0 ]]; then
        echo "Dieses Skript muss mit Root-Rechten ausgeführt werden."
        exit 1
    fi
}

# Funktion zur Überprüfung, ob ein Benutzer vorhanden ist
check_user() {
    if ! id -u "$1" >/dev/null 2>&1; then
        echo "Benutzer '$1' existiert nicht."
        exit 1
    fi
}

sort_backup_files() {
  local backup_dir="$1"
  cd "$backup_dir"
  ls -t | sort -r
}

create_backup_folder() {
  local backup_dir="$1"
  if [ ! -d "$backup_dir" ]; then
    mkdir "$backup_dir"
    echo "Backup-Verzeichnis erstellt: $backup_dir"
  fi
}

move_files_to_backup_folder() {
  local backup_dir="$1"
  local file_pattern="$2"
  find /home -maxdepth 1 -type f -name "$file_pattern" -exec mv {} "$backup_dir" \;
}



# Funktion zum Erstellen eines Backup-Jobs
# Funktion zum Erstellen eines Backup-Jobs
create_backup_job() {
    local backup_dir="$1"
    local backup_type="$2"
    local backup_script_path="$(pwd)/backup_${backup_type}_$(date +%Y-%m-%d_%H-%M-%S).sh"
    local backup_log_path="$(pwd)/backup_${backup_type}_$(date +%Y-%m-%d_%H-%M-%S).log"
    local cron_job_schedule="$3"

    # Skript zum Erstellen des Backups erstellen
    echo "#!/bin/bash" > "$backup_script_path"
    echo "set -euo pipefail" >> "$backup_script_path"
    echo "tar -czf \"$backup_dir/backup_${backup_type}_$(date +%Y-%m-%d_%H-%M-%S).tar.gz\" -C / home/" >> "$backup_script_path"

    # Skript ausführbar machen
    chmod +x "$backup_script_path"

    # Cron-Job erstellen
    create_cron_job "$backup_script_path" "$cron_job_schedule" "$backup_log_path"

    echo "Backup-Job für Typ '$backup_type' mit Schedule '$cron_job_schedule' erstellt."
}

# Funktion zum Löschen alter Backups
remove_old_backups() {
  local backup_dir="/backup"
  local max_backups=10 # Anzahl der maximalen Backups, die beibehalten werden sollen
  local backup_type="full"
  local days_to_keep=7

  # Lösche vollständige Backups, die älter als "days_to_keep" sind
  find "$backup_dir" -type f -name "backup_${backup_type}*.tar.gz*" -mtime +$days_to_keep -delete

  local num_backups=$(ls -1 "$backup_dir" | wc -l) # Anzahl der aktuellen Backups

  if [ $num_backups -gt $max_backups ]; then
    local num_to_remove=$((num_backups - max_backups))
    echo "Entferne $num_to_remove alte Backups..."

    # Lösche die ältesten Backups, bis nur noch die maximal erlaubte Anzahl übrig ist
    ls -1t "$backup_dir" | tail -$num_to_remove | xargs -I {} rm -rf "$backup_dir"/{}

    echo "Entfernung abgeschlossen."
  else
    echo "Keine alten Backups zum Entfernen gefunden..."
  fi
}


# Function to create a new cron job with the given schedule and command
create_cron_job() {
  local backup_script_path="$1"
  local cron_job_schedule="$2"
  local cron_job_log_path="$3"

  # Create a new cron job with the given schedule and command
  echo "$cron_job_schedule $backup_script_path >> $cron_job_log_path 2>&1" | crontab -

    # Cron-Job ausführen
    crontab /tmp/cronjob

    # Temporäre Datei löschen
    rm /tmp/cronjob

  # Verify that the cron job was created successfully
  if crontab -l | grep -q "$backup_script_path"; then
    echo "Cron job for $backup_script_path created successfully with schedule '$cron_job_schedule'"
  else
    echo "Failed to create cron job for $backup_script_path"
  fi
}

# Überprüfen der Root-Rechte
check_root

# Arrays mit den Dateiformaten
bilder=("jpg" "png" "gif")
dokumente=("pdf" "doc" "docx" "odt" "txt")
downloads=("zip" "tar" "gz")
musik=("mp3" "wav")
oeffentlich=("txt")
videos=("mp4" "avi" "mov")

# Funktion zur Sortierung der Dateien
sortieren() {
    for i in "$1"/*; do
        if [[ -d "$i" ]]; then
            sortieren "$i"
        elif [[ -f "$i" ]]; then
            # Dateiformat ermitteln
            extension="${i##*.}"
            # Zielordner ermitteln
            if printf '%s\n' "${bilder[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Bilder"
            elif printf '%s\n' "${dokumente[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Dokumente"
            elif printf '%s\n' "${downloads[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Downloads"
            elif printf '%s\n' "${musik[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Musik"
            elif printf '%s\n' "${oeffentlich[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Öffentlich"
            elif printf '%s\n' "${videos[@]}" | grep -q -P "\b$extension\b"; then
                zielordner="Videos"
            else
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


# Funktionsaufrufe
remove_old_backups
sortieren
create_cron_job

# Sortieren für jeden User aufrufen
sortieren_fuer_user "germ86"
sortieren_fuer_user "fabio"
sortieren_fuer_user "steffi"

# Remove old backups
remove_old_backups /var/backup 7

# Create cron job
create_cron_job "0 2 * * *" "$HOME/backup_sort.sh"