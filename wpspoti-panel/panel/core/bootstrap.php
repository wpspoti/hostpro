<?php
define('WPSPOTI_ROOT', dirname(__DIR__));
define('WPSPOTI_CORE', __DIR__);
define('WPSPOTI_CONFIG', '/etc/wpspoti/wpspoti.conf');
define('WPSPOTI_DB', '/var/wpspoti/panel.db');
define('WPSPOTI_LOG', '/var/log/wpspoti/panel.log');

spl_autoload_register(function ($class) {
    $file = WPSPOTI_CORE . '/' . $class . '.php';
    if (file_exists($file)) {
        require_once $file;
    }
});

$config = Config::load(WPSPOTI_CONFIG);
$db = Database::getInstance(WPSPOTI_DB);

ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_samesite', 'Strict');
ini_set('session.use_strict_mode', '1');
ini_set('session.gc_maxlifetime', '1800');
session_name('WPSPOTI_SID');

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// CSRF check for mutating requests
if (in_array($_SERVER['REQUEST_METHOD'], ['POST', 'PUT', 'DELETE'])) {
    $currentPath = str_replace(WPSPOTI_ROOT, '', $_SERVER['SCRIPT_FILENAME']);
    $csrfExempt = ['/api/auth/login.php'];
    if (!in_array($currentPath, $csrfExempt)) {
        Security::verifyCsrf();
    }
}

// Auth check (skip for public endpoints)
$publicEndpoints = ['/api/auth/login.php', '/api/auth/session.php'];
$currentPath = str_replace(WPSPOTI_ROOT, '', $_SERVER['SCRIPT_FILENAME']);
if (!in_array($currentPath, $publicEndpoints)) {
    Auth::requireLogin();
}

header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('X-XSS-Protection: 1; mode=block');
