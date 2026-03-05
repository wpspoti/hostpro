<?php
class Helpers {
    public static function formatBytes(int $bytes, int $precision = 2): string {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $factor = floor((strlen((string)$bytes) - 1) / 3);
        $factor = min($factor, count($units) - 1);
        return sprintf("%.{$precision}f %s", $bytes / pow(1024, $factor), $units[$factor]);
    }

    public static function timeAgo(string $datetime): string {
        $diff = time() - strtotime($datetime);
        if ($diff < 60) return $diff . 's ago';
        if ($diff < 3600) return floor($diff / 60) . 'm ago';
        if ($diff < 86400) return floor($diff / 3600) . 'h ago';
        return floor($diff / 86400) . 'd ago';
    }

    public static function generatePassword(int $length = 16): string {
        return bin2hex(random_bytes($length / 2));
    }

    public static function generateSalt(): string {
        $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_[]{}|;:,.<>?';
        $salt = '';
        for ($i = 0; $i < 64; $i++) {
            $salt .= $chars[random_int(0, strlen($chars) - 1)];
        }
        return $salt;
    }

    public static function renderTemplate(string $templateName, array $vars): string {
        $configDir = defined('WPSPOTI_CONFIG') ? WPSPOTI_CONFIG : '/etc/wpspoti';
        $templatePath = $configDir . '/templates/' . $templateName;
        if (!file_exists($templatePath)) {
            throw new RuntimeException("Template not found: {$templateName}");
        }
        $content = file_get_contents($templatePath);
        foreach ($vars as $key => $value) {
            $content = str_replace('{{' . $key . '}}', $value, $content);
        }
        return $content;
    }

    public static function getInput(): array {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (str_contains($contentType, 'application/json')) {
            $raw = file_get_contents('php://input');
            return json_decode($raw, true) ?? [];
        }
        return $_POST;
    }

    public static function getMimeType(string $filename): string {
        $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
        $types = [
            'html' => 'text/html', 'htm' => 'text/html', 'css' => 'text/css',
            'js' => 'application/javascript', 'json' => 'application/json',
            'xml' => 'text/xml', 'txt' => 'text/plain', 'md' => 'text/markdown',
            'php' => 'application/x-php', 'py' => 'text/x-python',
            'sh' => 'text/x-shellscript', 'sql' => 'text/x-sql',
            'png' => 'image/png', 'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg',
            'gif' => 'image/gif', 'svg' => 'image/svg+xml', 'ico' => 'image/x-icon',
            'pdf' => 'application/pdf', 'zip' => 'application/zip',
            'gz' => 'application/gzip', 'tar' => 'application/x-tar',
        ];
        return $types[$ext] ?? 'application/octet-stream';
    }
}
