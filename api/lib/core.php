<?php
// Fungsi inti: database, request/response, autentikasi, router.
$GLOBALS['cfg'] = require __DIR__ . '/../config.php';
$GLOBALS['routes'] = [];

function cfg(string $k) { return $GLOBALS['cfg'][$k] ?? null; }

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(cfg('db_dsn'), cfg('db_user'), cfg('db_pass'), [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
    }
    return $pdo;
}
function q_all(string $sql, array $args = []): array { $s = db()->prepare($sql); $s->execute($args); return $s->fetchAll(); }
function q_one(string $sql, array $args = []): ?array { $s = db()->prepare($sql); $s->execute($args); $r = $s->fetch(); return $r ?: null; }
function q_run(string $sql, array $args = []): int { $s = db()->prepare($sql); $s->execute($args); return $s->rowCount(); }
function q_ins(string $sql, array $args = []): int { q_run($sql, $args); return (int)db()->lastInsertId(); }

function send($data, int $code = 200): void {
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function fail(int $code, string $msg): void { send(['error' => $msg], $code); }

function body(): array {
    static $b = null;
    if ($b === null) {
        $raw = file_get_contents('php://input');
        $j = json_decode($raw ?: '', true);
        $b = array_merge($_POST, is_array($j) ? $j : []);
    }
    return $b;
}
function need(array $src, array $keys): void {
    foreach ($keys as $k) if (!isset($src[$k]) || $src[$k] === '') fail(422, "Field '$k' wajib diisi");
}

function api_base_url(): string {
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    $dir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
    return "$scheme://$host$dir";
}
function abs_url(?string $path): ?string {
    if (!$path) return null;
    if (preg_match('#^https?://#', $path)) return $path;
    return api_base_url() . '/' . ltrim($path, '/');
}

// ---------- autentikasi (bearer token) ----------
function bearer(): ?string {
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!$h && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) if (strtolower($k) === 'authorization') $h = $v;
    }
    return preg_match('/Bearer\s+(\S+)/i', $h, $m) ? $m[1] : null;
}
function auth_optional(): ?array {
    $t = bearer();
    if (!$t) return null;
    return q_one('SELECT u.* FROM api_tokens t JOIN users u ON u.id = t.user_id WHERE t.token = ?', [$t]);
}
function auth(): array {
    $u = auth_optional();
    if (!$u) fail(401, 'Silakan masuk terlebih dahulu');
    return $u;
}
function public_user(array $u): array {
    return ['id' => (int)$u['id'], 'name' => $u['name'], 'email' => $u['email'], 'role' => $u['role'],
            'language' => $u['language'], 'avatar_url' => abs_url($u['avatar_url'] ?? null)];
}
function make_token(int $uid): string {
    $t = bin2hex(random_bytes(32));
    q_run('INSERT INTO api_tokens (token, user_id) VALUES (?, ?)', [$t, $uid]);
    return $t;
}

// ---------- router ----------
function route(string $method, string $pattern, callable $h): void {
    $re = '#^' . preg_replace('#\{(\w+)\}#', '(?P<$1>[^/]+)', $pattern) . '/?$#';
    $GLOBALS['routes'][] = [$method, $re, $h];
}
function dispatch(): void {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Headers: Authorization, Content-Type');
    header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
    $method = $_SERVER['REQUEST_METHOD'];
    if ($method === 'OPTIONS') { http_response_code(204); exit; }
    $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    $base = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');
    if ($base !== '' && strpos($path, $base) === 0) $path = substr($path, strlen($base));
    $path = preg_replace('#^/index\.php#', '', $path);
    if ($path === '' || $path === false) $path = '/';
    foreach ($GLOBALS['routes'] as [$m, $re, $h]) {
        if ($m === $method && preg_match($re, $path, $mm)) {
            $params = array_filter($mm, 'is_string', ARRAY_FILTER_USE_KEY);
            try { $h($params); } catch (PDOException $e) { fail(500, 'Kesalahan database: ' . $e->getMessage()); }
            return;
        }
    }
    fail(404, 'Endpoint tidak ditemukan: ' . $method . ' ' . $path);
}

// ---------- util ----------
function today(): string { return date('Y-m-d'); }
function days_until(?string $date): ?int {
    if (!$date) return null;
    return (int)floor((strtotime($date) - strtotime(today())) / 86400);
}
function distance_km(float $a, float $b, float $c, float $d): float {
    $r = 6371; $dLat = deg2rad($c - $a); $dLng = deg2rad($d - $b);
    $x = sin($dLat / 2) ** 2 + cos(deg2rad($a)) * cos(deg2rad($c)) * sin($dLng / 2) ** 2;
    return round(2 * $r * asin(sqrt($x)), 1);
}
function jd(?string $s) { return $s ? json_decode($s, true) : null; }
function notify(int $uid, string $title, string $body, string $type = 'info', ?string $ref = null): void {
    if ($ref && q_one('SELECT id FROM notifications WHERE user_id = ? AND ref = ?', [$uid, $ref])) return;
    q_ins('INSERT INTO notifications (user_id, title, body, type, ref) VALUES (?,?,?,?,?)', [$uid, $title, $body, $type, $ref]);
}
