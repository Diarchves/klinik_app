<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $id = isset($_GET['id']) ? (int) $_GET['id'] : null;
        if ($id) {
            $stmt = db()->prepare('SELECT * FROM dokter WHERE id_dokter = :id');
            $stmt->execute(['id' => $id]);
            $dokter = $stmt->fetch();
            if (!$dokter) {
                respond(['success' => false, 'message' => 'Dokter tidak ditemukan'], 404);
            }
            respond(['success' => true, 'data' => $dokter]);
        }

        $stmt = db()->query('SELECT * FROM dokter ORDER BY nama');
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['nama', 'spesialisasi']);

        $stmt = db()->prepare(
            'INSERT INTO dokter (nama, spesialisasi, no_telepon, jadwal_praktik)
             VALUES (:nama, :spesialisasi, :no_telepon, :jadwal)'
        );
        $stmt->execute([
            'nama' => $payload['nama'],
            'spesialisasi' => $payload['spesialisasi'],
            'no_telepon' => $payload['no_telepon'] ?? null,
            'jadwal' => $payload['jadwal_praktik'] ?? null,
        ]);

        respond([
            'success' => true,
            'message' => 'Dokter berhasil ditambahkan',
            'data' => ['id_dokter' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_dokter'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'ID dokter wajib diisi'], 422);
        }

        $allowed = ['nama', 'spesialisasi', 'no_telepon', 'jadwal_praktik'];
        $data = array_intersect_key($payload, array_flip($allowed));
        if (!$data) {
            respond(['success' => false, 'message' => 'Tidak ada field yang diperbarui'], 400);
        }

        $setClauses = [];
        foreach (array_keys($data) as $index => $column) {
            $param = ":field{$index}";
            $setClauses[] = "$column = $param";
            $data[$param] = $data[$column];
            unset($data[$column]);
        }
        $data[':id'] = $id;

        $sql = 'UPDATE dokter SET ' . implode(', ', $setClauses) . ' WHERE id_dokter = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($data);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Dokter tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Data dokter diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_dokter'] ?? $_GET['id'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'ID dokter wajib diisi'], 422);
        }

        $stmt = db()->prepare('DELETE FROM dokter WHERE id_dokter = :id');
        $stmt->execute(['id' => $id]);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Dokter tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Dokter dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
