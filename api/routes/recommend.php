<?php
// Rekomendasi wisata: parser bahasa Indonesia + penilaian berbobot.
// Opsional: jika ANTHROPIC_API_KEY diisi, penjelasan dibuat oleh Claude API.
function parse_prompt(string $text): array {
    $t = mb_strtolower($text);
    $budget = null; $days = null;
    if (preg_match('/(\d+(?:[.,]\d+)?)\s*(juta|jt|ribu|rb|k)\b/u', $t, $m)) {
        $n = (float)str_replace(',', '.', $m[1]);
        $budget = (int)round($n * (in_array($m[2], ['juta', 'jt'], true) ? 1000000 : 1000));
    } elseif (preg_match('/rp\.?\s*([\d.]+)/u', $t, $m)) {
        $budget = (int)str_replace('.', '', $m[1]);
    }
    if (preg_match('/(\d+)\s*hari/u', $t, $m)) $days = max(1, min(14, (int)$m[1]));
    $map = [
        'alam' => ['gunung', 'alam', 'air terjun', 'trekking', 'hiking', 'sunrise', 'pendakian'],
        'pantai' => ['pantai', 'laut', 'snorkel', 'pulau', 'diving', 'sunset'],
        'budaya' => ['budaya', 'seni', 'tari', 'tradisi', 'desa'],
        'sejarah' => ['candi', 'sejarah', 'keraton', 'museum', 'istana'],
        'kuliner' => ['kuliner', 'makan', 'jajan', 'masakan'],
    ];
    $interests = [];
    foreach ($map as $cat => $words) foreach ($words as $w) if (mb_strpos($t, $w) !== false) { $interests[$cat] = true; break; }
    return ['budget' => $budget, 'days' => $days, 'interests' => array_keys($interests)];
}

function llm_explain(string $prompt, array $picks): ?string {
    $key = cfg('anthropic_key');
    if (!$key || !function_exists('curl_init')) return null;
    $names = implode(', ', array_map(fn($p) => $p['destination']['name'], $picks));
    $payload = ['model' => cfg('anthropic_model'), 'max_tokens' => 300,
        'messages' => [['role' => 'user', 'content' => "Pengguna meminta: \"$prompt\". Kami merekomendasikan: $names. Tulis 2 kalimat penjelasan singkat dalam bahasa Indonesia mengapa cocok."]]];
    $ch = curl_init('https://api.anthropic.com/v1/messages');
    curl_setopt_array($ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_POST => true, CURLOPT_TIMEOUT => 12,
        CURLOPT_HTTPHEADER => ['content-type: application/json', 'x-api-key: ' . $key, 'anthropic-version: 2023-06-01'],
        CURLOPT_POSTFIELDS => json_encode($payload)]);
    $res = curl_exec($ch); curl_close($ch);
    $j = $res ? json_decode($res, true) : null;
    return $j['content'][0]['text'] ?? null;
}

route('POST', '/recommend', function () {
    $u = auth_optional(); $b = body();
    $prompt = trim($b['prompt'] ?? '');
    $parsed = parse_prompt($prompt);
    $budget = isset($b['budget']) ? (int)$b['budget'] : $parsed['budget'];
    $days = isset($b['days']) ? max(1, (int)$b['days']) : ($parsed['days'] ?? 2);
    $people = max(1, (int)($b['people'] ?? 2));
    $interests = !empty($b['interests']) && is_array($b['interests']) ? $b['interests'] : $parsed['interests'];
    $lang = $u['language'] ?? 'id';
    $scored = [];
    foreach (q_all('SELECT * FROM destinations') as $d) {
        $cost = $d['price_idr'] * $people + 280000 + 5000;   // tiket + 1 hari guide + biaya layanan
        $score = 1.0; $why = [];
        if ($interests) {
            if (in_array($d['category'], $interests, true)) { $score += 3; $why[] = 'sesuai minat ' . $d['category']; }
            else $score -= 0.5;
        }
        if ($budget) {
            $perDay = $budget / $days;
            if ($cost <= $perDay) { $score += 2; $why[] = 'muat di budget'; }
            elseif ($cost <= $budget) { $score += 0.5; $why[] = 'masih di bawah total budget'; }
            else { $score -= 2; }
        }
        $rs = rating_summary((int)$d['id']);
        $score += $rs['avg'] * 0.4;
        if ($rs['avg']) $why[] = 'rating ' . $rs['avg'];
        $scored[] = ['destination' => shape_destination($d, $lang, $u ? (int)$u['id'] : null), 'score' => round($score, 2),
                     'est_cost' => $cost, 'reason' => $why ? ucfirst(implode(', ', $why)) : 'Populer di Wisantara'];
    }
    usort($scored, fn($a, $b2) => $b2['score'] <=> $a['score']);
    $top = array_slice($scored, 0, 3);
    $itin = [];
    foreach ($top as $i => $t) {
        $itin[] = ['day' => ($i % $days) + 1, 'destination_id' => $t['destination']['id'], 'title' => $t['destination']['name']];
    }
    send(['parsed' => ['budget' => $budget, 'days' => $days, 'people' => $people, 'interests' => $interests],
          'results' => $top, 'itinerary' => $itin, 'summary' => llm_explain($prompt, $top)]);
});
