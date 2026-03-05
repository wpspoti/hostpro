#!/bin/bash
set -e
apt update
apt install -y nginx php-fpm mariadb-server certbot python3-certbot-nginx ufw unzip zip

ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable

mkdir -p /var/www/wpspoti
cp -r panel/* /var/www/wpspoti/

cat > /etc/nginx/sites-available/wpspoti <<CONF
server {
    listen 80;
    server_name _;
    root /var/www/wpspoti;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm.sock;
    }
}
CONF

ln -s /etc/nginx/sites-available/wpspoti /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "Kurulum tamamlandı: http://SUNUCU_IP"
