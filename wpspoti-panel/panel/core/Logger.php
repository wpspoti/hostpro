<?php
class Logger {
    public static function log(string $level, string $message): void {
        $logFile = defined('WPSPOTI_LOG') ? WPSPOTI_LOG : '/var/log/wpspoti/panel.log';
        $timestamp = date('Y-m-d H:i:s');
        $ip = $_SERVER['REMOTE_ADDR'] ?? 'cli';
        $line = "[{$timestamp}] [{$level}] [ip={$ip}] {$message}\n";
        @file_put_contents($logFile, $line, FILE_APPEND | LOCK_EX);
    }

    public static function activity(string $action, string $target = '', string $details = ''): void {
        self::log('activity', "{$action} | {$target} | {$details}");

        try {
            $db = Database::getInstance();
            $stmt = $db->prepare(
                "INSERT INTO activity_log (user_id, action, target, details, ip_address)
                 VALUES (:uid, :action, :target, :details, :ip)"
            );
            $stmt->execute([
                ':uid' => $_SESSION['user_id'] ?? null,
                ':action' => $action,
                ':target' => $target,
                ':details' => $details,
                ':ip' => Security::getClientIp()
            ]);
        } catch (Exception $e) {
            self::log('error', "Failed to write activity log: " . $e->getMessage());
        }
    }
}
