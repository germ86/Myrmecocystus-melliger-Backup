#!/bin/bash

# Define usage function
usage() {
  echo "Usage: $0 [-h] [-b BACKUP] [-r RESTORE]"
  echo "  -h            Display help"
  echo "  -b BACKUP     Backup the specified databases (comma-separated list)"
  echo "  -r RESTORE    Restore the specified backups (comma-separated list)"
  exit 1
}

# Define error function
error() {
  echo "ERROR: $1"
  usage
}

# Parse options
while getopts ":hb:r:" opt; do
  case ${opt} in
    h )
      usage
      ;;
    b )
      DBS_BACKUP=$OPTARG
      ;;
    r )
      DBS_RESTORE=$OPTARG
      ;;
    \? )
      error "Invalid option: -$OPTARG"
      ;;
    : )
      error "Option -$OPTARG requires an argument"
      ;;
  esac
done
shift $((OPTIND -1))

# Check if backup or restore options are specified
if [[ -z "$DBS_BACKUP" && -z "$DBS_RESTORE" ]]; then
  error "Please specify either -b or -r option"
fi

# Define function to execute backup for a specific DBMS system
backup_dbms() {
  local dbms="$1"
  local databases="$2"
  local backup_script="backup_dbms_${dbms}_remote.sh"
  
  # Check if backup script exists for this DBMS system
  if [[ ! -f "$backup_script" ]]; then
    echo "ERROR: Backup script not found for DBMS $dbms"
    return 1
  fi
  
  # Execute backup script for each database
  for db in ${databases//,/ }; do
    ./$backup_script -b $db
  done
}

# Define function to execute restore for a specific DBMS system
restore_dbms() {
  local dbms="$1"
  local backups="$2"
  local restore_script="restore_dbms_${dbms}_remote.sh"
  
  # Check if restore script exists for this DBMS system
  if [[ ! -f "$restore_script" ]]; then
    echo "ERROR: Restore script not found for DBMS $dbms"
    return 1
  fi
  
  # Execute restore script for each backup
  for backup in ${backups//,/ }; do
    ./$restore_script -r $backup
  done
}

# Define function to execute backup for all specified DBMS systems
backup_all() {
  local databases="$1"
  local dbms_list=("mysql" "postgresql")
  
  # Execute backup for each DBMS system
  for dbms in ${dbms_list[@]}; do
    backup_dbms $dbms "$databases"
  done
}

# Define function to execute restore for all specified DBMS systems
restore_all() {
  local backups="$1"
  local dbms_list=("mysql" "postgresql")
  
  # Execute restore for each DBMS system
  for dbms in ${dbms_list[@]}; do
    restore_dbms $dbms "$backups"
  done
}

# Main script logic
if [[ ! -z "$DBS_BACKUP" ]]; then
  # Execute backup for all specified DBMS systems
  backup_all "$DBS_BACKUP"
fi

if [[ ! -z "$DBS_RESTORE" ]]; then
  # Execute restore for all specified DBMS systems
  restore_all "$DBS_RESTORE"
fi
