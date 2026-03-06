<?php
class Database {
    private static ?PDO $instance = null;
    private static string $dbPath = '';

    public static function getInstance(string $path = ''): PDO {
        if ($path) self::$dbPath = $path;
        if (self::$instance === null) {
            self::$instance = new PDO('sqlite:' . self::$dbPath, null, null, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
            self::$instance->exec('PRAGMA journal_mode=WAL');
            self::$instance->exec('PRAGMA foreign_keys=ON');
        }
        return self::$instance;
    }
}
