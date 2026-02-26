#!/bin/bash
# Flexible Autonomy Daemon Demo
# User sets interval, daemon runs reliably, AI decides what to do

DEMO_DIR="/tmp/autonomy-demo"
mkdir -p "$DEMO_DIR/state" "$DEMO_DIR/logs" "$DEMO_DIR/tasks"

# Colors for demo
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "═══════════════════════════════════════════════════════════"
echo -e "  ${CYAN}🤖 AUTONOMY DAEMON DEMO${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Demo configuration
INTERVAL_MINUTES="${1:-5}"  # Default 5 min, user can set: 12, 30, 60, etc.
INTERVAL_SECONDS=$((INTERVAL_MINUTES * 60))

echo -e "⏱️  Interval set to: ${YELLOW}${INTERVAL_MINUTES} minutes${NC}"
echo ""
echo "How this works:"
echo "  1. Daemon runs every ${INTERVAL_MINUTES} minutes (RELIABLE)"
echo "  2. Checks for tasks flagged 'needs_ai_attention'"
echo "  3. If found, notifies AI (but AI decides when to act)"
echo "  4. AI can choose to: process now, defer, or skip"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Create some demo tasks
cat > "$DEMO_DIR/tasks/demo-task-1.json" << 'EOF'
{
  "name": "demo-task-1",
  "description": "Fix security vulnerability in auth",
  "status": "needs_ai_attention",
  "priority": "critical",
  "flagged_at": "2026-02-26T10:00:00+01:00",
  "flagged_by": "daemon",
  "ai_decision": null
}
EOF

cat > "$DEMO_DIR/tasks/demo-task-2.json" << 'EOF'
{
  "name": "demo-task-2",
  "description": "Update documentation",
  "status": "pending",
  "priority": "low",
  "flagged_at": null,
  "ai_decision": null
}
EOF

echo -e "${CYAN}Created 2 demo tasks:${NC}"
echo "  1. demo-task-1 (CRITICAL - needs_ai_attention)"
echo "  2. demo-task-2 (LOW - pending)"
echo ""

# Simulate daemon cycles
cycle=1
while [[ $cycle -le 3 ]]; do
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}CYCLE $cycle - $(date '+%H:%M:%S')${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Log the check
    echo "{\"cycle\": $cycle, \"timestamp\": \"$(date -Iseconds)\", \"interval_min\": $INTERVAL_MINUTES}" > "$DEMO_DIR/state/last-check.json"
    echo -e "${CYAN}[DAEMON]${NC} Heartbeat check logged at $(date '+%H:%M:%S')"
    
    # Check for tasks
    found_tasks=0
    for task_file in "$DEMO_DIR"/tasks/*.json; do
        [[ -f "$task_file" ]] || continue
        
        status=$(jq -r '.status // "pending"' "$task_file" 2>/dev/null)
        priority=$(jq -r '.priority // "normal"' "$task_file" 2>/dev/null)
        task_name=$(jq -r '.name // "unknown"' "$task_file" 2>/dev/null)
        ai_decision=$(jq -r '.ai_decision // "null"' "$task_file" 2>/dev/null)
        
        if [[ "$status" == "needs_ai_attention" ]]; then
            found_tasks=$((found_tasks + 1))
            echo ""
            echo -e "${YELLOW}📋 FOUND TASK: $task_name${NC}"
            echo "   Priority: $priority"
            echo "   Status: $status"
            echo "   AI Decision: ${ai_decision:-'Not yet decided'}"
            echo ""
            
            # Simulate AI making a decision
            if [[ "$priority" == "critical" ]]; then
                echo -e "${CYAN}[AI]${NC} 'This is CRITICAL - I'll process it now'"
                echo -e "${CYAN}[AI]${NC} Processing task..."
                sleep 1
                echo -e "${CYAN}[AI]${NC} ✅ Task completed!"
                jq '.status = "completed" | .completed = true | .ai_decision = "processed_immediately" | .completed_at = "'$(date -Iseconds)'"' "$task_file" > "${task_file}.tmp" && mv "${task_file}.tmp" "$task_file"
            else
                echo -e "${CYAN}[AI]${NC} 'This can wait - I'll handle it later'"
                jq '.ai_decision = "deferred" | .deferred_at = "'$(date -Iseconds)'"' "$task_file" > "${task_file}.tmp" && mv "${task_file}.tmp" "$task_file"
            fi
        fi
    done
    
    if [[ $found_tasks -eq 0 ]]; then
        echo -e "${CYAN}[DAEMON]${NC} No tasks need attention"
    fi
    
    echo ""
    echo -e "${YELLOW}⏱️  Next check in ${INTERVAL_MINUTES} minutes...${NC}"
    echo ""
    
    # In real mode, sleep for full interval
    # In demo mode, sleep 3 seconds between cycles
    if [[ "$2" == "--real" ]]; then
        sleep $INTERVAL_SECONDS
    else
        sleep 3
    fi
    
    cycle=$((cycle + 1))
done

echo "═══════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ DEMO COMPLETE${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Key takeaways:"
echo "  1. Daemon ran every ${INTERVAL_MINUTES} minutes RELIABLY"
echo "  2. AI decided which tasks to process and when"
echo "  3. Critical tasks processed immediately"
echo "  4. Low priority tasks deferred (AI's choice)"
echo ""
echo "To run with YOUR interval:"
echo "  ./daemon-flexible.sh 12    # 12 minutes"
echo "  ./daemon-flexible.sh 30    # 30 minutes"
echo "  ./daemon-flexible.sh 60    # 1 hour"
echo ""
