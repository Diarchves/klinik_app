<?php

require __DIR__ . '/config.php';

requireMethod('GET');

$stmt = db()->query('SELECT id_dokter, nama, spesialisasi, no_telepon, jadwal_praktik FROM dokter ORDER BY nama');
$rows = $stmt->fetchAll();

respond($rows);
