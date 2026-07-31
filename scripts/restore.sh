#!/bin/bash
# MyHarur V4 Restore Script

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <encrypted_db_file.sql.gpg> <encrypted_uploads_file.tar.gz.gpg>"
    exit 1
fi

DB_ENCRYPTED=$1
UPLOADS_ENCRYPTED=$2

DB_CONTAINER="harur-db-1"
DB_USER="postgres"
DB_NAME="harur_town"
UPLOADS_DIR="./backend/static/uploads"

echo "[$(date)] Starting MyHarur Restore Process..."

# 1. Decrypt Files
echo "[$(date)] Decrypting backups..."
gpg -d "$DB_ENCRYPTED" > "restored_db.sql"
gpg -d "$UPLOADS_ENCRYPTED" > "restored_uploads.tar.gz"

# 2. Restore Database
echo "[$(date)] Restoring database..."
docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker exec -i $DB_CONTAINER psql -U $DB_USER -d $DB_NAME < "restored_db.sql"

# 3. Restore Uploads
echo "[$(date)] Restoring uploads..."
mkdir -p "$UPLOADS_DIR"
tar -xzf "restored_uploads.tar.gz" -C /

# 4. Cleanup
rm "restored_db.sql" "restored_uploads.tar.gz"

echo "[$(date)] Restore completed successfully."
