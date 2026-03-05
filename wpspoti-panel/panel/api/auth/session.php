<?php
require_once __DIR__ . '/../../core/bootstrap.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

$user = Auth::currentUser();

if (!$user) {
    Response::error('Not authenticated', 401);
}

Response::success([
    'user' => $user,
]);
