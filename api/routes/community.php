<?php
function shape_post(array $p, ?int $uid): array {
    $u = q_one('SELECT id, name, role, avatar_url FROM users WHERE id = ?', [$p['user_id']]);
    $d = q_one('SELECT name FROM destinations WHERE id = ?', [$p['destination_id']]);
    $g = $p['guide_id'] ? q_one('SELECT name FROM guides WHERE id = ?', [$p['guide_id']]) : null;
    return ['id' => (int)$p['id'], 'user' => ['id' => (int)$u['id'], 'name' => $u['name'], 'role' => $u['role'], 'avatar_url' => abs_url($u['avatar_url'])],
        'destination_id' => (int)$p['destination_id'], 'destination_name' => $d['name'],
        'guide_id' => $p['guide_id'] ? (int)$p['guide_id'] : null, 'guide_name' => $g['name'] ?? null,
        'rating_place' => (int)$p['rating_place'], 'rating_guide' => $p['rating_guide'] ? (int)$p['rating_guide'] : null,
        'caption' => $p['caption'], 'image_url' => abs_url($p['image_url']), 'created_at' => $p['created_at'],
        'likes' => (int)q_one('SELECT COUNT(*) c FROM post_likes WHERE post_id = ?', [$p['id']])['c'],
        'comments' => (int)q_one('SELECT COUNT(*) c FROM post_comments WHERE post_id = ?', [$p['id']])['c'],
        'liked' => $uid ? (bool)q_one('SELECT 1 x FROM post_likes WHERE post_id = ? AND user_id = ?', [$p['id'], $uid]) : false,
        'following' => $uid ? (bool)q_one('SELECT 1 x FROM follows WHERE user_id = ? AND follow_id = ?', [$uid, $p['user_id']]) : false];
}

route('GET', '/posts', function () {
    $u = auth_optional(); $uid = $u ? (int)$u['id'] : null;
    $sql = 'SELECT p.* FROM posts p WHERE 1=1'; $a = [];
    if (($_GET['tab'] ?? '') === 'following') {
        if (!$uid) fail(401, 'Masuk untuk melihat postingan yang kamu ikuti');
        $sql .= ' AND p.user_id IN (SELECT follow_id FROM follows WHERE user_id = ?)'; $a[] = $uid;
    }
    if (!empty($_GET['destination_id'])) { $sql .= ' AND p.destination_id = ?'; $a[] = (int)$_GET['destination_id']; }
    if (!empty($_GET['guide_id'])) { $sql .= ' AND p.guide_id = ?'; $a[] = (int)$_GET['guide_id']; }
    send(array_map(fn($r) => shape_post($r, $uid), q_all($sql . ' ORDER BY p.id DESC LIMIT 50', $a)));
});

route('GET', '/destinations/{id}/reviews', function ($p) {
    $u = auth_optional();
    $rows = q_all('SELECT * FROM posts WHERE destination_id = ? ORDER BY id DESC LIMIT 30', [$p['id']]);
    send(['summary' => rating_summary((int)$p['id']), 'posts' => array_map(fn($r) => shape_post($r, $u ? (int)$u['id'] : null), $rows)]);
});

route('POST', '/posts', function () {
    $u = auth();
    $src = $_POST ?: body();
    need($src, ['destination_id', 'rating_place']);
    $rp = (int)$src['rating_place'];
    if ($rp < 1 || $rp > 5) fail(422, 'Rating tempat harus 1-5');
    $rg = !empty($src['rating_guide']) ? (int)$src['rating_guide'] : null;
    $gid = !empty($src['guide_id']) ? (int)$src['guide_id'] : null;
    if ($gid && ($rg === null || $rg < 1 || $rg > 5)) fail(422, 'Rating pemandu harus 1-5');
    if (!q_one('SELECT id FROM destinations WHERE id = ?', [$src['destination_id']])) fail(404, 'Destinasi tidak ditemukan');
    $img = null;
    if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $f = $_FILES['image'];
        if ($f['size'] > 5 * 1024 * 1024) fail(413, 'Ukuran foto maksimal 5 MB');
        $info = @getimagesize($f['tmp_name']);
        $ext = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'][$info['mime'] ?? ''] ?? null;
        if (!$ext) fail(415, 'Format foto harus JPG, PNG, atau WebP');
        $dir = __DIR__ . '/../uploads/posts';
        if (!is_dir($dir)) mkdir($dir, 0775, true);
        $name = bin2hex(random_bytes(8)) . '.' . $ext;
        if (!move_uploaded_file($f['tmp_name'], "$dir/$name")) fail(500, 'Gagal menyimpan foto');
        $img = "/uploads/posts/$name";
    }
    $id = q_ins('INSERT INTO posts (user_id,destination_id,guide_id,rating_place,rating_guide,caption,image_url) VALUES (?,?,?,?,?,?,?)',
        [$u['id'], $src['destination_id'], $gid, $rp, $rg, mb_substr(trim($src['caption'] ?? ''), 0, 500), $img]);
    send(shape_post(q_one('SELECT * FROM posts WHERE id = ?', [$id]), (int)$u['id']), 201);
});

route('POST', '/posts/{id}/like', function ($p) {
    $u = auth();
    if (!q_one('SELECT id FROM posts WHERE id = ?', [$p['id']])) fail(404, 'Postingan tidak ditemukan');
    $has = q_one('SELECT 1 x FROM post_likes WHERE post_id = ? AND user_id = ?', [$p['id'], $u['id']]);
    if ($has) q_run('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [$p['id'], $u['id']]);
    else q_run('INSERT INTO post_likes (post_id, user_id) VALUES (?,?)', [$p['id'], $u['id']]);
    send(['liked' => !$has, 'likes' => (int)q_one('SELECT COUNT(*) c FROM post_likes WHERE post_id = ?', [$p['id']])['c']]);
});

route('GET', '/posts/{id}/comments', function ($p) {
    $rows = q_all('SELECT c.id, c.body, c.created_at, u.id uid, u.name FROM post_comments c JOIN users u ON u.id = c.user_id WHERE c.post_id = ? ORDER BY c.id', [$p['id']]);
    send(array_map(fn($r) => ['id' => (int)$r['id'], 'body' => $r['body'], 'created_at' => $r['created_at'], 'user' => ['id' => (int)$r['uid'], 'name' => $r['name']]], $rows));
});

route('POST', '/posts/{id}/comments', function ($p) {
    $u = auth(); $b = body(); need($b, ['body']);
    $post = q_one('SELECT * FROM posts WHERE id = ?', [$p['id']]);
    if (!$post) fail(404, 'Postingan tidak ditemukan');
    $text = mb_substr(trim($b['body']), 0, 300);
    $id = q_ins('INSERT INTO post_comments (post_id, user_id, body) VALUES (?,?,?)', [$p['id'], $u['id'], $text]);
    if ((int)$post['user_id'] !== (int)$u['id'])
        notify((int)$post['user_id'], 'Komentar baru', $u['name'] . ' mengomentari postinganmu.', 'community');
    send(['id' => $id, 'body' => $text, 'user' => ['id' => (int)$u['id'], 'name' => $u['name']]], 201);
});

route('POST', '/users/{id}/follow', function ($p) {
    $u = auth();
    if ((int)$p['id'] === (int)$u['id']) fail(422, 'Tidak bisa mengikuti diri sendiri');
    if (!q_one('SELECT id FROM users WHERE id = ?', [$p['id']])) fail(404, 'Pengguna tidak ditemukan');
    $has = q_one('SELECT 1 x FROM follows WHERE user_id = ? AND follow_id = ?', [$u['id'], $p['id']]);
    if ($has) q_run('DELETE FROM follows WHERE user_id = ? AND follow_id = ?', [$u['id'], $p['id']]);
    else q_run('INSERT INTO follows (user_id, follow_id) VALUES (?,?)', [$u['id'], $p['id']]);
    send(['following' => !$has]);
});
