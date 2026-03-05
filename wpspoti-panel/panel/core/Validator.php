<?php
class Validator {
    public static function required(array $fields, array $source): array {
        $errors = [];
        foreach ($fields as $field) {
            if (!isset($source[$field]) || trim($source[$field]) === '') {
                $errors[] = "{$field} is required";
            }
        }
        return $errors;
    }

    public static function username(string $value): bool {
        return (bool) preg_match('/^[a-zA-Z0-9_]{3,32}$/', $value);
    }

    public static function password(string $value): bool {
        return strlen($value) >= 8;
    }

    public static function dbName(string $value): bool {
        return (bool) preg_match('/^[a-zA-Z0-9_]{1,64}$/', $value);
    }

    public static function cronField(string $value): bool {
        return (bool) preg_match('/^[\d\*\/\,\-]+$/', $value);
    }

    public static function port(string $value): bool {
        $port = (int)$value;
        return $port >= 1 && $port <= 65535;
    }

    public static function path(string $value): bool {
        return !str_contains($value, '..') && !str_contains($value, "\0");
    }

    public static function filename(string $value): bool {
        return (bool) preg_match('/^[a-zA-Z0-9._\-]+$/', $value) && !str_starts_with($value, '.');
    }
}
