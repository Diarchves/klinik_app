<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $where = [];
        $params = [];

        if (!empty($_GET['id_rekam_medis'])) {
            $where[] = 'eo.id_rekam_medis = :id_rekam_medis';
            $params['id_rekam_medis'] = (int) $_GET['id_rekam_medis'];
        }
        if (!empty($_GET['id_obat'])) {
            $where[] = 'eo.id_obat = :id_obat';
            $params['id_obat'] = (int) $_GET['id_obat'];
        }

        if (!$where) {
            requireAdmin();
        }

        $sql = 'SELECT eo.id_entity,
                       eo.jumlah,
                       eo.id_rekam_medis,
                       eo.id_obat,
                       o.nama_obat,
                       o.jenis,
                       o.bentuk
                FROM entity_obat eo
                JOIN obat o ON eo.id_obat = o.id_obat';

        if ($where) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['id_rekam_medis', 'id_obat', 'jumlah']);

        $stmt = db()->prepare(
            'INSERT INTO entity_obat (id_rekam_medis, id_obat, jumlah)
             VALUES (:id_rekam_medis, :id_obat, :jumlah)'
        );
        $stmt->execute([
            'id_rekam_medis' => (int) $payload['id_rekam_medis'],
            'id_obat' => (int) $payload['id_obat'],
            'jumlah' => (int) $payload['jumlah'],
        ]);

        respond([
            'success' => true,
            'message' => 'Resep ditambahkan',
            'data' => ['id_entity' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_entity'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_entity wajib diisi'], 422);
        }

        $allowed = ['jumlah'];
        $data = array_intersect_key($payload, array_flip($allowed));

        if (!$data) {
            respond(['success' => false, 'message' => 'Tidak ada field yang diperbarui'], 400);
        }

        $stmt = db()->prepare('UPDATE entity_obat SET jumlah = :jumlah WHERE id_entity = :id');
        $stmt->execute([
            'jumlah' => (int) $data['jumlah'],
            'id' => $id,
        ]);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Resep tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Resep diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_entity'] ?? $_GET['id_entity'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_entity wajib diisi'], 422);
        }

        $stmt = db()->prepare('DELETE FROM entity_obat WHERE id_entity = :id');
        $stmt->execute(['id' => $id]);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Resep tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Resep dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
