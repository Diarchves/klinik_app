<?php

require __DIR__ . '/config.php';

requireMethod('GET');

$idDokter = isset($_GET['id_dokter']) ? (int) $_GET['id_dokter'] : 0;
if ($idDokter <= 0) {
    respond([
        'success' => false,
        'message' => 'Parameter id_dokter wajib diisi',
    ], 422);
}

$tanggalMulai = $_GET['tanggal_mulai'] ?? $_GET['tanggal'] ?? date('Y-m-d');
$tanggalSelesai = $_GET['tanggal_selesai'] ?? $tanggalMulai;

$stmtDokter = db()->prepare('SELECT id_dokter, nama, spesialisasi, jadwal_praktik FROM dokter WHERE id_dokter = :id');
$stmtDokter->execute(['id' => $idDokter]);
$dokter = $stmtDokter->fetch();

if (!$dokter) {
    respond([
        'success' => false,
        'message' => 'Dokter tidak ditemukan',
    ], 404);
}

$stmt = db()->prepare(
    'SELECT j.id_janji,
            j.tanggal,
            j.waktu,
            j.status,
            a.no_antrian,
            p.nama AS nama_pasien
     FROM janji j
     LEFT JOIN antrian a ON a.id_janji = j.id_janji
     JOIN pasien p ON p.id_pasien = j.id_pasien
     WHERE j.id_dokter = :id_dokter
       AND j.tanggal BETWEEN :mulai AND :selesai
     ORDER BY j.tanggal ASC, j.waktu ASC'
);
$stmt->execute([
    'id_dokter' => $idDokter,
    'mulai' => $tanggalMulai,
    'selesai' => $tanggalSelesai,
]);

respond([
    'success' => true,
    'data' => [
        'dokter' => $dokter,
        'rentang_tanggal' => [
            'mulai' => $tanggalMulai,
            'selesai' => $tanggalSelesai,
        ],
        'booking' => $stmt->fetchAll(),
    ],
]);
