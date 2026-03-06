<?php
require_once __DIR__ . '/../../core/bootstrap.php';
if ($_SERVER['REQUEST_METHOD'] !== 'GET') Response::error('Method not allowed', 405);
$db = Database::getInstance();
$sites = $db->query("SELECT * FROM sites ORDER BY created_at DESC")->fetchAll();
Response::success(['sites' => $sites]);
