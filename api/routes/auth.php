<?php
route('POST', '/auth/register', function () {
    $b = body(); need($b, ['name', 'email', 'password']);
    $email = strtolower(trim($b['email']));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) fail(422, 'Email tidak valid');
    if (strlen($b['password']) < 6) fail(422, 'Kata sandi minimal 6 karakter');
    if (q_one('SELECT id FROM users WHERE email = ?', [$email])) fail(409, 'Email sudah terdaftar');
    $role = in_array($b['role'] ?? 'turis', ['lokal', 'turis'], true) ? ($b['role'] ?? 'turis') : 'turis';
    $id = q_ins('INSERT INTO users (name, email, password_hash, role) VALUES (?,?,?,?)',
        [trim($b['name']), $email, password_hash($b['password'], PASSWORD_BCRYPT), $role]);
    notify($id, 'Selamat datang di Wisantara', 'Mulai jelajahi wisata Indonesia dan buat rencana perjalananmu.', 'info');
    send(['token' => make_token($id), 'user' => public_user(q_one('SELECT * FROM users WHERE id = ?', [$id]))], 201);
});

route('POST', '/auth/login', function () {
    $b = body(); need($b, ['email', 'password']);
    $u = q_one('SELECT * FROM users WHERE email = ?', [strtolower(trim($b['email']))]);
    if (!$u || !password_verify($b['password'], $u['password_hash'])) fail(401, 'Email atau kata sandi salah');
    send(['token' => make_token((int)$u['id']), 'user' => public_user($u)]);
});

route('POST', '/auth/logout', function () {
    if ($t = bearer()) q_run('DELETE FROM api_tokens WHERE token = ?', [$t]);
    send(['ok' => true]);
});

route('POST', '/auth/forgot', function () {
    $b = body(); need($b, ['email']);
    // Di produksi: kirim email berisi tautan atur ulang. Di sini cukup konfirmasi.
    send(['ok' => true, 'message' => 'Jika email terdaftar, tautan atur ulang telah dikirim.']);
});

route('GET', '/me', function () { send(public_user(auth())); });

route('PUT', '/me', function () {
    $u = auth(); $b = body();
    $name = trim($b['name'] ?? $u['name']);
    $role = in_array($b['role'] ?? $u['role'], ['lokal', 'turis'], true) ? ($b['role'] ?? $u['role']) : $u['role'];
    $lang = in_array($b['language'] ?? $u['language'], ['id', 'en', 'zh', 'ja', 'ko'], true) ? ($b['language'] ?? $u['language']) : $u['language'];
    q_run('UPDATE users SET name = ?, role = ?, language = ? WHERE id = ?', [$name, $role, $lang, $u['id']]);
    send(public_user(q_one('SELECT * FROM users WHERE id = ?', [$u['id']])));
});

route('GET', '/me/stats', function () {
    $u = auth();
    send([
        'trips' => (int)q_one("SELECT COUNT(*) c FROM bookings WHERE user_id = ? AND status = 'paid'", [$u['id']])['c'],
        'saved' => (int)q_one('SELECT COUNT(*) c FROM favorites WHERE user_id = ?', [$u['id']])['c'],
        'posts' => (int)q_one('SELECT COUNT(*) c FROM posts WHERE user_id = ?', [$u['id']])['c'],
        'plans' => (int)q_one('SELECT COUNT(*) c FROM plans WHERE user_id = ?', [$u['id']])['c'],
    ]);
});
