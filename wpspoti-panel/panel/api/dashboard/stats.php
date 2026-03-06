<?php
require_once __DIR__ . '/../../core/bootstrap.php';
if ($_SERVER['REQUEST_METHOD'] !== 'GET') Response::error('Method not allowed', 405);

$cpuLoad = sys_getloadavg() ?: [0,0,0];
$nproc = (int) trim(Shell::exec('nproc')['output'] ?: '1');

$memInfo = Shell::exec('free', ['-m']);
preg_match('/Mem:\s+(\d+)\s+(\d+)/', $memInfo['output'], $m);
$ramTotal = (int)($m[1] ?? 0); $ramUsed = (int)($m[2] ?? 0);

$diskInfo = Shell::exec('df', ['-BG', '--output=size,used,avail', '/']);
preg_match('/(\d+)G\s+(\d+)G\s+(\d+)G/', $diskInfo['output'], $d);

$uptimeRaw = trim(Shell::exec('uptime', ['-p'])['output']);
$db = Database::getInstance();
$siteCount = $db->query("SELECT COUNT(*) FROM sites")->fetchColumn();

$services = ['nginx','php8.3-fpm','mariadb','named','postfix','dovecot','vsftpd','fail2ban'];
$svcStatus = [];
foreach ($services as $svc) {
    $r = Shell::exec('systemctl', ['is-active', $svc]);
    $svcStatus[$svc] = trim($r['output']);
}

$recent = $db->query("SELECT * FROM activity_log ORDER BY created_at DESC LIMIT 10")->fetchAll();

Response::success([
    'cpu' => ['load_1'=>$cpuLoad[0],'load_5'=>$cpuLoad[1],'load_15'=>$cpuLoad[2],'cores'=>$nproc],
    'ram' => ['total_mb'=>$ramTotal,'used_mb'=>$ramUsed,'percent'=>$ramTotal>0?round($ramUsed/$ramTotal*100,1):0],
    'disk' => ['total_gb'=>(int)($d[1]??0),'used_gb'=>(int)($d[2]??0),'available_gb'=>(int)($d[3]??0)],
    'uptime' => $uptimeRaw,
    'sites_count' => (int)$siteCount,
    'services' => $svcStatus,
    'hostname' => gethostname(),
    'server_ip' => trim(Shell::exec('hostname', ['-I'])['output']),
    'recent_activity' => $recent
]);
