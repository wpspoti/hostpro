server {
    listen 80;
    server_name {{DOMAIN}} www.{{DOMAIN}};

    root {{DOCUMENT_ROOT}};
    index index.php index.html index.htm;

    client_max_body_size 64M;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php{{PHP_VERSION}}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public";
    }

    access_log /var/log/nginx/{{DOMAIN}}.access.log;
    error_log /var/log/nginx/{{DOMAIN}}.error.log;
}
