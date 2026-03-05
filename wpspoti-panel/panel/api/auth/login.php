<?php
require_once __DIR__ . '/../../core/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$input = Helpers::getInput();
$username = Security::sanitize($input['username'] ?? '');
$password = $input['password'] ?? '';

if (empty($username) || empty($password)) {
    Response::error('Username and password are required');
}

$ip = Security::getClientIp();

if (Security::isRateLimited($ip)) {
    Response::error('Too many login attempts. Please try again later.', 429);
}

$user = Auth::login($username, $password);

if (!$user) {
    Security::recordLoginAttempt($ip, $username, false);
    Logger::activity('login_failed', $username, "IP: {$ip}");
    Response::error('Invalid username or password', 401);
}

Security::recordLoginAttempt($ip, $username, true);
Logger::activity('login_success', $username, "IP: {$ip}");

Response::success([
    'user' => [
        'id' => $user['id'],
        'username' => $user['username'],
        'role' => $user['role'],
    ],
    'csrf_token' => Security::generateCsrfToken(),
]);
