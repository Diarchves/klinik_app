<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $stmt = db()->query('SELECT * FROM obat ORDER BY nama_obat');
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['nama_obat']);

        $stmt = db()->prepare(
            'INSERT INTO obat (nama_obat, jenis, bentuk, stok)
             VALUES (:nama_obat, :jenis, :bentuk, :stok)'
        );
        $stmt->execute([
            'nama_obat' => $payload['nama_obat'],
            'jenis' => $payload['jenis'] ?? null,
            'bentuk' => $payload['bentuk'] ?? null,
            'stok' => isset($payload['stok']) ? (int) $payload['stok'] : null,
        ]);

        respond([
            'success' => true,
            'message' => 'Obat ditambahkan',
            'data' => ['id_obat' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_obat'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_obat wajib diisi'], 422);
        }

        $allowed = ['nama_obat', 'jenis', 'bentuk', 'stok'];
        $data = array_intersect_key($payload, array_flip($allowed));

        if (!$data) {
            respond(['success' => false, 'message' => 'Tidak ada field yang diperbarui'], 400);
        }

        $setClauses = [];
        $params = [];
        $idx = 0;
        foreach ($data as $column => $value) {
            $param = ":field{$idx}";
            $setClauses[] = "$column = $param";
            $params[$param] = $column === 'stok' ? (int) $value : $value;
            $idx++;
        }
        $params[':id'] = $id;

        $sql = 'UPDATE obat SET ' . implode(', ', $setClauses) . ' WHERE id_obat = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Obat tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Data obat diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_obat'] ?? $_GET['id_obat'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_obat wajib diisi'], 422);
        }

        $pdo = db();
        $pdo->beginTransaction();
        $pdo->prepare('DELETE eo FROM entity_obat eo WHERE eo.id_obat = :id')->execute(['id' => $id]);
        $stmt = $pdo->prepare('DELETE FROM obat WHERE id_obat = :id');
        $stmt->execute(['id' => $id]);
        $pdo->commit();

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Obat tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Obat dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
