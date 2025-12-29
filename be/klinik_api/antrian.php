<?php

require __DIR__ . '/config.php';

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $where = [];
        $params = [];

        if (!empty($_GET['id_dokter'])) {
            $where[] = 'j.id_dokter = :id_dokter';
            $params['id_dokter'] = (int) $_GET['id_dokter'];
        }
        if (!empty($_GET['tanggal'])) {
            $where[] = 'j.tanggal = :tanggal';
            $params['tanggal'] = $_GET['tanggal'];
        }
        if (!empty($_GET['status'])) {
            $where[] = 'a.status = :status';
            $params['status'] = $_GET['status'];
        }

        if (!$where) {
            requireAdmin();
        }

        $sql = 'SELECT a.id_antrian,
                       a.no_antrian,
                       a.status,
                       j.id_janji,
                       j.tanggal,
                       j.waktu,
                       j.poli,
                       p.id_pasien,
                       p.nama AS nama_pasien,
                       d.id_dokter,
                       d.nama AS nama_dokter
                FROM antrian a
                JOIN janji j ON a.id_janji = j.id_janji
                JOIN pasien p ON j.id_pasien = p.id_pasien
                JOIN dokter d ON j.id_dokter = d.id_dokter';

        if ($where) {
            $sql .= ' WHERE ' . implode(' AND ', $where);
        }

        $sql .= ' ORDER BY j.tanggal ASC, a.no_antrian ASC';

        $stmt = db()->prepare($sql);
        $stmt->execute($params);
        respond(['success' => true, 'data' => $stmt->fetchAll()]);

    case 'PUT':
    case 'PATCH':
        requireAdmin();
        $payload = readJsonBody();
        $idAntrian = (int) ($payload['id_antrian'] ?? 0);
        if ($idAntrian <= 0) {
            respond(['success' => false, 'message' => 'id_antrian wajib diisi'], 422);
        }

        $allowed = ['status', 'no_antrian'];
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
        $params[':id'] = $idAntrian;

        $sql = 'UPDATE antrian SET ' . implode(', ', $setClauses) . ' WHERE id_antrian = :id';
        $stmt = db()->prepare($sql);
        $stmt->execute($params);

        if ($stmt->rowCount() === 0) {
            respond(['success' => false, 'message' => 'Antrian tidak ditemukan atau tidak ada perubahan'], 404);
        }

        respond(['success' => true, 'message' => 'Antrian diperbarui']);

    default:
        respond([
            'success' => false,
            'message' => 'Metode tidak dikenali',
        ], 405);
}
