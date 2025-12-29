<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $where = [];
        $params = [];

        if (!empty($_GET['id_laporan'])) {
            $where[] = 'id_laporan = :id_laporan';
            $params['id_laporan'] = (int) $_GET['id_laporan'];
        }
        if (!empty($_GET['periode'])) {
            $where[] = 'periode = :periode';
            $params['periode'] = $_GET['periode'];
        }
        if (!empty($_GET['jenis'])) {
            $where[] = 'jenis = :jenis';
            $params['jenis'] = $_GET['jenis'];
        }

        if (!$where) {
            requireAdmin();
        }

        $sql = 'SELECT * FROM laporan';
        if ($where) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }
        $sql .= ' ORDER BY id_laporan DESC';

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['periode', 'jenis', 'isi_laporan']);

        $stmt = db()->prepare(
            'INSERT INTO laporan (periode, jenis, isi_laporan)
             VALUES (:periode, :jenis, :isi_laporan)'
        );
        $stmt->execute([
            'periode' => $payload['periode'],
            'jenis' => $payload['jenis'],
            'isi_laporan' => $payload['isi_laporan'],
        ]);

        respond([
            'success' => true,
            'message' => 'Laporan dibuat',
            'data' => ['id_laporan' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_laporan'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_laporan wajib diisi'], 422);
        }

        $allowed = ['periode', 'jenis', 'isi_laporan'];
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
            $params[$param] = $value;
            $idx++;
        }
        $params[':id'] = $id;

        $sql = 'UPDATE laporan SET ' . implode(', ', $setClauses) . ' WHERE id_laporan = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Laporan tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Laporan diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_laporan'] ?? $_GET['id_laporan'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_laporan wajib diisi'], 422);
        }

        $stmt = db()->prepare('DELETE FROM laporan WHERE id_laporan = :id');
        $stmt->execute(['id' => $id]);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Laporan tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Laporan dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
