<?php
require_once __DIR__ . '/../../core/bootstrap.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') Response::error('Method not allowed', 405);

$input = Helpers::getInput();
$domain = Security::sanitize($input['domain'] ?? '');
$phpVersion = Security::sanitize($input['php_version'] ?? '8.3');

if (!Security::validateDomain($domain)) Response::error('Invalid domain name');
if (!in_array($phpVersion, ['8.1','8.2','8.3'])) Response::error('Invalid PHP version');

$db = Database::getInstance();
$stmt = $db->prepare("SELECT id FROM sites WHERE domain = :d");
$stmt->execute([':d' => $domain]);
if ($stmt->fetch()) Response::error('Domain already exists');

$docRoot = "/var/www/{$domain}/public";
Shell::sudo('mkdir', ['-p', $docRoot]);
Shell::sudo('chown', ['-R', 'www-data:www-data', "/var/www/{$domain}"]);

$configDir = defined('WPSPOTI_CONFIG') ? dirname(WPSPOTI_CONFIG) : '/etc/wpspoti';
$template = @file_get_contents($configDir . '/templates/nginx-vhost.conf.tpl');
if (!$template) $template = "server {\n    listen 80;\n    server_name {$domain} www.{$domain};\n    root {$docRoot};\n    index index.php index.html;\n    location / { try_files \$uri \$uri/ /index.php?\$args; }\n    location ~ \\.php$ { include snippets/fastcgi-php.conf; fastcgi_pass unix:/run/php/php{$phpVersion}-fpm.sock; }\n}";
else {
    $template = str_replace(['{{DOMAIN}}','{{DOCUMENT_ROOT}}','{{PHP_VERSION}}'], [$domain,$docRoot,$phpVersion], $template);
}

$tmpFile = "/tmp/wpspoti-vhost-{$domain}.conf";
file_put_contents($tmpFile, $template);
$vhostPath = "/etc/nginx/sites-available/{$domain}.conf";
Shell::sudo('mv', [$tmpFile, $vhostPath]);
Shell::sudo('ln', ['-sf', $vhostPath, "/etc/nginx/sites-enabled/{$domain}.conf"]);

$test = Shell::sudo('nginx', ['-t']);
if (!$test['success']) {
    Shell::sudo('rm', ['-f', "/etc/nginx/sites-enabled/{$domain}.conf"]);
    Shell::sudo('rm', ['-f', $vhostPath]);
    Response::error('Nginx config test failed: ' . $test['output']);
}
Shell::sudo('systemctl', ['reload', 'nginx']);

$defaultHtml = "<html><head><title>Welcome to {$domain}</title></head><body><h1>Welcome to {$domain}</h1><p>Site created by Wpspoti Panel</p></body></html>";
$tmpIndex = "/tmp/wpspoti-index-{$domain}.html";
file_put_contents($tmpIndex, $defaultHtml);
Shell::sudo('mv', [$tmpIndex, "{$docRoot}/index.html"]);
Shell::sudo('chown', ['www-data:www-data', "{$docRoot}/index.html"]);

$stmt = $db->prepare("INSERT INTO sites (domain, document_root, php_version, nginx_config_path, created_by) VALUES (:d,:dr,:pv,:np,:cb)");
$stmt->execute([':d'=>$domain,':dr'=>$docRoot,':pv'=>$phpVersion,':np'=>$vhostPath,':cb'=>$_SESSION['user_id']]);

Logger::activity('site.create', $domain);
Response::success(['site_id' => $db->lastInsertId()], "Site {$domain} created");
