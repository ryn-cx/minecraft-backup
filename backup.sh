#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/.env"

LOG_FILE="$SERVER_DIR/logs/latest.log"
BACKUP_LOG="$SERVER_DIR/minecraft-backup.log"

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$BACKUP_LOG"
    echo "$msg"
}

log_error() {
    log "ERROR: $1"
    send_cmd "/say ERROR: $1"
}

send_cmd() {
    screen -S "$SCREEN_NAME" -p 0 -X stuff "$1$(printf '\r')"
}

send_and_wait() {
    local cmd="$1"
    local pattern="$2"
    # Get the number of lines in the log so only lines after the command are executed
    # when checking for the command to be completed.
    local line_count
    line_count=$(wc -l < "$LOG_FILE")

    send_cmd "$cmd"
    
    # Wait 60 seconds for the command to be completed.
    for i in $(seq 1 60); do
        if tail -n +"$((line_count + 1))" "$LOG_FILE" | grep -q "$pattern"; then
            return 0
        fi
        sleep 1
    done
    return 1
}

# Verify the server is running
if ! screen -list | grep -q "$SCREEN_NAME"; then
    log "ERROR: Screen session '$SCREEN_NAME' not found. Is the server running?"
    # Can't send to server since screen isn't running
    exit 1
fi

log "Starting backup."

# Disable saving and flush data
if ! send_and_wait "save-off" "Automatic saving is now disabled"; then
    log_error "Backup Error: save-off did not complete within 60 seconds."
    exit 1
fi
if ! send_and_wait "save-all" "Saved the game"; then
    log_error "Backup Error: save-all did not complete within 60 seconds."
    exit 1
fi


# Backup with rclone
log "Starting rclone sync to $RCLONE_REMOTE"

RCLONE_STATS=$(rclone sync "$SERVER_DIR" "$RCLONE_REMOTE" --stats-one-line -v 2>&1)
RCLONE_EXIT=$?

if [[ $RCLONE_EXIT -eq 0 ]]; then
    log "rclone completed successfully. $RCLONE_STATS"
else
    log_error "Backup Error: rclone sync failed (exit $RCLONE_EXIT). Check logs for details."
fi

# Re-enable saving
if send_and_wait "save-on" "Automatic saving is now enabled"; then
    log "Saving re-enabled. Backup process finished."
else
    log_error "Backup Error: save-on did not confirm, but backup is complete."
fi

send_cmd "/say Backup completed successfully."
