<?php

require __DIR__ . '/config.php';

requireMethod('POST');
$payload = readJsonBody();
validateFields($payload, ['nik', 'nama', 'password']);

$nik = trim($payload['nik']);
$nama = trim($payload['nama']);
$password = $payload['password'];
$tanggalLahir = $payload['tanggal_lahir'] ?? null;
$alamat = $payload['alamat'] ?? null;
$noTelepon = $payload['no_telepon'] ?? null;

$hash = password_hash($password, PASSWORD_BCRYPT);

try {
    $stmt = db()->prepare(
        'INSERT INTO pasien (nik, nama, password, tanggal_lahir, alamat, no_telepon)
         VALUES (:nik, :nama, :password, :tanggal_lahir, :alamat, :no_telepon)'
    );
    $stmt->execute([
        'nik' => $nik,
        'nama' => $nama,
        'password' => $hash,
        'tanggal_lahir' => $tanggalLahir,
        'alamat' => $alamat,
        'no_telepon' => $noTelepon,
    ]);

    respond([
        'success' => true,
        'message' => 'Registrasi berhasil',
        'data' => [
            'id_pasien' => (int) db()->lastInsertId(),
            'nama' => $nama,
        ],
    ], 201);
} catch (PDOException $e) {
    if ($e->getCode() === '23000') {
        respond([
            'success' => false,
            'message' => 'NIK sudah terdaftar',
        ], 409);
    }

    respond([
        'success' => false,
        'message' => 'Gagal menyimpan data pasien',
        'detail' => $e->getMessage(),
    ], 500);
}
