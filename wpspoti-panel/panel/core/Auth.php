<?php
class Auth {
    public static function requireLogin(): void {
        if (empty($_SESSION['user_id'])) {
            Response::error('Authentication required', 401);
        }
        $db = Database::getInstance();
        $stmt = $db->prepare("SELECT id FROM sessions WHERE id = :sid AND user_id = :uid");
        $stmt->execute([':sid' => session_id(), ':uid' => $_SESSION['user_id']]);
        if (!$stmt->fetch()) {
            session_destroy();
            Response::error('Session expired', 401);
        }
        // Update last activity
        $stmt = $db->prepare("UPDATE sessions SET last_activity = datetime('now') WHERE id = :sid");
        $stmt->execute([':sid' => session_id()]);
    }

    public static function login(string $username, string $password): array|false {
        $db = Database::getInstance();
        $stmt = $db->prepare("SELECT * FROM users WHERE username = :u AND is_active = 1");
        $stmt->execute([':u' => $username]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return false;
        }

        session_regenerate_id(true);
        $_SESSION['user_id'] = $user['id'];
        $_SESSION['username'] = $user['username'];
        $_SESSION['role'] = $user['role'];
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));

        // Record session
        $stmt = $db->prepare(
            "INSERT INTO sessions (id, user_id, ip_address, user_agent) VALUES (:sid, :uid, :ip, :ua)"
        );
        $stmt->execute([
            ':sid' => session_id(),
            ':uid' => $user['id'],
            ':ip' => Security::getClientIp(),
            ':ua' => $_SERVER['HTTP_USER_AGENT'] ?? ''
        ]);

        // Update last login
        $stmt = $db->prepare("UPDATE users SET last_login_at = datetime('now'), last_login_ip = :ip WHERE id = :id");
        $stmt->execute([':ip' => Security::getClientIp(), ':id' => $user['id']]);

        return $user;
    }

    public static function logout(): void {
        $db = Database::getInstance();
        if (!empty($_SESSION['user_id'])) {
            $stmt = $db->prepare("DELETE FROM sessions WHERE id = :sid");
            $stmt->execute([':sid' => session_id()]);
        }
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000,
                $params['path'], $params['domain'], $params['secure'], $params['httponly']
            );
        }
        session_destroy();
    }

    public static function currentUser(): ?array {
        if (empty($_SESSION['user_id'])) return null;
        return [
            'id' => $_SESSION['user_id'],
            'username' => $_SESSION['username'],
            'role' => $_SESSION['role']
        ];
    }

    public static function changePassword(int $userId, string $currentPassword, string $newPassword): bool {
        $db = Database::getInstance();
        $stmt = $db->prepare("SELECT password_hash FROM users WHERE id = :id");
        $stmt->execute([':id' => $userId]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($currentPassword, $user['password_hash'])) {
            return false;
        }

        $newHash = password_hash($newPassword, PASSWORD_ARGON2ID);
        $stmt = $db->prepare("UPDATE users SET password_hash = :hash, updated_at = datetime('now') WHERE id = :id");
        $stmt->execute([':hash' => $newHash, ':id' => $userId]);

        return true;
    }
}
