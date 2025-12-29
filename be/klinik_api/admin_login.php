<?php

require __DIR__ . '/config.php';

requireMethod('POST');
$payload = readJsonBody();
validateFields($payload, ['username', 'password']);

$username = trim((string) $payload['username']);
$password = (string) $payload['password'];

if (!verifyAdminCredentials($username, $password)) {
    respond([
        'success' => false,
        'message' => 'Username atau password admin salah',
    ], 401);
}

respond([
    'success' => true,
    'token' => ADMIN_TOKEN,
]);
