#!/bin/bash
# Wpspoti Panel - Restore Script
# Usage: restore.sh <backup_file> <domain>
set -euo pipefail

BACKUP_FILE="${1}"
DOMAIN="${2:-}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

echo "Restoring from: ${BACKUP_FILE}"

if [[ "$BACKUP_FILE" == *.sql.gz ]]; then
    DB_PASS=$(grep 'db_root_password' /etc/wpspoti/wpspoti.conf | cut -d'=' -f2)
    DB_NAME=$(echo "${DOMAIN}" | tr '.' '_' | tr '-' '_')
    echo "Restoring database ${DB_NAME}..."
    gunzip -c "${BACKUP_FILE}" | mysql -u root -p"${DB_PASS}" "${DB_NAME}"
elif [[ "$BACKUP_FILE" == *.tar.gz ]]; then
    if [ -n "$DOMAIN" ]; then
        echo "Restoring files for ${DOMAIN}..."
        tar -xzf "${BACKUP_FILE}" -C /var/www/ 2>/dev/null
        chown -R www-data:www-data "/var/www/${DOMAIN}"
    else
        echo "Restoring full backup..."
        tar -xzf "${BACKUP_FILE}" -C / 2>/dev/null
    fi
fi

echo "Restore completed successfully."
