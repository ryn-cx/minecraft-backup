# minecraft-backup

Shell script that backs up a Minecraft server to Backblaze B2 using rclone. Designed to run via cron while the server stays running.

- Safely pauses world saving (`save-all`, `save-off`) before backing up, then re-enables it
- Broadcasts errors and success to players in-game via `/say`
- Automatic versioned backups via Backblaze B2's built-in file versioning
- Should cost pennies per month for a typical server

## Requirements

- `screen` (server must be running in a named screen session)
- `rclone` (configured with a Backblaze B2 remote)

## Setup

1. Copy `backup.sh` and `.env` to your server.
2. Edit `.env`:
   ```
   SERVER_DIR="$HOME/minecraft"
   SCREEN_NAME="minecraft"
   RCLONE_REMOTE="b2-bucket:rclone-name"
   ```
3. `chmod +x backup.sh`
4. Add to crontab (`crontab -e`):
   ```
   0 * * * * /path/to/backup.sh
   ```

## Logs

Written to `$SERVER_DIR/minecraft-backup.log`.
