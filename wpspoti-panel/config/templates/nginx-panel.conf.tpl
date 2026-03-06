server {
    listen {{PANEL_PORT}} ssl http2;
    server_name _;

    ssl_certificate /etc/ssl/wpspoti/panel.crt;
    ssl_certificate_key /etc/ssl/wpspoti/panel.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root {{PANEL_DIR}};
    index index.php;

    client_max_body_size 256M;

    # Protect core directory
    location ^~ /core/ {
        deny all;
        return 404;
    }

    # Protect sensitive files
    location ~* \.(db|sqlite|conf|sql|sh|log)$ {
        deny all;
        return 404;
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php{{PHP_VERSION}}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    # API endpoints
    location ^~ /api/ {
        try_files $uri =404;
    }

    # Static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # SPA fallback
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    access_log /var/log/wpspoti/access.log;
    error_log /var/log/wpspoti/error.log;
}
