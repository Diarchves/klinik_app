<?php

require __DIR__ . '/config.php';

requireMethod('POST');
$payload = readJsonBody();
validateFields($payload, ['id_pasien', 'id_dokter', 'tanggal', 'jam']);

$idPasien = (int) $payload['id_pasien'];
$idDokter = (int) $payload['id_dokter'];
$tanggal = $payload['tanggal'];
$poli = $payload['poli'] ?? null;
$catatan = $payload['catatan'] ?? null;

$time = strtotime($payload['jam']);
if ($time === false) {
    respond([
        'success' => false,
        'message' => 'Format jam tidak valid',
    ], 422);
}
$waktu = date('H:i:s', $time);

$pdo = db();

try {
    $pdo->beginTransaction();

    $queueStmt = $pdo->prepare(
        'SELECT COALESCE(MAX(a.no_antrian), 0) + 1 AS next_queue
         FROM antrian a
         JOIN janji j ON a.id_janji = j.id_janji
         WHERE j.id_dokter = :id_dokter AND j.tanggal = :tanggal
         FOR UPDATE'
    );
    $queueStmt->execute([
        'id_dokter' => $idDokter,
        'tanggal' => $tanggal,
    ]);
    $nextQueue = (int) ($queueStmt->fetchColumn() ?: 1);

    $janjiStmt = $pdo->prepare(
        'INSERT INTO janji (id_pasien, id_dokter, poli, tanggal, waktu, status, catatan)
         VALUES (:id_pasien, :id_dokter, :poli, :tanggal, :waktu, :status, :catatan)'
    );
    $janjiStmt->execute([
        'id_pasien' => $idPasien,
        'id_dokter' => $idDokter,
        'poli' => $poli,
        'tanggal' => $tanggal,
        'waktu' => $waktu,
        'status' => 'menunggu',
        'catatan' => $catatan,
    ]);

    $idJanji = (int) $pdo->lastInsertId();

    $antrianStmt = $pdo->prepare(
        'INSERT INTO antrian (id_janji, no_antrian, status)
         VALUES (:id_janji, :no_antrian, :status)'
    );
    $antrianStmt->execute([
        'id_janji' => $idJanji,
        'no_antrian' => $nextQueue,
        'status' => 'menunggu',
    ]);

    $pdo->commit();

    respond([
        'success' => true,
        'message' => 'Janji berhasil dibuat',
        'data' => [
            'id_janji' => $idJanji,
            'no_antrian' => $nextQueue,
        ],
    ], 201);
} catch (Throwable $e) {
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    respond([
        'success' => false,
        'message' => 'Gagal membuat janji',
        'detail' => $e->getMessage(),
    ], 500);
}
