<?php

require __DIR__ . '/lib/core.php';
foreach (['auth', 'destinations', 'recommend', 'bookings', 'community', 'plans', 'notifications'] as $r)
    require __DIR__ . "/routes/$r.php";
route('GET', '/', fn() => send(['name' => 'Wisantara API', 'status' => 'ok']));
dispatch();
