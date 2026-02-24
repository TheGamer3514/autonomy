# Architecture Decision Records

## ADR-001: Organic Adaptive Autonomy System

**Status**: Implemented  
**Date**: 2026-02-24

### Context

The autonomy system needed to evolve beyond static, hardcoded checks. Users wanted a system that could:

1. Discover what needs attention automatically
2. Adapt its behavior as a project matures
3. Provide deep, thorough improvements rather than surface-level checks
4. Work with a single command: "check my project and work on it"

### Decision

Implement an **organic adaptive autonomy system** with the following architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    ORGANIC CYCLE                            │
├─────────────────────────────────────────────────────────────┤
│  DISCOVER → ANALYZE → PLAN → EXECUTE → VERIFY → REFLECT    │
│      ↑___________________________________________↓         │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. Adaptive Lifecycle Phases

| Phase | Trigger | Focus Areas |
|-------|---------|-------------|
| **Ideation** | New project, minimal structure | Architecture, setup, initial docs |
| **Development** | Active coding, features being built | Code quality, testing, bugs |
| **Polish** | Features complete, tests passing | Performance, security, docs |
| **Maintenance** | Released, stable, low activity | Security, dependencies |
| **Sunset** | Deprecated, no commits for 180+ days | Migration docs only |

#### 2. Phase Detection

The system detects phase transitions automatically:

```bash
# Indicators checked each cycle
- Recent commit activity
- Test file presence
- Documentation completeness
- CI/CD configuration
- Version tags (releases)
- Stable branches
```

#### 3. Dynamic Focus Adaptation

Each phase has different priority weights:

```json
{
  "security": { "development": 0.7, "polish": 1.0, "maintenance": 1.0 },
  "performance": { "development": 0.5, "polish": 1.0, "maintenance": 0.8 },
  "features": { "development": 1.0, "polish": 0.3, "maintenance": 0.1 }
}
```

### Commands

```bash
# Start organic analysis
autonomy work /path/to/project

# Check status
autonomy status

# Manually advance lifecycle phase
autonomy advance

# Reset cycle
autonomy reset

# Stop automation
autonomy off
```

### State Management

```
state/
├── organic-cycle-state.json      # Current cycle position
├── discovery-results.json        # Issues found
├── current-plan.json            # Active plan
├── analysis.json                # Prioritized issues
└── state-detection.json         # Phase detection results
```

### Consequences

**Pros:**
- Self-configuring - no manual check setup
- Adapts to project maturity
- Deep, thorough improvements per cycle
- Learns from each iteration

**Cons:**
- Slower than static checks (one phase per heartbeat)
- Requires more state management
- Phase detection may need tuning

### Related Files

- `checks/organic_cycle.sh` - Main orchestrator
- `contexts/*.json` - Context configurations
- `logs/organic-cycle.jsonl` - Execution history
