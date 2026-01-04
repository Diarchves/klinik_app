<?php

require __DIR__ . '/config.php';

const LOW_STOCK_THRESHOLD = 10;
const AUTOMATED_REPORT_TYPES = ['kunjungan', 'penggunaan', 'kinerja'];

function isAdminRequest(): bool
{
    $token = getAuthorizationToken();
    return $token && $token === ADMIN_TOKEN;
}

function resolvePeriodeRange(?string $periode): array
{
    if (!$periode) {
        return [null, null, 'Semua periode'];
    }
    $periode = trim($periode);
    if (preg_match('/^\d{4}-\d{2}$/', $periode)) {
        $start = $periode . '-01';
        $date = DateTimeImmutable::createFromFormat('Y-m-d', $start) ?: new DateTimeImmutable($start);
        $end = $date->format('Y-m-t');
        return [$start, $end, $date->format('F Y')];
    }
    if (preg_match('/^\d{4}$/', $periode)) {
        $date = DateTimeImmutable::createFromFormat('Y', $periode) ?: new DateTimeImmutable($periode . '-01-01');
        return [
            $periode . '-01-01',
            $periode . '-12-31',
            'Tahun ' . $date->format('Y'),
        ];
    }
    return [null, null, $periode];
}

function buildDateWhereClause(string $column, ?string $start, ?string $end): array
{
    if ($start && $end) {
        return ['WHERE ' . $column . ' BETWEEN :start AND :end', ['start' => $start, 'end' => $end]];
    }
    return ['', []];
}

function formatInteger(int $value): string
{
    return number_format($value, 0, ',', '.');
}

function formatDecimal(float $value, int $precision = 1): string
{
    return number_format($value, $precision, ',', '.');
}

function formatPercent(float $value): string
{
    return formatDecimal($value) . '%';
}

function buildLaporanResponse(
    string $jenis,
    string $periodeLabel,
    string $ringkasan,
    array $statistik = [],
    ?string $detailTitle = null,
    array $detailRows = [],
    array $catatan = []
): array {
    return [
        'jenis' => $jenis,
        'periode' => $periodeLabel,
        'isi_laporan' => $ringkasan,
        'statistik' => $statistik,
        'detail_title' => $detailTitle,
        'detail_rows' => $detailRows,
        'catatan' => $catatan,
        'generated_at' => (new DateTimeImmutable())->format(DateTimeInterface::ATOM),
    ];
}

function generateKunjunganReport(?string $periode): array
{
    [$start, $end, $label] = resolvePeriodeRange($periode);
    [$whereSql, $params] = buildDateWhereClause('j.tanggal', $start, $end);

    $stmt = db()->prepare(
        "SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN LOWER(COALESCE(j.status, '')) = 'selesai' THEN 1 ELSE 0 END) AS selesai,
            SUM(CASE WHEN LOWER(COALESCE(j.status, '')) = 'batal' THEN 1 ELSE 0 END) AS batal,
            SUM(CASE WHEN LOWER(COALESCE(j.status, '')) NOT IN ('selesai', 'batal') THEN 1 ELSE 0 END) AS aktif
        FROM janji j
        $whereSql"
    );
    $stmt->execute($params);
    $stats = $stmt->fetch() ?: [];

    $total = (int) ($stats['total'] ?? 0);
    $selesai = (int) ($stats['selesai'] ?? 0);
    $batal = (int) ($stats['batal'] ?? 0);
    $aktif = (int) ($stats['aktif'] ?? 0);
    $completionRate = $total > 0 ? round(($selesai / $total) * 100, 1) : 0.0;

    $stmtTop = db()->prepare(
        "SELECT
            COALESCE(d.nama, 'Belum ditentukan') AS dokter,
            COUNT(*) AS total,
            SUM(CASE WHEN LOWER(COALESCE(j.status, '')) = 'selesai' THEN 1 ELSE 0 END) AS selesai
        FROM janji j
        LEFT JOIN dokter d ON j.id_dokter = d.id_dokter
        $whereSql
        GROUP BY j.id_dokter
        ORDER BY total DESC
        LIMIT 5"
    );
    $stmtTop->execute($params);
    $detailRows = array_map(static function (array $row): array {
        return [
            'label' => $row['dokter'],
            'value' => formatInteger((int) ($row['total'] ?? 0)) . ' janji',
            'note' => 'Selesai ' . formatInteger((int) ($row['selesai'] ?? 0)),
        ];
    }, $stmtTop->fetchAll() ?: []);

    $ringkasan = sprintf(
        'Tercatat %s janji pada %s dengan %s selesai (%s), %s masih aktif, dan %s dibatalkan.',
        formatInteger($total),
        $label,
        formatInteger($selesai),
        formatPercent($completionRate),
        formatInteger($aktif),
        formatInteger($batal)
    );

    $statistik = [
        ['label' => 'Total Janji', 'value' => formatInteger($total)],
        ['label' => 'Selesai', 'value' => formatInteger($selesai)],
        ['label' => 'Aktif', 'value' => formatInteger($aktif)],
        ['label' => 'Batal', 'value' => formatInteger($batal)],
    ];

    return buildLaporanResponse(
        'kunjungan',
        $label,
        $ringkasan,
        $statistik,
        '5 Dokter dengan kunjungan terbanyak',
        $detailRows
    );
}

function generatePenggunaanObatReport(?string $periode): array
{
    [$start, $end, $label] = resolvePeriodeRange($periode);
    [$whereSql, $params] = buildDateWhereClause('j.tanggal', $start, $end);
    $whereSql = $whereSql ?: '';

    $stmt = db()->prepare(
        "SELECT
            COALESCE(SUM(eo.jumlah), 0) AS total_keluar,
            COUNT(DISTINCT eo.id_obat) AS varian
        FROM entity_obat eo
        JOIN rekam_medis rm ON eo.id_rekam_medis = rm.id_rekam_medis
        JOIN janji j ON rm.id_janji = j.id_janji
        $whereSql"
    );
    $stmt->execute($params);
    $stats = $stmt->fetch() ?: [];
    $totalKeluar = (int) ($stats['total_keluar'] ?? 0);
    $varian = (int) ($stats['varian'] ?? 0);
    $rataRata = $varian > 0 ? round($totalKeluar / $varian, 1) : 0.0;

    $stmtTop = db()->prepare(
        "SELECT
            COALESCE(o.nama_obat, CONCAT('ID ', eo.id_obat)) AS nama,
            SUM(eo.jumlah) AS total
        FROM entity_obat eo
        LEFT JOIN obat o ON eo.id_obat = o.id_obat
        JOIN rekam_medis rm ON eo.id_rekam_medis = rm.id_rekam_medis
        JOIN janji j ON rm.id_janji = j.id_janji
        $whereSql
        GROUP BY eo.id_obat
        ORDER BY total DESC
        LIMIT 5"
    );
    $stmtTop->execute($params);
    $detailRows = array_map(static function (array $row): array {
        return [
            'label' => $row['nama'],
            'value' => formatInteger((int) ($row['total'] ?? 0)) . ' dosis',
        ];
    }, $stmtTop->fetchAll() ?: []);

    $lowStockStmt = db()->prepare(
        'SELECT nama_obat, stok FROM obat WHERE stok IS NOT NULL AND stok <= :threshold ORDER BY stok ASC LIMIT 5'
    );
    $lowStockStmt->execute(['threshold' => LOW_STOCK_THRESHOLD]);
    $lowStocks = $lowStockStmt->fetchAll() ?: [];
    $catatan = array_map(static function (array $row): string {
        return sprintf('%s tersisa %s unit', $row['nama_obat'], formatInteger((int) $row['stok']));
    }, $lowStocks);

    $ringkasan = sprintf(
        'Sebanyak %s dosis obat digunakan pada %s dengan %s jenis obat terpakai (rata-rata %s dosis per obat).',
        formatInteger($totalKeluar),
        $label,
        formatInteger($varian),
        formatDecimal($rataRata)
    );

    $statistik = [
        ['label' => 'Total Dosis Keluar', 'value' => formatInteger($totalKeluar)],
        ['label' => 'Variasi Obat', 'value' => formatInteger($varian)],
        ['label' => 'Rata-rata per Obat', 'value' => formatDecimal($rataRata)],
    ];

    return buildLaporanResponse(
        'penggunaan',
        $label,
        $ringkasan,
        $statistik,
        'Obat paling sering digunakan',
        $detailRows,
        $catatan
    );
}

function generateKinerjaLayananReport(?string $periode): array
{
    [$start, $end, $label] = resolvePeriodeRange($periode);
    [$whereSql, $params] = buildDateWhereClause('j.tanggal', $start, $end);

    $stmt = db()->prepare(
        "SELECT
            COUNT(*) AS total,
            SUM(CASE WHEN LOWER(COALESCE(a.status, '')) = 'selesai' THEN 1 ELSE 0 END) AS selesai,
            SUM(CASE WHEN LOWER(COALESCE(a.status, '')) = 'dipanggil' THEN 1 ELSE 0 END) AS dipanggil,
            SUM(CASE WHEN LOWER(COALESCE(a.status, '')) = 'menunggu' THEN 1 ELSE 0 END) AS menunggu
        FROM antrian a
        JOIN janji j ON a.id_janji = j.id_janji
        $whereSql"
    );
    $stmt->execute($params);
    $stats = $stmt->fetch() ?: [];
    $total = (int) ($stats['total'] ?? 0);
    $selesai = (int) ($stats['selesai'] ?? 0);
    $dipanggil = (int) ($stats['dipanggil'] ?? 0);
    $menunggu = (int) ($stats['menunggu'] ?? 0);
    $completionRate = $total > 0 ? round(($selesai / $total) * 100, 1) : 0.0;

    $stmtTop = db()->prepare(
        "SELECT
            COALESCE(d.nama, 'Belum ditentukan') AS dokter,
            SUM(CASE WHEN LOWER(COALESCE(a.status, '')) = 'selesai' THEN 1 ELSE 0 END) AS selesai,
            COUNT(*) AS total
        FROM antrian a
        JOIN janji j ON a.id_janji = j.id_janji
        LEFT JOIN dokter d ON j.id_dokter = d.id_dokter
        $whereSql
        GROUP BY j.id_dokter
        HAVING total > 0
        ORDER BY selesai DESC, total DESC
        LIMIT 5"
    );
    $stmtTop->execute($params);
    $detailRows = array_map(static function (array $row): array {
        return [
            'label' => $row['dokter'],
            'value' => formatInteger((int) ($row['selesai'] ?? 0)) . ' selesai',
            'note' => formatInteger((int) ($row['total'] ?? 0)) . ' tiket diproses',
        ];
    }, $stmtTop->fetchAll() ?: []);

    $ringkasan = sprintf(
        'Sebanyak %s tiket antrian tercatat pada %s dengan tingkat penyelesaian %s. %s tiket sudah dipanggil dan %s masih menunggu layanan.',
        formatInteger($total),
        $label,
        formatPercent($completionRate),
        formatInteger($dipanggil),
        formatInteger($menunggu)
    );

    $statistik = [
        ['label' => 'Total Tiket', 'value' => formatInteger($total)],
        ['label' => 'Selesai', 'value' => formatInteger($selesai)],
        ['label' => 'Dipanggil', 'value' => formatInteger($dipanggil)],
        ['label' => 'Menunggu', 'value' => formatInteger($menunggu)],
        ['label' => 'Tingkat Penyelesaian', 'value' => formatPercent($completionRate)],
    ];

    $catatan = $menunggu > 0
        ? [sprintf('%s tiket masih menunggu giliran, prioritaskan pemanggilan.', formatInteger($menunggu))]
        : ['Semua tiket sudah terselesaikan pada periode ini.'];

    return buildLaporanResponse(
        'kinerja',
        $label,
        $ringkasan,
        $statistik,
        'Performa dokter berdasarkan tiket selesai',
        $detailRows,
        $catatan
    );
}

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

switch ($method) {
    case 'GET':
        $jenisParam = isset($_GET['jenis']) ? strtolower(trim((string) $_GET['jenis'])) : null;
        $periodeParam = $_GET['periode'] ?? null;

        $automated = [];
        if ($jenisParam && in_array($jenisParam, AUTOMATED_REPORT_TYPES, true)) {
            if ($jenisParam === 'kunjungan') {
                $automated[] = generateKunjunganReport($periodeParam);
            } elseif ($jenisParam === 'penggunaan') {
                $automated[] = generatePenggunaanObatReport($periodeParam);
            } else {
                $automated[] = generateKinerjaLayananReport($periodeParam);
            }
        }

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

        if (!$where && !$automated) {
            requireAdmin();
        }

        $manualData = [];
        $shouldFetchManual = $where !== [] || isAdminRequest();
        if ($shouldFetchManual) {
            $sql = 'SELECT * FROM laporan';
            if ($where) {
                $sql .= ' WHERE ' . implode(' AND ', $where);
            }
            $sql .= ' ORDER BY id_laporan DESC';

            $stmt = db()->prepare($sql);
            $stmt->execute($params);
            $manualData = $stmt->fetchAll();
        }

        respond(['success' => true, 'data' => array_merge($automated, $manualData)]);

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
