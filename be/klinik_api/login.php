<?php

require __DIR__ . '/config.php';

requireMethod('POST');
$payload = readJsonBody();
validateFields($payload, ['nik', 'password']);

$stmt = db()->prepare('SELECT id_pasien, nama, password FROM pasien WHERE nik = :nik LIMIT 1');
$stmt->execute(['nik' => $payload['nik']]);
$user = $stmt->fetch();

if (!$user || !password_verify($payload['password'], $user['password'] ?? '')) {
    respond([
        'success' => false,
        'message' => 'NIK atau password salah',
    ], 401);
}

respond([
    'success' => true,
    'data' => [
        'id_pasien' => (int) $user['id_pasien'],
        'nama' => $user['nama'],
    ],
]);
