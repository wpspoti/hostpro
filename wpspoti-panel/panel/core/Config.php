<?php
class Config {
    private static ?Config $instance = null;
    private array $data = [];

    private function __construct(string $path) {
        if (file_exists($path)) {
            $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '' || $line[0] === '#') continue;
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) {
                    $this->data[trim($parts[0])] = trim($parts[1]);
                }
            }
        }
    }

    public static function load(string $path): self {
        if (self::$instance === null) {
            self::$instance = new self($path);
        }
        return self::$instance;
    }

    public static function getInstance(): self {
        return self::$instance;
    }

    public function get(string $key, string $default = ''): string {
        return $this->data[$key] ?? $default;
    }

    public function set(string $key, string $value): void {
        $this->data[$key] = $value;
    }

    public function all(): array {
        return $this->data;
    }
}
