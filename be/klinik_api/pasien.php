<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
$selectColumns = 'id_pasien, nama, nik, tanggal_lahir, alamat, no_telepon';

switch ($method) {
    case 'GET':
        $id = isset($_GET['id']) ? (int) $_GET['id'] : null;
        if ($id) {
            $stmt = db()->prepare("SELECT $selectColumns FROM pasien WHERE id_pasien = :id");
            $stmt->execute(['id' => $id]);
            $pasien = $stmt->fetch();
            if (!$pasien) {
                respond(['success' => false, 'message' => 'Pasien tidak ditemukan'], 404);
            }
            respond(['success' => true, 'data' => $pasien]);
        }

        $stmt = db()->query("SELECT $selectColumns FROM pasien ORDER BY nama");
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['nik', 'nama', 'password']);

        $stmt = db()->prepare(
            'INSERT INTO pasien (nik, nama, password, tanggal_lahir, alamat, no_telepon)
             VALUES (:nik, :nama, :password, :tanggal_lahir, :alamat, :no_telepon)'
        );
        try {
            $stmt->execute([
                'nik' => $payload['nik'],
                'nama' => $payload['nama'],
                'password' => password_hash($payload['password'], PASSWORD_BCRYPT),
                'tanggal_lahir' => $payload['tanggal_lahir'] ?? null,
                'alamat' => $payload['alamat'] ?? null,
                'no_telepon' => $payload['no_telepon'] ?? null,
            ]);
        } catch (PDOException $e) {
            if ($e->getCode() === '23000') {
                respond(['success' => false, 'message' => 'NIK sudah terdaftar'], 409);
            }
            respond(['success' => false, 'message' => 'Gagal menambah pasien', 'detail' => $e->getMessage()], 500);
        }

        respond([
            'success' => true,
            'message' => 'Pasien berhasil ditambahkan',
            'data' => ['id_pasien' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_pasien'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'ID pasien wajib diisi'], 422);
        }

        $allowed = ['nama', 'nik', 'tanggal_lahir', 'alamat', 'no_telepon'];
        $data = array_intersect_key($payload, array_flip($allowed));
        if (!empty($payload['password'])) {
            $data['password'] = password_hash($payload['password'], PASSWORD_BCRYPT);
        }

        if (!$data) {
            respond(['success' => false, 'message' => 'Tidak ada field yang diperbarui'], 400);
        }

        $setClauses = [];
        $params = [];
        $index = 0;
        foreach ($data as $column => $value) {
            $param = ":field{$index}";
            $setClauses[] = "$column = $param";
            $params[$param] = $value;
            $index++;
        }
        $params[':id'] = $id;

        $sql = 'UPDATE pasien SET ' . implode(', ', $setClauses) . ' WHERE id_pasien = :id';
        $stmt = db()->prepare($sql);
        try {
            $stmt->execute($params);
        } catch (PDOException $e) {
            if ($e->getCode() === '23000') {
                respond(['success' => false, 'message' => 'NIK sudah digunakan'], 409);
            }
            respond(['success' => false, 'message' => 'Gagal memperbarui pasien', 'detail' => $e->getMessage()], 500);
        }

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Pasien tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Data pasien diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_pasien'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'ID pasien wajib diisi'], 422);
        }

        $stmt = db()->prepare('DELETE FROM pasien WHERE id_pasien = :id');
        try {
            $stmt->execute(['id' => $id]);
        } catch (PDOException $e) {
            respond([
                'success' => false,
                'message' => 'Gagal menghapus pasien (kemungkinan masih terkait data lain)',
                'detail' => $e->getMessage(),
            ], 409);
        }

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Pasien tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Pasien dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
