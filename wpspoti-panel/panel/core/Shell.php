<?php
class Shell {
    private static array $allowedCommands = [
        'nginx', 'systemctl', 'certbot', 'ufw', 'useradd', 'userdel',
        'passwd', 'chown', 'chmod', 'mkdir', 'rm', 'cp', 'mv', 'tar',
        'zip', 'unzip', 'named-checkzone', 'rndc', 'postconf', 'doveadm',
        'fail2ban-client', 'mysql', 'mysqladmin', 'df', 'free', 'uptime',
        'ps', 'kill', 'cat', 'tail', 'head', 'wc', 'du', 'ls', 'ln',
        'crontab', 'openssl', 'hostname', 'ip', 'ss', 'lsb_release',
        'nproc', 'grep', 'awk', 'sed', 'tee', 'stat', 'find', 'wp',
        'curl', 'wget', 'htpasswd', 'postmap'
    ];

    public static function exec(string $command, array $args = []): array {
        $binary = basename(explode(' ', trim($command))[0]);

        if (!in_array($binary, self::$allowedCommands)) {
            Logger::log('security', "Blocked command: {$binary}");
            return ['success' => false, 'output' => '', 'error' => 'Command not allowed', 'return_code' => -1];
        }

        $escapedArgs = array_map('escapeshellarg', $args);
        $fullCommand = $command . ' ' . implode(' ', $escapedArgs) . ' 2>&1';

        $output = [];
        $returnCode = -1;
        exec($fullCommand, $output, $returnCode);

        $outputStr = implode("\n", $output);

        Logger::log('shell', "CMD: {$fullCommand} | RC: {$returnCode}");

        return [
            'success' => ($returnCode === 0),
            'output' => $outputStr,
            'return_code' => $returnCode
        ];
    }

    public static function sudo(string $command, array $args = []): array {
        return self::exec('sudo ' . $command, $args);
    }

    public static function execRaw(string $fullCommand): array {
        $binary = basename(explode(' ', trim(str_replace('sudo ', '', $fullCommand)))[0]);
        if (!in_array($binary, self::$allowedCommands)) {
            Logger::log('security', "Blocked raw command: {$binary}");
            return ['success' => false, 'output' => '', 'return_code' => -1];
        }

        $output = [];
        $returnCode = -1;
        exec($fullCommand . ' 2>&1', $output, $returnCode);

        return [
            'success' => ($returnCode === 0),
            'output' => implode("\n", $output),
            'return_code' => $returnCode
        ];
    }
}
