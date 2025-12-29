<?php

require __DIR__ . '/config.php';

requireAdmin();

$pdo = db();

$totalPasien = (int) $pdo->query('SELECT COUNT(*) FROM pasien')->fetchColumn();
$totalDokter = (int) $pdo->query('SELECT COUNT(*) FROM dokter')->fetchColumn();

$statusStmt = $pdo->query(
    "SELECT status, COUNT(*) AS jumlah FROM janji GROUP BY status"
);
$statusBreakdown = $statusStmt->fetchAll();

$today = date('Y-m-d');
$janjiHariIniStmt = $pdo->prepare(
    'SELECT COUNT(*) FROM janji WHERE tanggal = :today'
);
$janjiHariIniStmt->execute(['today' => $today]);
$janjiHariIni = (int) $janjiHariIniStmt->fetchColumn();

$menungguStmt = $pdo->prepare(
    "SELECT COUNT(*) FROM janji WHERE status = 'menunggu'"
);
$menungguStmt->execute();
$menunggu = (int) $menungguStmt->fetchColumn();

$nextJanjiStmt = $pdo->prepare(
    'SELECT j.id_janji,
            j.tanggal,
            j.waktu,
            j.status,
            p.nama AS nama_pasien,
            d.nama AS nama_dokter,
            a.no_antrian
     FROM janji j
     JOIN pasien p ON j.id_pasien = p.id_pasien
     JOIN dokter d ON j.id_dokter = d.id_dokter
     LEFT JOIN antrian a ON a.id_janji = j.id_janji
     WHERE j.tanggal > :today
        OR (j.tanggal = :today AND j.waktu >= :now)
     ORDER BY j.tanggal ASC, j.waktu ASC
     LIMIT 5'
);
$nextJanjiStmt->execute([
    'today' => $today,
    'now' => date('H:i:s'),
]);
$nextJanji = $nextJanjiStmt->fetchAll();

$lowStockStmt = $pdo->query(
    'SELECT id_obat, nama_obat, stok FROM obat
     WHERE stok IS NOT NULL
     ORDER BY stok ASC
     LIMIT 5'
);
$lowStock = $lowStockStmt->fetchAll();

respond([
    'success' => true,
    'data' => [
        'total_pasien' => $totalPasien,
        'total_dokter' => $totalDokter,
        'janji_menunggu' => $menunggu,
        'janji_hari_ini' => $janjiHariIni,
        'status_breakdown' => $statusBreakdown,
        'next_janji' => $nextJanji,
        'obat_stok_terendah' => $lowStock,
    ],
]);
