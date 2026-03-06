<?php
require_once __DIR__ . '/../../core/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    Response::error('Method not allowed', 405);
}

$input = Helpers::getInput();
$currentPassword = $input['current_password'] ?? '';
$newPassword = $input['new_password'] ?? '';

if (empty($currentPassword) || empty($newPassword)) {
    Response::error('Current password and new password are required');
}

if (strlen($newPassword) < 8) {
    Response::error('New password must be at least 8 characters');
}

$userId = $_SESSION['user_id'];
$username = $_SESSION['username'];

if (!Auth::changePassword($userId, $currentPassword, $newPassword)) {
    Logger::activity('password_change_failed', $username, 'Invalid current password');
    Response::error('Current password is incorrect', 401);
}

Logger::activity('password_changed', $username);

Response::success([], 'Password changed successfully');
