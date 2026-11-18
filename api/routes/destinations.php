<?php
function rating_summary(int $destId): array {
    $rows = q_all('SELECT rating_place, rating_guide FROM posts WHERE destination_id = ?', [$destId]);
    $n = count($rows); $bars = [5 => 0, 4 => 0, 3 => 0, 2 => 0, 1 => 0];
    $sumP = 0; $sumG = 0; $nG = 0;
    foreach ($rows as $r) {
        $bars[(int)$r['rating_place']]++; $sumP += (int)$r['rating_place'];
        if ($r['rating_guide']) { $sumG += (int)$r['rating_guide']; $nG++; }
    }
    $pct = []; foreach ($bars as $k => $v) $pct[$k] = $n ? (int)round($v * 100 / $n) : 0;
    return ['count' => $n, 'avg' => $n ? round($sumP / $n, 1) : 0, 'guide_avg' => $nG ? round($sumG / $nG, 1) : 0, 'bars' => $pct];
}

function shape_destination(array $d, string $lang, ?int $uid, bool $full = false): array {
    $desc = jd($d['descriptions']) ?: [];
    $rs = rating_summary((int)$d['id']);
    $out = [
        'id' => (int)$d['id'], 'name' => $d['name'], 'region' => $d['region'], 'category' => $d['category'],
        'price_idr' => (int)$d['price_idr'], 'lat' => (float)$d['lat'], 'lng' => (float)$d['lng'],
        'image_url' => abs_url($d['image_url']), 'image_credit' => $d['image_credit'],
        'description' => $desc[$lang] ?? ($desc['id'] ?? ''), 'rating' => $rs['avg'], 'review_count' => $rs['count'],
        'is_favorite' => $uid ? (bool)q_one('SELECT 1 x FROM favorites WHERE user_id = ? AND destination_id = ?', [$uid, $d['id']]) : false,
    ];
    if ($full) {
        $out['descriptions'] = $desc;
        $out['access_times'] = jd($d['access_times']);
        $out['access_notes'] = jd($d['access_notes']);
        $out['pros'] = jd($d['pros']); $out['cons'] = jd($d['cons']); $out['equipment'] = jd($d['equipment']);
        $out['best_time'] = $d['best_time']; $out['eat_nearby'] = jd($d['eat_nearby']);
        $out['rating_summary'] = $rs;
    }
    return $out;
}

route('GET', '/destinations', function () {
    $u = auth_optional(); $lang = $_GET['lang'] ?? ($u['language'] ?? 'id');
    $sql = 'SELECT * FROM destinations WHERE 1=1'; $args = [];
    if (!empty($_GET['q'])) { $sql .= ' AND (name LIKE ? OR region LIKE ? OR category LIKE ?)'; $like = '%' . $_GET['q'] . '%'; array_push($args, $like, $like, $like); }
    if (!empty($_GET['category'])) { $sql .= ' AND category = ?'; $args[] = $_GET['category']; }
    if (!empty($_GET['region'])) { $sql .= ' AND region LIKE ?'; $args[] = '%' . $_GET['region'] . '%'; }
    if (!empty($_GET['max_price'])) { $sql .= ' AND price_idr <= ?'; $args[] = (int)$_GET['max_price']; }
    $rows = q_all($sql . ' ORDER BY id', $args);
    $lat = isset($_GET['lat']) ? (float)$_GET['lat'] : null; $lng = isset($_GET['lng']) ? (float)$_GET['lng'] : null;
    $out = [];
    foreach ($rows as $r) {
        $s = shape_destination($r, $lang, $u ? (int)$u['id'] : null);
        if ($lat !== null && $lng !== null) $s['distance_km'] = distance_km($lat, $lng, (float)$r['lat'], (float)$r['lng']);
        $out[] = $s;
    }
    if ($lat !== null && $lng !== null) usort($out, fn($a, $b) => $a['distance_km'] <=> $b['distance_km']);
    send($out);
});

route('GET', '/destinations/{id}', function ($p) {
    $u = auth_optional(); $lang = $_GET['lang'] ?? ($u['language'] ?? 'id');
    $d = q_one('SELECT * FROM destinations WHERE id = ?', [$p['id']]);
    if (!$d) fail(404, 'Destinasi tidak ditemukan');
    send(shape_destination($d, $lang, $u ? (int)$u['id'] : null, true));
});

route('POST', '/destinations/{id}/favorite', function ($p) {
    $u = auth();
    if (!q_one('SELECT id FROM destinations WHERE id = ?', [$p['id']])) fail(404, 'Destinasi tidak ditemukan');
    $has = q_one('SELECT 1 x FROM favorites WHERE user_id = ? AND destination_id = ?', [$u['id'], $p['id']]);
    if ($has) q_run('DELETE FROM favorites WHERE user_id = ? AND destination_id = ?', [$u['id'], $p['id']]);
    else q_run('INSERT INTO favorites (user_id, destination_id) VALUES (?,?)', [$u['id'], $p['id']]);
    send(['is_favorite' => !$has]);
});

route('GET', '/favorites', function () {
    $u = auth();
    $rows = q_all('SELECT d.* FROM favorites f JOIN destinations d ON d.id = f.destination_id WHERE f.user_id = ?', [$u['id']]);
    send(array_map(fn($r) => shape_destination($r, $u['language'], (int)$u['id']), $rows));
});

route('GET', '/guides', function () {
    $sql = 'SELECT * FROM guides WHERE 1=1'; $args = [];
    if (!empty($_GET['lang'])) { $sql .= ' AND (languages LIKE ?)'; $args[] = '%' . $_GET['lang'] . '%'; }
    if (!empty($_GET['region'])) { $sql .= ' AND region LIKE ?'; $args[] = '%' . $_GET['region'] . '%'; }
    $out = [];
    foreach (q_all($sql . ' ORDER BY id', $args) as $g) {
        $r = q_one('SELECT COUNT(rating_guide) n, AVG(rating_guide) a FROM posts WHERE guide_id = ? AND rating_guide IS NOT NULL', [$g['id']]);
        $out[] = ['id' => (int)$g['id'], 'name' => $g['name'], 'region' => $g['region'], 'languages' => explode(',', $g['languages']),
                  'price_idr' => (int)$g['price_idr'], 'bio' => $g['bio'], 'color' => $g['color'],
                  'rating' => $r['n'] ? round((float)$r['a'], 1) : 0, 'review_count' => (int)$r['n']];
    }
    send($out);
});

route('GET', '/phrases', function () {
    $lang = $_GET['lang'] ?? 'en';
    send(q_all('SELECT src_id AS source, text_tr AS translation FROM phrases WHERE lang = ? ORDER BY id', [$lang]));
});
