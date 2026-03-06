#!/bin/bash
# Wpspoti Panel - Resource Monitoring Collector
# Run via cron every minute: * * * * * /var/wpspoti/scripts/monitoring-collector.sh

DB_PATH="/var/wpspoti/panel.db"

CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' 2>/dev/null || echo "0")
LOAD=$(cat /proc/loadavg 2>/dev/null || echo "0 0 0")
LOAD_1=$(echo "$LOAD" | awk '{print $1}')
LOAD_5=$(echo "$LOAD" | awk '{print $2}')
LOAD_15=$(echo "$LOAD" | awk '{print $3}')

MEM_INFO=$(free -m | grep Mem)
RAM_TOTAL=$(echo "$MEM_INFO" | awk '{print $2}')
RAM_USED=$(echo "$MEM_INFO" | awk '{print $3}')

DISK_INFO=$(df -BG / | tail -1)
DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}' | tr -d 'G')
DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}' | tr -d 'G')

NET_IN=$(cat /proc/net/dev | grep -E 'eth0|ens' | head -1 | awk '{print $2}' 2>/dev/null || echo "0")
NET_OUT=$(cat /proc/net/dev | grep -E 'eth0|ens' | head -1 | awk '{print $10}' 2>/dev/null || echo "0")

sqlite3 "$DB_PATH" "INSERT INTO resource_history (cpu_percent, ram_used_mb, ram_total_mb, disk_used_gb, disk_total_gb, net_in_bytes, net_out_bytes, load_1, load_5, load_15) VALUES ($CPU_PERCENT, $RAM_USED, $RAM_TOTAL, $DISK_USED, $DISK_TOTAL, $NET_IN, $NET_OUT, $LOAD_1, $LOAD_5, $LOAD_15);"

# Cleanup old records (keep 7 days)
sqlite3 "$DB_PATH" "DELETE FROM resource_history WHERE recorded_at < datetime('now', '-7 days');"
