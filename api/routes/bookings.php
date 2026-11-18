<?php
function shape_booking(array $b): array {
    $d = q_one('SELECT name, region, image_url FROM destinations WHERE id = ?', [$b['destination_id']]);
    $g = $b['guide_id'] ? q_one('SELECT name FROM guides WHERE id = ?', [$b['guide_id']]) : null;
    return ['id' => (int)$b['id'], 'code' => $b['code'], 'destination_id' => (int)$b['destination_id'],
        'destination_name' => $d['name'], 'region' => $d['region'], 'image_url' => abs_url($d['image_url']),
        'guide_id' => $b['guide_id'] ? (int)$b['guide_id'] : null, 'guide_name' => $g['name'] ?? null,
        'visit_date' => $b['visit_date'], 'qty' => (int)$b['qty'], 'subtotal' => (int)$b['subtotal'],
        'guide_fee' => (int)$b['guide_fee'], 'service_fee' => (int)$b['service_fee'], 'total' => (int)$b['total'],
        'status' => $b['status'], 'payment_method' => $b['payment_method'], 'payment_ref' => $b['payment_ref'],
        'paid_at' => $b['paid_at'], 'created_at' => $b['created_at']];
}

route('POST', '/bookings', function () {
    $u = auth(); $b = body(); need($b, ['destination_id', 'visit_date']);
    $d = q_one('SELECT * FROM destinations WHERE id = ?', [$b['destination_id']]);
    if (!$d) fail(404, 'Destinasi tidak ditemukan');
    if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $b['visit_date']) || days_until($b['visit_date']) < 0) fail(422, 'Tanggal kunjungan tidak valid');
    $qty = max(1, min(20, (int)($b['qty'] ?? 1)));
    $guideFee = 0; $gid = null;
    if (!empty($b['guide_id'])) {
        $g = q_one('SELECT * FROM guides WHERE id = ?', [$b['guide_id']]);
        if (!$g) fail(404, 'Pemandu tidak ditemukan');
        $gid = (int)$g['id']; $guideFee = (int)$g['price_idr'];
    }
    $sub = (int)$d['price_idr'] * $qty; $svc = (int)cfg('service_fee');
    $code = 'WSN-' . strtoupper(substr(bin2hex(random_bytes(4)), 0, 6));
    $id = q_ins('INSERT INTO bookings (code,user_id,destination_id,guide_id,visit_date,qty,subtotal,guide_fee,service_fee,total,status) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
        [$code, $u['id'], $d['id'], $gid, $b['visit_date'], $qty, $sub, $guideFee, $svc, $sub + $guideFee + $svc, 'pending']);
    send(shape_booking(q_one('SELECT * FROM bookings WHERE id = ?', [$id])), 201);
});

route('GET', '/bookings', function () {
    $u = auth();
    $sql = 'SELECT * FROM bookings WHERE user_id = ?'; $a = [$u['id']];
    if (!empty($_GET['status'])) { $sql .= ' AND status = ?'; $a[] = $_GET['status']; }
    send(array_map('shape_booking', q_all($sql . ' ORDER BY id DESC', $a)));
});

route('GET', '/bookings/{id}', function ($p) {
    $u = auth();
    $b = q_one('SELECT * FROM bookings WHERE id = ? AND user_id = ?', [$p['id'], $u['id']]);
    if (!$b) fail(404, 'Pesanan tidak ditemukan');
    send(shape_booking($b));
});

// Pembayaran disimulasikan. Ganti bagian "gateway" dengan Midtrans/Xendit di produksi.
route('POST', '/bookings/{id}/pay', function ($p) {
    $u = auth(); $b = body(); need($b, ['method']);
    if (!in_array($b['method'], ['qris', 'va', 'ewallet', 'card'], true)) fail(422, 'Metode pembayaran tidak dikenal');
    $bk = q_one('SELECT * FROM bookings WHERE id = ? AND user_id = ?', [$p['id'], $u['id']]);
    if (!$bk) fail(404, 'Pesanan tidak ditemukan');
    if ($bk['status'] === 'paid') send(shape_booking($bk));
    if ($bk['status'] === 'cancelled') fail(409, 'Pesanan sudah dibatalkan');
    // --- gateway hook (simulasi) ---
    $ref = strtoupper($b['method']) . '-' . strtoupper(substr(bin2hex(random_bytes(5)), 0, 10));
    q_run("UPDATE bookings SET status='paid', payment_method=?, payment_ref=?, paid_at=? WHERE id=?",
        [$b['method'], $ref, date('Y-m-d H:i:s'), $bk['id']]);
    $bk = q_one('SELECT * FROM bookings WHERE id = ?', [$bk['id']]);
    $d = q_one('SELECT name FROM destinations WHERE id = ?', [$bk['destination_id']]);
    notify((int)$u['id'], 'Pembayaran berhasil', "Tiket {$d['name']} ({$bk['code']}) sudah lunas.", 'payment', 'pay-' . $bk['id']);
    sync_booking_to_plans($bk, $d['name']);
    send(shape_booking($bk));
});

route('POST', '/bookings/{id}/cancel', function ($p) {
    $u = auth();
    $bk = q_one('SELECT * FROM bookings WHERE id = ? AND user_id = ?', [$p['id'], $u['id']]);
    if (!$bk) fail(404, 'Pesanan tidak ditemukan');
    if ($bk['status'] !== 'pending') fail(409, 'Hanya pesanan belum bayar yang bisa dibatalkan');
    q_run("UPDATE bookings SET status='cancelled' WHERE id = ?", [$bk['id']]);
    send(shape_booking(q_one('SELECT * FROM bookings WHERE id = ?', [$bk['id']])));
});
