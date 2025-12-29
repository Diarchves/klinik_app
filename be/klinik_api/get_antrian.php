<?php

require __DIR__ . '/config.php';

requireMethod('GET');
$idPasien = isset($_GET['id_pasien']) ? (int) $_GET['id_pasien'] : 0;

if ($idPasien <= 0) {
    respond([
        'success' => false,
        'message' => 'Parameter id_pasien wajib diisi',
    ], 422);
}

$stmt = db()->prepare(
    'SELECT j.id_janji,
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
     JOIN dokter d ON j.id_dokter = d.id_dokter
     LEFT JOIN antrian a ON a.id_janji = j.id_janji
     WHERE j.id_pasien = :id_pasien
     ORDER BY j.tanggal DESC, j.waktu DESC'
);
$stmt->execute(['id_pasien' => $idPasien]);
$data = $stmt->fetchAll();

respond([
    'success' => true,
    'data' => $data,
]);
