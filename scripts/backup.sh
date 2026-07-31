#!/bin/bash
# MyHarur V4 Production Backup Script
# Creates daily encrypted backups of the database and static uploads.

set -e

BACKUP_DIR="/var/backups/myharur"
DATE=$(date +"%Y%m%d_%H%M%S")
DB_CONTAINER="harur-db-1"
DB_USER="postgres"
DB_NAME="harur_town"
UPLOADS_DIR="./backend/static/uploads"
GPG_RECIPIENT="admin@myharur.local"  # Ensure this key is imported in the server's GPG keychain

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting MyHarur Backup Process..."

# 1. Database Backup
DB_BACKUP_FILE="$BACKUP_DIR/db_backup_$DATE.sql"
echo "[$(date)] Dumping database to $DB_BACKUP_FILE..."
docker exec -t $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME > "$DB_BACKUP_FILE"

# 2. Uploads Backup
UPLOADS_BACKUP_FILE="$BACKUP_DIR/uploads_backup_$DATE.tar.gz"
echo "[$(date)] Archiving uploads to $UPLOADS_BACKUP_FILE..."
tar -czf "$UPLOADS_BACKUP_FILE" "$UPLOADS_DIR"

# 3. Encryption (Optional but recommended)
echo "[$(date)] Encrypting backups..."
gpg --batch --yes --trust-model always -r "$GPG_RECIPIENT" -e "$DB_BACKUP_FILE"
gpg --batch --yes --trust-model always -r "$GPG_RECIPIENT" -e "$UPLOADS_BACKUP_FILE"

# 4. Cleanup unencrypted files
rm "$DB_BACKUP_FILE" "$UPLOADS_BACKUP_FILE"

# 5. Retention Policy (Keep last 7 days)
echo "[$(date)] Cleaning up old backups (>7 days)..."
find "$BACKUP_DIR" -type f -name "*.gpg" -mtime +7 -exec rm {} \;

echo "[$(date)] Backup completed successfully."
