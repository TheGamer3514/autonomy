# Agentic Autonomy for OpenClaw

**AI-driven self-improving autonomy system.**

The AI decides what to do, creates its own tasks, and improves itself - with safety guards to prevent runaway usage.

## What It Does

Instead of following scripts, the AI:
- **Reasons** about what needs attention
- **Creates** its own tasks
- **Decides** how to solve problems
- **Verifies** its work (anti-hallucination)
- **Stops** when done (not endless building)

## Quick Start

```bash
# Activate agentic mode
autonomy on

# Give the AI work
autonomy work "Build a memory tracker for token usage"

# The AI decides, plans, builds, tests, and reports back
```

## Commands

| Command | Description |
|---------|-------------|
| `autonomy on` | Activate agentic mode |
| `autonomy off` | Deactivate |
| `autonomy work "instruction"` | Give the AI a task |
| `autonomy task list` | Show active tasks |
| `autonomy task complete <name> "proof"` | Mark done (requires proof) |
| `autonomy spawn "task"` | Spawn sub-agent |
| `autonomy schedule add <interval> <task>` | Schedule recurring work |
| `autonomy tool create <name>` | Create custom tool |
| `autonomy status` | Show workstation status |
| `autonomy update check` | Check for updates |
| `autonomy update apply` | Apply latest update |

## Safety Guards

**Hard Limits:**
- Max 5 concurrent tasks
- Max 3 sub-agents
- Max 5 schedules
- 50k daily token budget
- Max 5 iterations per task

**Anti-Hallucination:**
- Must verify work before marking complete
- Must provide proof: "Tested: X works, Y exists"
- Max 3 attempts before forced stop
- Check for existing solutions first

**Approval Required:**
- External API calls
- Sending messages
- File deletion
- Public posts
- Git push
- Installing packages

## How It Works

### 1. Heartbeat Triggers
```
OpenClaw → Read HEARTBEAT.md → AI decides what to do
```

### 2. AI Checks Workstation
- Pending tasks?
- Scheduled work due?
- What needs attention?

### 3. AI Reasons & Acts
```
"I should build a token tracker"
  ↓
Create task → Plan approach → Build → Test → Verify → Complete
```

### 4. Verification Required
```bash
# WRONG - No proof
autonomy task complete X

# RIGHT - With proof
autonomy task complete X "Tested: logs tokens, file exists with data"
```

## Example Session

```bash
# User activates autonomy
$ autonomy on
✓ Agentic Autonomy ACTIVATED

# User gives work
$ autonomy work "Create a token usage tracker"
✓ Task created: task-1234567890

# (AI takes over on next heartbeat)
# AI thinks: "I need to track tokens. I'll create a script that
# reads session status and logs to a file."

# AI builds it, tests it, verifies it works
# AI marks complete with proof:
# "Tested: Script runs, logs to /logs/tokens.jsonl, has today's data"

# User checks status
$ autonomy status
Workstation: ACTIVE
Active Tasks: 0 (all complete)
```

## Architecture

```
skills/autonomy/
├── autonomy           # Main CLI
├── config.json        # Configuration & limits
├── HEARTBEAT.md       # AI instructions (read each heartbeat)
├── ARCHITECTURE.md    # Design docs
├── checks/            # Update checker
├── lib/               # Shared libraries
├── tasks/             # Active tasks (JSON)
├── agents/            # Running agents
├── tools/             # Custom tools created by AI
├── logs/              # Activity logs
└── state/             # Runtime state
```

## Configuration

Edit `config.json`:

```json
{
  "agentic_config": {
    "hard_limits": {
      "max_concurrent_tasks": 5,
      "max_sub_agents": 3,
      "daily_token_budget": 50000
    }
  }
}
```

## Self-Update

The autonomy can update itself from GitHub:

```bash
autonomy update check    # Check if new version available
autonomy update apply    # Download and install
```

## License

MIT
