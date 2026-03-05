<?php
class Response {
    public static function success(array $data = [], string $message = 'OK'): never {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'csrf_token' => Security::generateCsrfToken()
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function error(string $message, int $httpCode = 400): never {
        http_response_code($httpCode);
        echo json_encode([
            'success' => false,
            'message' => $message,
            'csrf_token' => Security::generateCsrfToken()
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function paginated(array $items, int $total, int $page, int $perPage, string $message = 'OK'): never {
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $items,
            'pagination' => [
                'total' => $total,
                'page' => $page,
                'per_page' => $perPage,
                'total_pages' => ceil($total / $perPage)
            ],
            'csrf_token' => Security::generateCsrfToken()
        ], JSON_UNESCAPED_UNICODE);
        exit;
    }
}
