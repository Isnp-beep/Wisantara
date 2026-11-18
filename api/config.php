<?php
// Konfigurasi API Wisantara. Nilai bisa diganti lewat environment variable.
function env(string $k, $default = null) {
    $v = getenv($k);
    return ($v === false || $v === '') ? $default : $v;
}
return [
    'db_dsn'  => env('DB_DSN', 'mysql:host=127.0.0.1;port=3306;dbname=wisantara;charset=utf8mb4'),
    'db_user' => env('DB_USER', 'root'),
    'db_pass' => env('DB_PASS', ''),
    'service_fee' => 5000,
    // Opsional: isi untuk memakai Claude API sebagai penjelas rekomendasi.
    'anthropic_key'   => env('ANTHROPIC_API_KEY', ''),
    'anthropic_model' => env('ANTHROPIC_MODEL', 'claude-haiku-5-5'),
];
