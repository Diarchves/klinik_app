<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $where = [];
        $params = [];

        if (!empty($_GET['id_pasien'])) {
            $where[] = 'j.id_pasien = :id_pasien';
            $params['id_pasien'] = (int) $_GET['id_pasien'];
        }
        if (!empty($_GET['id_dokter'])) {
            $where[] = 'j.id_dokter = :id_dokter';
            $params['id_dokter'] = (int) $_GET['id_dokter'];
        }
        if (!empty($_GET['status'])) {
            $where[] = 'j.status = :status';
            $params['status'] = $_GET['status'];
        }
        if (!empty($_GET['tanggal'])) {
            $where[] = 'j.tanggal = :tanggal';
            $params['tanggal'] = $_GET['tanggal'];
        }

        if (!$where) {
            requireAdmin(); // tanpa filter hanya boleh admin
        }

        $sql = 'SELECT j.id_janji,
                       j.id_pasien,
                       p.nama AS nama_pasien,
                       j.id_dokter,
                       d.nama AS nama_dokter,
                       d.spesialisasi,
                       j.poli,
                       j.tanggal,
                       j.waktu,
                       j.status,
                       j.catatan,
                       a.no_antrian
                FROM janji j
                JOIN pasien p ON j.id_pasien = p.id_pasien
                JOIN dokter d ON j.id_dokter = d.id_dokter
                LEFT JOIN antrian a ON a.id_janji = j.id_janji';

        if ($where) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        $sql .= ' ORDER BY j.tanggal DESC, j.waktu DESC';

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $idJanji = (int) ($payload['id_janji'] ?? 0);
        if ($idJanji <= 0) {
            respond(['success' => false, 'message' => 'id_janji wajib diisi'], 422);
        }

        $allowed = ['poli', 'tanggal', 'waktu', 'status', 'catatan', 'id_dokter'];
        $data = array_intersect_key($payload, array_flip($allowed));

        if (isset($data['waktu'])) {
            $time = strtotime($data['waktu']);
            if ($time === false) {
                respond(['success' => false, 'message' => 'Format waktu tidak valid'], 422);
            }
            $data['waktu'] = date('H:i:s', $time);
        }

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
        $params[':id'] = $idJanji;

        $sql = 'UPDATE janji SET ' . implode(', ', $setClauses) . ' WHERE id_janji = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Janji tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Janji diperbarui']);

    case 'DELETE':
        requireAdmin();
        $payload = readJsonBody();
        $idJanji = (int) ($payload['id_janji'] ?? $_GET['id_janji'] ?? 0);
        if ($idJanji <= 0) {
            respond(['success' => false, 'message' => 'id_janji wajib diisi'], 422);
        }

        $pdo = db();
        $pdo->beginTransaction();
        $pdo->prepare('DELETE FROM antrian WHERE id_janji = :id')->execute(['id' => $idJanji]);
        $stmt = $pdo->prepare('DELETE FROM janji WHERE id_janji = :id');
        $stmt->execute(['id' => $idJanji]);
        $pdo->commit();

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Janji tidak ditemukan'], 404);
        }

        respond(['success' => true, 'message' => 'Janji dihapus']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
