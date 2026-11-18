<?php
function own_plan(int $id): array {
    $u = auth();
    $p = q_one('SELECT * FROM plans WHERE id = ? AND user_id = ?', [$id, $u['id']]);
    if (!$p) fail(404, 'Rencana tidak ditemukan');
    return $p;
}

function plan_summary(array $p): array {
    $spent = (int)q_one('SELECT COALESCE(SUM(amount),0) s FROM plan_expenses WHERE plan_id = ?', [$p['id']])['s'];
    $items = q_one('SELECT COUNT(*) c, COALESCE(SUM(done),0) d FROM plan_items WHERE plan_id = ?', [$p['id']]);
    return ['id' => (int)$p['id'], 'folder' => $p['folder'], 'name' => $p['name'], 'start_date' => $p['start_date'], 'end_date' => $p['end_date'],
        'budget_idr' => (int)$p['budget_idr'], 'spent_idr' => $spent, 'remaining_idr' => (int)$p['budget_idr'] - $spent,
        'remind_depart' => (bool)$p['remind_depart'], 'remind_pack' => (bool)$p['remind_pack'],
        'days_until' => days_until($p['start_date']), 'items_total' => (int)$items['c'], 'items_done' => (int)$items['d']];
}

function plan_detail(array $p): array {
    $s = plan_summary($p);
    $s['items'] = array_map(fn($i) => ['id' => (int)$i['id'], 'day_no' => (int)$i['day_no'], 'time_label' => $i['time_label'], 'title' => $i['title'],
        'note' => $i['note'], 'kind' => $i['kind'], 'destination_id' => $i['destination_id'] ? (int)$i['destination_id'] : null,
        'booking_id' => $i['booking_id'] ? (int)$i['booking_id'] : null, 'done' => (bool)$i['done']],
        q_all('SELECT * FROM plan_items WHERE plan_id = ? ORDER BY day_no, time_label, id', [$p['id']]));
    $s['expenses'] = array_map(fn($e) => ['id' => (int)$e['id'], 'title' => $e['title'], 'amount' => (int)$e['amount'], 'booking_id' => $e['booking_id'] ? (int)$e['booking_id'] : null],
        q_all('SELECT * FROM plan_expenses WHERE plan_id = ? ORDER BY id', [$p['id']]));
    $s['packing'] = array_map(fn($i) => ['id' => (int)$i['id'], 'label' => $i['label'], 'done' => (bool)$i['done']],
        q_all('SELECT * FROM packing_items WHERE plan_id = ? ORDER BY id', [$p['id']]));
    return $s;
}

// Dipanggil setelah pembayaran: centang tiket/pemandu di rencana yang memuat destinasi + tanggal sama, catat pengeluaran.
function sync_booking_to_plans(array $bk, string $destName): void {
    $plans = q_all('SELECT * FROM plans WHERE user_id = ?', [$bk['user_id']]);
    foreach ($plans as $pl) {
        $has = q_one('SELECT id FROM plan_items WHERE plan_id = ? AND destination_id = ?', [$pl['id'], $bk['destination_id']]);
        if (!$has) continue;
        q_run("UPDATE plan_items SET done = 1, booking_id = ? WHERE plan_id = ? AND destination_id = ? AND kind IN ('ticket','guide')",
            [$bk['id'], $pl['id'], $bk['destination_id']]);
        if (!q_one('SELECT id FROM plan_expenses WHERE plan_id = ? AND booking_id = ?', [$pl['id'], $bk['id']]))
            q_ins('INSERT INTO plan_expenses (plan_id, title, amount, booking_id) VALUES (?,?,?,?)', [$pl['id'], "Tiket $destName ({$bk['code']})", (int)$bk['total'], $bk['id']]);
        notify((int)$bk['user_id'], 'Rencana diperbarui', "Tiket $destName otomatis dicentang di \"{$pl['name']}\" dan budget berkurang.", 'plan', 'sync-' . $bk['id'] . '-' . $pl['id']);
    }
}

route('GET', '/plans', function () {
    $u = auth();
    send(array_map('plan_summary', q_all('SELECT * FROM plans WHERE user_id = ? ORDER BY folder, id DESC', [$u['id']])));
});

route('POST', '/plans', function () {
    $u = auth(); $b = body(); need($b, ['name']);
    $id = q_ins('INSERT INTO plans (user_id, folder, name, start_date, end_date, budget_idr) VALUES (?,?,?,?,?,?)',
        [$u['id'], trim($b['folder'] ?? 'Liburan') ?: 'Liburan', trim($b['name']), $b['start_date'] ?? null, $b['end_date'] ?? null, max(0, (int)($b['budget_idr'] ?? 0))]);
    foreach (['KTP / Paspor', 'Power bank', 'Jaket', 'Sepatu nyaman', 'Obat pribadi', 'Botol minum'] as $l)
        q_ins('INSERT INTO packing_items (plan_id, label) VALUES (?,?)', [$id, $l]);
    send(plan_detail(q_one('SELECT * FROM plans WHERE id = ?', [$id])), 201);
});

route('GET', '/plans/{id}', function ($p) { send(plan_detail(own_plan((int)$p['id']))); });

route('PUT', '/plans/{id}', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body();
    q_run('UPDATE plans SET folder=?, name=?, start_date=?, end_date=?, budget_idr=?, remind_depart=?, remind_pack=? WHERE id=?', [
        $b['folder'] ?? $pl['folder'], $b['name'] ?? $pl['name'], array_key_exists('start_date', $b) ? $b['start_date'] : $pl['start_date'],
        array_key_exists('end_date', $b) ? $b['end_date'] : $pl['end_date'], (int)($b['budget_idr'] ?? $pl['budget_idr']),
        isset($b['remind_depart']) ? (int)(bool)$b['remind_depart'] : $pl['remind_depart'],
        isset($b['remind_pack']) ? (int)(bool)$b['remind_pack'] : $pl['remind_pack'], $pl['id']]);
    send(plan_detail(q_one('SELECT * FROM plans WHERE id = ?', [$pl['id']])));
});

route('DELETE', '/plans/{id}', function ($p) { $pl = own_plan((int)$p['id']); q_run('DELETE FROM plans WHERE id = ?', [$pl['id']]); send(['ok' => true]); });

route('POST', '/plans/{id}/items', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body(); need($b, ['title']);
    $id = q_ins('INSERT INTO plan_items (plan_id, day_no, time_label, title, note, kind, destination_id) VALUES (?,?,?,?,?,?,?)',
        [$pl['id'], max(1, (int)($b['day_no'] ?? 1)), $b['time_label'] ?? '08.00', trim($b['title']), $b['note'] ?? null,
         in_array($b['kind'] ?? 'activity', ['activity', 'food', 'ticket', 'guide', 'stay'], true) ? ($b['kind'] ?? 'activity') : 'activity', $b['destination_id'] ?? null]);
    send(plan_detail($pl), 201);
});

route('PATCH', '/plans/{id}/items/{item}', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body();
    $it = q_one('SELECT * FROM plan_items WHERE id = ? AND plan_id = ?', [$p['item'], $pl['id']]);
    if (!$it) fail(404, 'Item tidak ditemukan');
    q_run('UPDATE plan_items SET title=?, time_label=?, day_no=?, note=?, done=? WHERE id=?', [
        $b['title'] ?? $it['title'], $b['time_label'] ?? $it['time_label'], (int)($b['day_no'] ?? $it['day_no']),
        array_key_exists('note', $b) ? $b['note'] : $it['note'], isset($b['done']) ? (int)(bool)$b['done'] : $it['done'], $it['id']]);
    send(plan_detail($pl));
});

route('DELETE', '/plans/{id}/items/{item}', function ($p) {
    $pl = own_plan((int)$p['id']); q_run('DELETE FROM plan_items WHERE id = ? AND plan_id = ?', [$p['item'], $pl['id']]); send(plan_detail($pl));
});

route('POST', '/plans/{id}/expenses', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body(); need($b, ['title', 'amount']);
    q_ins('INSERT INTO plan_expenses (plan_id, title, amount) VALUES (?,?,?)', [$pl['id'], trim($b['title']), max(0, (int)$b['amount'])]);
    send(plan_detail($pl), 201);
});
route('DELETE', '/plans/{id}/expenses/{eid}', function ($p) {
    $pl = own_plan((int)$p['id']); q_run('DELETE FROM plan_expenses WHERE id = ? AND plan_id = ?', [$p['eid'], $pl['id']]); send(plan_detail($pl));
});

route('POST', '/plans/{id}/packing', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body(); need($b, ['label']);
    q_ins('INSERT INTO packing_items (plan_id, label) VALUES (?,?)', [$pl['id'], trim($b['label'])]); send(plan_detail($pl), 201);
});
route('PATCH', '/plans/{id}/packing/{pid}', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body();
    q_run('UPDATE packing_items SET done = ? WHERE id = ? AND plan_id = ?', [(int)(bool)($b['done'] ?? 0), $p['pid'], $pl['id']]); send(plan_detail($pl));
});
route('DELETE', '/plans/{id}/packing/{pid}', function ($p) {
    $pl = own_plan((int)$p['id']); q_run('DELETE FROM packing_items WHERE id = ? AND plan_id = ?', [$p['pid'], $pl['id']]); send(plan_detail($pl));
});

// Masukkan destinasi ke rencana: otomatis tambah item jalan, tiket, pemandu (opsional), dan makan siang terdekat.
route('POST', '/plans/{id}/add-destination', function ($p) {
    $pl = own_plan((int)$p['id']); $b = body(); need($b, ['destination_id']);
    $d = q_one('SELECT * FROM destinations WHERE id = ?', [$b['destination_id']]);
    if (!$d) fail(404, 'Destinasi tidak ditemukan');
    $day = max(1, (int)($b['day_no'] ?? 1));
    $ins = fn($t, $title, $kind, $note = null) => q_ins('INSERT INTO plan_items (plan_id, day_no, time_label, title, note, kind, destination_id) VALUES (?,?,?,?,?,?,?)',
        [$pl['id'], $day, $t, $title, $note, $kind, $d['id']]);
    $ins('07.00', 'Tiba di ' . $d['name'], 'activity', $d['region']);
    $ins('07.30', 'Tiket ' . $d['name'], 'ticket', 'Rp ' . number_format((int)$d['price_idr'], 0, ',', '.'));
    if (!empty($b['with_guide'])) $ins('08.00', 'Pemandu wisata', 'guide');
    $ins('09.00', 'Jelajah ' . $d['name'], 'activity');
    $eat = jd($d['eat_nearby']);
    $first = is_array($eat) && $eat ? (is_array($eat[0]) ? ($eat[0]['name'] ?? reset($eat[0])) : $eat[0]) : null;
    $ins('12.30', 'Makan siang' . ($first ? ': ' . $first : ''), 'food');
    send(plan_detail($pl), 201);
});
