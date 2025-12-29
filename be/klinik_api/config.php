<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if (!defined('DB_HOST')) {
    define('DB_HOST', getenv('DB_HOST') ?: '127.0.0.1');
    define('DB_NAME', getenv('DB_NAME') ?: 'klinik_rawat_jalan');
    define('DB_USER', getenv('DB_USER') ?: 'root');
    define('DB_PASS', getenv('DB_PASS') ?: 'a');
    define('ADMIN_TOKEN', getenv('ADMIN_TOKEN') ?: 'change-me-admin-token');
    define('ADMIN_USERNAME', getenv('ADMIN_USERNAME') ?: 'admin');
    define('ADMIN_PASSWORD_HASH', getenv('ADMIN_PASSWORD_HASH') ?: '$2y$10$7Kp5bUgHkdjP88Ea49X3Men/C06RaoXu1v1jxENdJqfhwF3EX8G7m');
}

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', DB_HOST, DB_NAME);
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
        } catch (PDOException $e) {
            respond([
                'success' => false,
                'message' => 'Gagal terhubung ke database',
                'detail' => $e->getMessage(),
            ], 500);
        }
    }
    return $pdo;
}

function readJsonBody(): array
{
    $content = file_get_contents('php://input') ?: '';
    $data = json_decode($content, true);
    return is_array($data) ? $data : [];
}

function respond(array $payload, int $statusCode = 200): void
{
    http_response_code($statusCode);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function requireMethod(string $method): void
{
    if (strtoupper($_SERVER['REQUEST_METHOD'] ?? '') !== strtoupper($method)) {
        respond([
            'success' => false,
            'message' => 'Metode HTTP tidak diizinkan',
        ], 405);
    }
}

function validateFields(array $payload, array $required): void
{
    $missing = array_filter($required, static fn ($field) => empty($payload[$field]) && $payload[$field] !== '0');
    if ($missing) {
        respond([
            'success' => false,
            'message' => 'Field wajib belum lengkap',
            'fields' => array_values($missing),
        ], 422);
    }
}

function getAuthorizationToken(): ?string
{
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (stripos($header, 'Bearer ') === 0) {
        return trim(substr($header, 7));
    }
    return $_SERVER['HTTP_X_ADMIN_TOKEN']
        ?? ($_GET['token'] ?? null);
}

function requireAdmin(): void
{
    $provided = getAuthorizationToken();
    if (!$provided || $provided !== ADMIN_TOKEN) {
        respond([
            'success' => false,
            'message' => 'Akses admin diperlukan',
        ], 401);
    }
}

function verifyAdminCredentials(string $username, string $password): bool
{
    return hash_equals(ADMIN_USERNAME, $username)
        && password_verify($password, ADMIN_PASSWORD_HASH);
}
