#!/bin/bash
###############################################
# Wpspoti Hosting Panel - Installer
# Ubuntu 24.04 LTS
# Usage: sudo bash install.sh
###############################################
set -euo pipefail

PANEL_VERSION="1.0.0"
PANEL_PORT="8443"
PANEL_DIR="/var/www/wpspoti-panel"
PANEL_DATA="/var/wpspoti"
PANEL_CONFIG="/etc/wpspoti"
PANEL_LOG="/var/log/wpspoti"
PHP_VERSION="8.3"
DB_PATH="${PANEL_DATA}/panel.db"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# ============================================================
# PRE-CHECKS
# ============================================================
[[ $EUID -eq 0 ]] || error "Bu script root olarak çalıştırılmalı: sudo bash install.sh"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    log "İşletim sistemi: $PRETTY_NAME"
else
    warn "OS tespit edilemedi, devam ediliyor..."
fi

generate_password() {
    openssl rand -base64 24 | tr -d '=/+' | head -c 16
}

ADMIN_PASS=$(generate_password)
DB_ROOT_PASS=$(generate_password)

log "========================================"
log "  Wpspoti Panel Installer v${PANEL_VERSION}"
log "========================================"
echo ""

# ============================================================
# STEP 1: System Update & Prerequisites
# ============================================================
log "ADIM 1/12: Sistem güncelleniyor..."
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y
apt install -y software-properties-common curl wget gnupg2 \
    unzip zip lsb-release apt-transport-https ca-certificates \
    sqlite3 acl sudo openssl

# ============================================================
# STEP 2: Install Packages
# ============================================================
log "ADIM 2/12: Paketler kuruluyor..."
apt install -y \
    nginx \
    php${PHP_VERSION}-fpm php${PHP_VERSION}-cli php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-curl \
    php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mysql php${PHP_VERSION}-bcmath php${PHP_VERSION}-readline \
    mariadb-server mariadb-client \
    certbot python3-certbot-nginx \
    fail2ban \
    ufw \
    vsftpd \
    2>/dev/null || true

# Optional: BIND9, Postfix, Dovecot
apt install -y bind9 bind9-utils 2>/dev/null || warn "BIND9 kurulamadı, DNS yönetimi devre dışı"
apt install -y postfix dovecot-imapd dovecot-pop3d 2>/dev/null || warn "Mail servisleri kurulamadı"

# WP-CLI
if ! command -v wp &>/dev/null; then
    log "WP-CLI kuruluyor..."
    curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# ============================================================
# STEP 3: Create Directories
# ============================================================
log "ADIM 3/12: Dizin yapısı oluşturuluyor..."
mkdir -p ${PANEL_DIR}
mkdir -p ${PANEL_DATA}/{backups,sessions,scripts}
mkdir -p ${PANEL_CONFIG}/templates
mkdir -p ${PANEL_LOG}
mkdir -p /var/www
mkdir -p /var/log/php
mkdir -p /var/mail/vhosts

# ============================================================
# STEP 4: Deploy Panel Files
# ============================================================
log "ADIM 4/12: Panel dosyaları yerleştiriliyor..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Panel dosyalarını kopyala
if [ -d "${SCRIPT_DIR}/panel" ]; then
    cp -r "${SCRIPT_DIR}/panel/"* ${PANEL_DIR}/
else
    # Eğer wpspoti-panel alt dizinindeyse
    if [ -d "${SCRIPT_DIR}/wpspoti-panel/panel" ]; then
        cp -r "${SCRIPT_DIR}/wpspoti-panel/panel/"* ${PANEL_DIR}/
        SCRIPT_DIR="${SCRIPT_DIR}/wpspoti-panel"
    else
        error "Panel dosyaları bulunamadı!"
    fi
fi

# Config dosyalarını kopyala
[ -f "${SCRIPT_DIR}/config/wpspoti.conf.example" ] && cp "${SCRIPT_DIR}/config/wpspoti.conf.example" ${PANEL_CONFIG}/wpspoti.conf
[ -d "${SCRIPT_DIR}/config/templates" ] && cp -r "${SCRIPT_DIR}/config/templates/"* ${PANEL_CONFIG}/templates/ 2>/dev/null || true

# Script dosyalarını kopyala
[ -d "${SCRIPT_DIR}/scripts" ] && cp -r "${SCRIPT_DIR}/scripts/"* ${PANEL_DATA}/scripts/ 2>/dev/null || true
chmod +x ${PANEL_DATA}/scripts/*.sh 2>/dev/null || true

# Database schema
[ -f "${SCRIPT_DIR}/database/schema.sql" ] && cp "${SCRIPT_DIR}/database/schema.sql" ${PANEL_DATA}/schema.sql

# Permissions
chown -R www-data:www-data ${PANEL_DIR}
chmod -R 750 ${PANEL_DIR}
chmod -R 700 ${PANEL_DIR}/core 2>/dev/null || true
chown -R www-data:www-data ${PANEL_DATA}
chmod -R 750 ${PANEL_DATA}

# ============================================================
# STEP 5: Download Vendor JS Libraries
# ============================================================
log "ADIM 5/12: JavaScript kütüphaneleri indiriliyor..."
mkdir -p ${PANEL_DIR}/assets/js/vendor

# Alpine.js
curl -sL "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js" -o ${PANEL_DIR}/assets/js/vendor/alpine.min.js 2>/dev/null || \
    echo "/* Alpine.js - load from CDN */" > ${PANEL_DIR}/assets/js/vendor/alpine.min.js

# Chart.js
curl -sL "https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js" -o ${PANEL_DIR}/assets/js/vendor/chart.min.js 2>/dev/null || \
    echo "/* Chart.js - load from CDN */" > ${PANEL_DIR}/assets/js/vendor/chart.min.js

chown -R www-data:www-data ${PANEL_DIR}/assets/

# ============================================================
# STEP 6: Initialize SQLite Database
# ============================================================
log "ADIM 6/12: Veritabanı başlatılıyor..."
ADMIN_HASH=$(php${PHP_VERSION} -r "echo password_hash('${ADMIN_PASS}', PASSWORD_ARGON2ID);")

if [ -f "${PANEL_DATA}/schema.sql" ]; then
    sqlite3 ${DB_PATH} < ${PANEL_DATA}/schema.sql
else
    error "Schema dosyası bulunamadı!"
fi

sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO users (username, email, password_hash, role) VALUES ('admin', 'admin@localhost', '${ADMIN_HASH}', 'admin');"

chown www-data:www-data ${DB_PATH}
chmod 660 ${DB_PATH}
# WAL dosyaları için de izin ver
touch ${DB_PATH}-wal ${DB_PATH}-shm 2>/dev/null || true
chown www-data:www-data ${DB_PATH}-wal ${DB_PATH}-shm 2>/dev/null || true

# ============================================================
# STEP 7: Configure Panel Config File
# ============================================================
log "ADIM 7/12: Panel ayarları yapılandırılıyor..."
cat > ${PANEL_CONFIG}/wpspoti.conf <<CONF
panel_name=Wpspoti Panel
panel_port=${PANEL_PORT}
panel_dir=${PANEL_DIR}
data_dir=${PANEL_DATA}
backup_dir=${PANEL_DATA}/backups
log_dir=${PANEL_LOG}
php_version=${PHP_VERSION}
db_path=${DB_PATH}
db_root_password=${DB_ROOT_PASS}
session_timeout=1800
max_upload_size=256M
ssl_cert=/etc/ssl/wpspoti/panel.crt
ssl_key=/etc/ssl/wpspoti/panel.key
monitoring_interval=60
CONF
chmod 600 ${PANEL_CONFIG}/wpspoti.conf
chown www-data:www-data ${PANEL_CONFIG}/wpspoti.conf

# ============================================================
# STEP 8: Configure Nginx
# ============================================================
log "ADIM 8/12: Nginx yapılandırılıyor..."

# Self-signed SSL sertifikası
mkdir -p /etc/ssl/wpspoti
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/ssl/wpspoti/panel.key \
    -out /etc/ssl/wpspoti/panel.crt \
    -subj "/CN=wpspoti-panel/O=Wpspoti/C=TR" 2>/dev/null

# Panel Nginx config
cat > /etc/nginx/sites-available/wpspoti-panel.conf <<NGINX
server {
    listen ${PANEL_PORT} ssl http2;
    server_name _;

    ssl_certificate /etc/ssl/wpspoti/panel.crt;
    ssl_certificate_key /etc/ssl/wpspoti/panel.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root ${PANEL_DIR};
    index index.php;

    client_max_body_size 256M;

    location ^~ /core/ {
        deny all;
        return 404;
    }

    location ~* \.(db|sqlite|conf|sql|sh|log)$ {
        deny all;
        return 404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ^~ /api/ {
        try_files \$uri =404;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    access_log ${PANEL_LOG}/access.log;
    error_log ${PANEL_LOG}/error.log;
}
NGINX

ln -sf /etc/nginx/sites-available/wpspoti-panel.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

nginx -t && systemctl reload nginx
systemctl enable nginx

# ============================================================
# STEP 9: Configure PHP-FPM
# ============================================================
log "ADIM 9/12: PHP-FPM yapılandırılıyor..."
PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"
if [ -f "$PHP_INI" ]; then
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 256M/' ${PHP_INI}
    sed -i 's/^post_max_size.*/post_max_size = 256M/' ${PHP_INI}
    sed -i 's/^memory_limit.*/memory_limit = 256M/' ${PHP_INI}
    sed -i 's/^max_execution_time.*/max_execution_time = 300/' ${PHP_INI}
    sed -i 's/^max_input_time.*/max_input_time = 300/' ${PHP_INI}
fi
systemctl restart php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

# ============================================================
# STEP 10: Configure MariaDB
# ============================================================
log "ADIM 10/12: MariaDB yapılandırılıyor..."
systemctl start mariadb
systemctl enable mariadb

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';" 2>/dev/null || true
mysql -u root -p"${DB_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -u root -p"${DB_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
mysql -u root -p"${DB_ROOT_PASS}" -e "FLUSH PRIVILEGES;" 2>/dev/null || true

# ============================================================
# STEP 11: Configure Firewall & Security
# ============================================================
log "ADIM 11/12: Güvenlik duvarı ve Fail2ban yapılandırılıyor..."
ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
ufw allow 22/tcp 2>/dev/null || true
ufw allow 80/tcp 2>/dev/null || true
ufw allow 443/tcp 2>/dev/null || true
ufw allow ${PANEL_PORT}/tcp 2>/dev/null || true
ufw allow 25/tcp 2>/dev/null || true
ufw allow 587/tcp 2>/dev/null || true
ufw allow 993/tcp 2>/dev/null || true
ufw allow 53 2>/dev/null || true
ufw allow 21/tcp 2>/dev/null || true
ufw allow 40000:50000/tcp 2>/dev/null || true
ufw --force enable 2>/dev/null || true

# Fail2ban
cat > /etc/fail2ban/jail.d/wpspoti.conf <<F2B
[wpspoti-panel]
enabled = true
port = ${PANEL_PORT}
filter = wpspoti-panel
logpath = ${PANEL_LOG}/panel.log
maxretry = 5
bantime = 3600
findtime = 600
F2B

cat > /etc/fail2ban/filter.d/wpspoti-panel.conf <<F2BF
[Definition]
failregex = ^.*LOGIN_FAILED.*ip=<HOST>.*$
ignoreregex =
F2BF

systemctl restart fail2ban 2>/dev/null || true
systemctl enable fail2ban 2>/dev/null || true

# Sudoers
cat > /etc/sudoers.d/wpspoti <<SUDOERS
www-data ALL=(ALL) NOPASSWD: /usr/sbin/nginx *
www-data ALL=(ALL) NOPASSWD: /bin/systemctl reload nginx
www-data ALL=(ALL) NOPASSWD: /bin/systemctl restart *
www-data ALL=(ALL) NOPASSWD: /bin/systemctl start *
www-data ALL=(ALL) NOPASSWD: /bin/systemctl stop *
www-data ALL=(ALL) NOPASSWD: /bin/systemctl is-active *
www-data ALL=(ALL) NOPASSWD: /usr/bin/certbot *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/ufw *
www-data ALL=(ALL) NOPASSWD: /bin/mkdir *
www-data ALL=(ALL) NOPASSWD: /bin/chown *
www-data ALL=(ALL) NOPASSWD: /bin/chmod *
www-data ALL=(ALL) NOPASSWD: /bin/rm *
www-data ALL=(ALL) NOPASSWD: /bin/cp *
www-data ALL=(ALL) NOPASSWD: /bin/mv *
www-data ALL=(ALL) NOPASSWD: /bin/ln *
www-data ALL=(ALL) NOPASSWD: /usr/bin/tee *
www-data ALL=(ALL) NOPASSWD: /usr/bin/crontab *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/useradd *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/userdel *
www-data ALL=(ALL) NOPASSWD: /usr/bin/passwd *
www-data ALL=(ALL) NOPASSWD: /usr/bin/fail2ban-client *
www-data ALL=(ALL) NOPASSWD: /usr/sbin/rndc *
www-data ALL=(ALL) NOPASSWD: /usr/bin/mysql *
www-data ALL=(ALL) NOPASSWD: /usr/bin/mysqladmin *
www-data ALL=(ALL) NOPASSWD: /usr/bin/mysqldump *
www-data ALL=(ALL) NOPASSWD: /usr/bin/postmap *
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/wp *
www-data ALL=(ALL) NOPASSWD: /var/wpspoti/scripts/*
www-data ALL=(ALL) NOPASSWD: /usr/bin/tar *
www-data ALL=(ALL) NOPASSWD: /usr/bin/zip *
www-data ALL=(ALL) NOPASSWD: /usr/bin/unzip *
www-data ALL=(ALL) NOPASSWD: /usr/bin/curl *
www-data ALL=(ALL) NOPASSWD: /usr/bin/wget *
SUDOERS
chmod 440 /etc/sudoers.d/wpspoti

# ============================================================
# STEP 12: Setup Monitoring Cron
# ============================================================
log "ADIM 12/12: Monitoring cron kuruluyor..."
(crontab -l 2>/dev/null; echo "* * * * * ${PANEL_DATA}/scripts/monitoring-collector.sh >/dev/null 2>&1") | sort -u | crontab -

# ============================================================
# DONE
# ============================================================
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo -e "${CYAN}========================================"
echo -e "  KURULUM TAMAMLANDI!"
echo -e "========================================${NC}"
echo ""
echo -e "${GREEN}Panel URL:${NC}  https://${SERVER_IP}:${PANEL_PORT}"
echo -e "${GREEN}Kullanıcı:${NC} admin"
echo -e "${GREEN}Şifre:${NC}     ${ADMIN_PASS}"
echo ""
echo -e "${GREEN}MariaDB Root Şifresi:${NC} ${DB_ROOT_PASS}"
echo ""
echo -e "${YELLOW}ÖNEMLİ: Bu bilgileri şimdi kaydedin!${NC}"
echo -e "${YELLOW}NOT: Self-signed SSL sertifikası kullanılıyor.${NC}"
echo -e "${YELLOW}Tarayıcıda güvenlik uyarısını kabul edin.${NC}"
echo ""

# Bilgileri dosyaya kaydet
cat > /root/.wpspoti_credentials <<CRED
========================================
Wpspoti Panel Credentials
========================================
Panel URL: https://${SERVER_IP}:${PANEL_PORT}
Admin User: admin
Admin Pass: ${ADMIN_PASS}
MariaDB Root: ${DB_ROOT_PASS}
Installed: $(date)
========================================
CRED
chmod 600 /root/.wpspoti_credentials
echo -e "${GREEN}Bilgiler /root/.wpspoti_credentials dosyasına kaydedildi.${NC}"
echo ""
