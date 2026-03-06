<?php
require_once __DIR__ . '/../../core/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$username = $_SESSION['username'] ?? 'unknown';
Auth::logout();
Logger::activity('logout', $username);

Response::success([], 'Logged out successfully');
