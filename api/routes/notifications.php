<?php
// Pengingat dibuat saat daftar notifikasi dibuka: H-3 barang bawaan, H-1 keberangkatan.
function generate_reminders(int $uid): void {
    foreach (q_all('SELECT * FROM plans WHERE user_id = ? AND start_date IS NOT NULL', [$uid]) as $pl) {
        $n = days_until($pl['start_date']);
        if ($n === null || $n < 0) continue;
        if ($pl['remind_pack'] && $n <= 3) {
            $left = (int)q_one('SELECT COUNT(*) c FROM packing_items WHERE plan_id = ? AND done = 0', [$pl['id']])['c'];
            notify($uid, 'Siapkan barang bawaan', "{$pl['name']} berangkat $n hari lagi. Masih $left barang belum dicek.", 'reminder', 'pack-' . $pl['id']);
        }
        if ($pl['remind_depart'] && $n <= 1) {
            notify($uid, 'Besok berangkat!', "{$pl['name']} dimulai " . ($n === 0 ? 'hari ini' : 'besok') . '. Cek tiket dan rencana harianmu.', 'reminder', 'dep-' . $pl['id']);
        }
    }
}

route('GET', '/notifications', function () {
    $u = auth(); generate_reminders((int)$u['id']);
    $rows = q_all('SELECT * FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 60', [$u['id']]);
    send(['unread' => count(array_filter($rows, fn($r) => !$r['is_read'])),
          'items' => array_map(fn($r) => ['id' => (int)$r['id'], 'title' => $r['title'], 'body' => $r['body'], 'type' => $r['type'],
                                          'is_read' => (bool)$r['is_read'], 'created_at' => $r['created_at']], $rows)]);
});
route('POST', '/notifications/read-all', function () {
    $u = auth(); q_run('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [$u['id']]); send(['ok' => true]);
});
route('POST', '/notifications/{id}/read', function ($p) {
    $u = auth(); q_run('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?', [$p['id'], $u['id']]); send(['ok' => true]);
});
