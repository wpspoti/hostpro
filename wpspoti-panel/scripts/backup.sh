#!/bin/bash
# Wpspoti Panel - Backup Script
# Usage: backup.sh <site_domain|full> <backup_type> <backup_path>
set -euo pipefail

DOMAIN="${1:-full}"
TYPE="${2:-full}"
BACKUP_DIR="${3:-/var/wpspoti/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_PASS=$(grep 'db_root_password' /etc/wpspoti/wpspoti.conf | cut -d'=' -f2)

mkdir -p "${BACKUP_DIR}"

if [ "$DOMAIN" = "full" ]; then
    FILENAME="full_backup_${TIMESTAMP}.tar.gz"
    echo "Creating full server backup..."
    tar -czf "${BACKUP_DIR}/${FILENAME}" \
        --exclude='*.sock' \
        /var/www/ \
        /etc/nginx/sites-available/ \
        /etc/wpspoti/ \
        /var/wpspoti/panel.db \
        2>/dev/null || true

    # Dump all databases
    mysqldump -u root -p"${DB_PASS}" --all-databases > "/tmp/wpspoti_all_db_${TIMESTAMP}.sql" 2>/dev/null
    tar -rf "${BACKUP_DIR}/${FILENAME}" -C /tmp "wpspoti_all_db_${TIMESTAMP}.sql" 2>/dev/null || true
    rm -f "/tmp/wpspoti_all_db_${TIMESTAMP}.sql"
else
    SITE_DIR="/var/www/${DOMAIN}"
    if [ ! -d "$SITE_DIR" ]; then
        echo "ERROR: Site directory not found: ${SITE_DIR}"
        exit 1
    fi

    case "$TYPE" in
        files)
            FILENAME="${DOMAIN}_files_${TIMESTAMP}.tar.gz"
            echo "Backing up files for ${DOMAIN}..."
            tar -czf "${BACKUP_DIR}/${FILENAME}" -C /var/www "${DOMAIN}" 2>/dev/null
            ;;
        database)
            DB_NAME=$(echo "${DOMAIN}" | tr '.' '_' | tr '-' '_')
            FILENAME="${DOMAIN}_db_${TIMESTAMP}.sql.gz"
            echo "Backing up database for ${DOMAIN}..."
            mysqldump -u root -p"${DB_PASS}" "${DB_NAME}" 2>/dev/null | gzip > "${BACKUP_DIR}/${FILENAME}"
            ;;
        *)
            FILENAME="${DOMAIN}_full_${TIMESTAMP}.tar.gz"
            echo "Creating full backup for ${DOMAIN}..."
            tar -czf "${BACKUP_DIR}/${FILENAME}" -C /var/www "${DOMAIN}" 2>/dev/null

            DB_NAME=$(echo "${DOMAIN}" | tr '.' '_' | tr '-' '_')
            mysqldump -u root -p"${DB_PASS}" "${DB_NAME}" 2>/dev/null | gzip > "${BACKUP_DIR}/${DOMAIN}_db_${TIMESTAMP}.sql.gz"
            tar -rf "${BACKUP_DIR}/${FILENAME}" -C "${BACKUP_DIR}" "${DOMAIN}_db_${TIMESTAMP}.sql.gz" 2>/dev/null || true
            rm -f "${BACKUP_DIR}/${DOMAIN}_db_${TIMESTAMP}.sql.gz"
            ;;
    esac
fi

FILE_SIZE=$(stat -c%s "${BACKUP_DIR}/${FILENAME}" 2>/dev/null || stat -f%z "${BACKUP_DIR}/${FILENAME}" 2>/dev/null || echo "0")
echo "BACKUP_FILE=${FILENAME}"
echo "BACKUP_SIZE=${FILE_SIZE}"
echo "Backup completed successfully."
