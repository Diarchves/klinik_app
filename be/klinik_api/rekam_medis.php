<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $where = [];
        $params = [];

        if (!empty($_GET['id_rekam_medis'])) {
            $where[] = 'r.id_rekam_medis = :id_rekam_medis';
            $params['id_rekam_medis'] = (int) $_GET['id_rekam_medis'];
        }
        if (!empty($_GET['id_janji'])) {
            $where[] = 'r.id_janji = :id_janji';
            $params['id_janji'] = (int) $_GET['id_janji'];
        }
        if (!empty($_GET['id_pasien'])) {
            $where[] = 'j.id_pasien = :id_pasien';
            $params['id_pasien'] = (int) $_GET['id_pasien'];
        }

        if (!$where) {
            requireAdmin();
        }

        $sql = 'SELECT r.id_rekam_medis,
                       r.diagnosa,
                       r.tindakan,
                       r.catatan,
                       j.id_janji,
                       j.tanggal,
                       j.waktu,
                       j.status,
                       p.id_pasien,
                       p.nama AS nama_pasien,
                       d.id_dokter,
                       d.nama AS nama_dokter
                FROM rekam_medis r
                JOIN janji j ON r.id_janji = j.id_janji
                JOIN pasien p ON j.id_pasien = p.id_pasien
                JOIN dokter d ON j.id_dokter = d.id_dokter';

        if ($where) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        $sql .= ' ORDER BY j.tanggal DESC, j.waktu DESC';

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'POST':
        requireAdmin();
        $payload = readJsonBody();
        validateFields($payload, ['id_janji']);

        $stmtCheck = db()->prepare('SELECT id_rekam_medis FROM rekam_medis WHERE id_janji = :id_janji');
        $stmtCheck->execute(['id_janji' => (int) $payload['id_janji']]);
        if ($stmtCheck->fetch()) {
            respond([
                'success' => false,
                'message' => 'Rekam medis untuk janji ini sudah ada',
            ], 409);
        }

        $stmt = db()->prepare(
            'INSERT INTO rekam_medis (id_janji, diagnosa, tindakan, catatan)
             VALUES (:id_janji, :diagnosa, :tindakan, :catatan)'
        );
        $stmt->execute([
            'id_janji' => (int) $payload['id_janji'],
            'diagnosa' => $payload['diagnosa'] ?? null,
            'tindakan' => $payload['tindakan'] ?? null,
            'catatan' => $payload['catatan'] ?? null,
        ]);

        respond([
            'success' => true,
            'message' => 'Rekam medis dibuat',
            'data' => ['id_rekam_medis' => (int) db()->lastInsertId()],
        ], 201);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_rekam_medis'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_rekam_medis wajib diisi'], 422);
        }

        $allowed = ['diagnosa', 'tindakan', 'catatan'];
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

        $sql = 'UPDATE rekam_medis SET ' . implode(', ', $setClauses) . ' WHERE id_rekam_medis = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Rekam medis tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Rekam medis diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $id = (int) ($payload['id_rekam_medis'] ?? $_GET['id_rekam_medis'] ?? 0);
        if ($id <= 0) {
            respond(['success' => false, 'message' => 'id_rekam_medis wajib diisi'], 422);
        }

        $pdo = db();
        $pdo->beginTransaction();
        $pdo->prepare('DELETE FROM entity_obat WHERE id_rekam_medis = :id')->execute(['id' => $id]);
        $stmt = $pdo->prepare('DELETE FROM rekam_medis WHERE id_rekam_medis = :id');
        $stmt->execute(['id' => $id]);
        $pdo->commit();

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Rekam medis tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Rekam medis dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
