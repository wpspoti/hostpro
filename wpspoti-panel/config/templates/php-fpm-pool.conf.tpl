[{{DOMAIN}}]
user = www-data
group = www-data
listen = /run/php/php{{PHP_VERSION}}-fpm-{{DOMAIN}}.sock
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 5
pm.max_requests = 500
php_admin_value[error_log] = /var/log/php/{{DOMAIN}}.error.log
php_admin_flag[log_errors] = on
php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M
php_value[memory_limit] = 256M
php_value[max_execution_time] = 300
