<?php
class Security {
    public static function generateCsrfToken(): string {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }
        return $_SESSION['csrf_token'];
    }

    public static function verifyCsrf(): void {
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? $_POST['csrf_token'] ?? '';
        if (!hash_equals($_SESSION['csrf_token'] ?? '', $token)) {
            Response::error('Invalid CSRF token', 403);
        }
    }

    public static function sanitize(string $input): string {
        return htmlspecialchars(strip_tags(trim($input)), ENT_QUOTES, 'UTF-8');
    }

    public static function validateDomain(string $domain): bool {
        return (bool) preg_match(
            '/^(?:[a-zA-Z0-9](?:[a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/',
            $domain
        );
    }

    public static function validatePath(string $path, string $basePath): bool {
        $realPath = realpath($path);
        $realBase = realpath($basePath);
        return $realPath !== false && $realBase !== false && str_starts_with($realPath, $realBase);
    }

    public static function validateIp(string $ip): bool {
        return filter_var($ip, FILTER_VALIDATE_IP) !== false;
    }

    public static function validatePort(int $port): bool {
        return $port >= 1 && $port <= 65535;
    }

    public static function validateEmail(string $email): bool {
        return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
    }

    public static function isRateLimited(string $ip, int $maxAttempts = 5, int $windowMinutes = 15): bool {
        $db = Database::getInstance();
        $stmt = $db->prepare(
            "SELECT COUNT(*) FROM login_attempts
             WHERE ip_address = :ip AND success = 0
             AND attempted_at > datetime('now', :window)"
        );
        $stmt->execute([
            ':ip' => $ip,
            ':window' => "-{$windowMinutes} minutes"
        ]);
        return $stmt->fetchColumn() >= $maxAttempts;
    }

    public static function recordLoginAttempt(string $ip, string $username, bool $success): void {
        $db = Database::getInstance();
        $stmt = $db->prepare(
            "INSERT INTO login_attempts (ip_address, username, success) VALUES (:ip, :user, :success)"
        );
        $stmt->execute([':ip' => $ip, ':user' => $username, ':success' => $success ? 1 : 0]);
    }

    public static function getClientIp(): string {
        return $_SERVER['REMOTE_ADDR'] ?? '0.0.0.0';
    }
}
