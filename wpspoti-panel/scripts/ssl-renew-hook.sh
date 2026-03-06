#!/bin/bash
# Wpspoti Panel - SSL Renewal Hook
# Called by certbot after certificate renewal
# certbot renew --deploy-hook /var/wpspoti/scripts/ssl-renew-hook.sh

DB_PATH="/var/wpspoti/panel.db"
DOMAIN="${RENEWED_DOMAINS:-}"

if [ -n "$DOMAIN" ]; then
    FIRST_DOMAIN=$(echo "$DOMAIN" | awk '{print $1}')
    EXPIRY=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/${FIRST_DOMAIN}/cert.pem" 2>/dev/null | cut -d= -f2)
    EXPIRY_ISO=$(date -d "$EXPIRY" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "")

    if [ -n "$EXPIRY_ISO" ]; then
        sqlite3 "$DB_PATH" "UPDATE sites SET ssl_expires_at = '${EXPIRY_ISO}', updated_at = datetime('now') WHERE domain = '${FIRST_DOMAIN}';"
    fi
fi

systemctl reload nginx 2>/dev/null || true
echo "SSL renewal hook executed for: ${DOMAIN}"
