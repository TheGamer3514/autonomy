#!/bin/bash
# Flexible Interval Autonomy Daemon
# User-configurable interval, reliable execution, AI-controlled processing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTONOMY_DIR="${AUTONOMY_DIR:-$SCRIPT_DIR}"
CONFIG_FILE="$AUTONOMY_DIR/config.json"
PID_FILE="$AUTONOMY_DIR/state/daemon.pid"
LOG_FILE="$AUTONOMY_DIR/logs/daemon.log"
CHECK_FILE="$AUTONOMY_DIR/state/last-check.json"

# Get interval from config (user can change this)
get_interval() {
    local interval=$(jq -r '.daemon.interval_minutes // 5' "$CONFIG_FILE" 2>/dev/null || echo 5)
    # Validate: must be between 1 and 1440 (24 hours)
    if [[ "$interval" -lt 1 ]]; then interval=1; fi
    if [[ "$interval" -gt 1440 ]]; then interval=1440; fi
    echo "$interval"
}

log() {
    echo "[$(date -Iseconds)] $1" | tee -a "$LOG_FILE"
}

# The reliable check - runs on fixed interval, never changes
do_check() {
    local interval_min=$(get_interval)
    local timestamp=$(date -Iseconds)
    
    # Always log that daemon ran (THIS IS THE HEARTBEAT)
    log "HEARTBEAT CHECK: interval=${interval_min}min timestamp=$timestamp"
    
    # Update check file for Web UI
    cat > "$CHECK_FILE" << EOF
{
  "last_check": "$timestamp",
  "interval_minutes": $interval_min,
  "next_check": "$(date -d "+${interval_min} minutes" -Iseconds)"
}
EOF
    
    # Look for tasks needing AI attention
    local found_count=0
    for task_file in "$AUTONOMY_DIR"/tasks/*.json; do
        [[ -f "$task_file" ]] || continue
        
        local status=$(jq -r '.status // "pending"' "$task_file" 2>/dev/null)
        local task_name=$(jq -r '.name // "unknown"' "$task_file" 2>/dev/null)
        
        # Skip if not flagged for AI
        [[ "$status" != "needs_ai_attention" ]] && continue
        
        # Skip continuous-improvement (neverending)
        [[ "$task_name" == "continuous-improvement" ]] && continue
        
        found_count=$((found_count + 1))
        log "FLAGGED TASK: $task_name (AI will decide what to do)"
        
        # Create notification for AI
        cat > "$AUTONOMY_DIR/state/ai-notification.json" << EOF
{
  "timestamp": "$timestamp",
  "task_name": "$task_name",
  "task_file": "$task_file",
  "message": "Task flagged by daemon - AI decides when to process",
  "daemon_cycle": "$(cat $CHECK_FILE | jq -r '.last_check // "unknown"')"
}
EOF
        
        # Only flag one task per check (prevent overload)
        break
    done
    
    if [[ $found_count -eq 0 ]]; then
        log "NO TASKS: Nothing flagged for AI"
        rm -f "$AUTONOMY_DIR/state/ai-notification.json"
    fi
    
    log "CHECK COMPLETE: Found $found_count task(s)"
}

# Main loop - RELIABLE, NEVER CHANGES INTERVAL
main_loop() {
    local interval_min=$(get_interval)
    local interval_sec=$((interval_min * 60))
    
    echo $$ > "$PID_FILE"
    log "DAEMON STARTED: Interval=${interval_min}min (${interval_sec}s) - NEVER CHANGES"
    
    while true; do
        # Check for stop signal
        if [[ -f "$AUTONOMY_DIR/state/daemon.stop" ]]; then
            rm -f "$AUTONOMY_DIR/state/daemon.stop"
            log "DAEMON STOPPED (signal received)"
            rm -f "$PID_FILE"
            exit 0
        fi
        
        # Get current interval (user might have changed it)
        local current_interval=$(get_interval)
        local current_sec=$((current_interval * 60))
        
        if [[ "$current_interval" != "$interval_min" ]]; then
            interval_min=$current_interval
            interval_sec=$current_sec
            log "INTERVAL CHANGED: Now ${interval_min}min"
        fi
        
        # DO THE CHECK
        do_check
        
        # Sleep EXACTLY the interval (check for stop every second)
        local slept=0
        while [[ $slept -lt $interval_sec ]]; do
            if [[ -f "$AUTONOMY_DIR/state/daemon.stop" ]]; then
                rm -f "$AUTONOMY_DIR/state/daemon.stop"
                log "DAEMON STOPPED (signal during sleep)"
                rm -f "$PID_FILE"
                exit 0
            fi
            sleep 1
            ((slept++))
        done
    done
}

# Allow user to change interval
cmd_set_interval() {
    local new_interval="$1"
    if [[ -z "$new_interval" ]] || ! [[ "$new_interval" =~ ^[0-9]+$ ]]; then
        echo "Usage: $0 set-interval <minutes>"
        echo "  Valid range: 1-1440 minutes (1 min to 24 hours)"
        exit 1
    fi
    
    # Update config
    local tmp_file="${CONFIG_FILE}.tmp"
    jq --arg interval "$new_interval" '.daemon.interval_minutes = ($interval | tonumber)' "$CONFIG_FILE" > "$tmp_file" 2>/dev/null || echo "{\"daemon\": {\"interval_minutes\": $new_interval}}" > "$tmp_file"
    mv "$tmp_file" "$CONFIG_FILE"
    
    echo "✅ Interval set to $new_interval minutes"
    echo "   Daemon will use this on next cycle (or restart now)"
}

# Command handling
case "${1:-status}" in
    start)
        if [[ -f "$PID_FILE" ]] && ps -p $(cat "$PID_FILE") >/dev/null 2>&1; then
            echo "Daemon already running (PID: $(cat "$PID_FILE"))"
            echo "Current interval: $(get_interval) minutes"
            exit 1
        fi
        main_loop &
        echo $! > "$PID_FILE"
        echo "✅ Daemon started"
        echo "   Interval: $(get_interval) minutes (reliable, never changes)"
        ;;
    stop)
        if [[ -f "$PID_FILE" ]]; then
            touch "$AUTONOMY_DIR/state/daemon.stop"
            sleep 2
            rm -f "$PID_FILE"
            echo "✅ Daemon stopped"
        else
            echo "Daemon not running"
        fi
        ;;
    restart)
        $0 stop 2>/dev/null
        sleep 1
        $0 start
        ;;
    status)
        if [[ -f "$PID_FILE" ]] && ps -p $(cat "$PID_FILE") >/dev/null 2>&1; then
            echo "✅ Daemon running (PID: $(cat "$PID_FILE"))"
            echo "   Interval: $(get_interval) minutes"
            if [[ -f "$CHECK_FILE" ]]; then
                cat "$CHECK_FILE" | jq -r '. | "   Last check: \(.last_check)"'
                cat "$CHECK_FILE" | jq -r '. | "   Next check: \(.next_check)"'
            fi
        else
            echo "❌ Daemon not running"
            echo "   Configured interval: $(get_interval) minutes"
        fi
        ;;
    set-interval)
        cmd_set_interval "$2"
        ;;
    check)
        # Manual check
        do_check
        ;;
    *)
        echo "Flexible Interval Autonomy Daemon"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|set-interval|check}"
        echo ""
        echo "Commands:"
        echo "  start              Start daemon with configured interval"
        echo "  stop               Stop daemon"
        echo "  restart            Restart daemon"
        echo "  status             Show daemon status and interval"
        echo "  set-interval <min> Change interval (1-1440 minutes)"
        echo "  check              Run one check manually"
        echo ""
        echo "Examples:"
        echo "  $0 set-interval 5   # Check every 5 minutes (default)"
        echo "  $0 set-interval 12  # Check every 12 minutes"
        echo "  $0 set-interval 30  # Check every 30 minutes"
        echo "  $0 set-interval 60  # Check every hour"
        exit 1
        ;;
esac
