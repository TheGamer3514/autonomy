# Autonomy Bash Completion
# Source this file: source /path/to/autonomy-completion.bash

_autonomy_complete() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main commands
    local commands="status on off check action undo context config activity health help"
    
    # Context-specific completions
    case "${prev}" in
        on|context|switch)
            # Complete with available contexts
            local contexts=$(ls ~/.openclaw/workspace/skills/autonomy/contexts/*.json 2>/dev/null | xargs -n1 basename -s .json)
            COMPREPLY=( $(compgen -W "${contexts}" -- ${cur}) )
            return 0
            ;;
        action)
            COMPREPLY=( $(compgen -W "commit stash push sync" -- ${cur}) )
            return 0
            ;;
        check)
            COMPREPLY=( $(compgen -W "now" -- ${cur}) )
            return 0
            ;;
        config)
            COMPREPLY=( $(compgen -W "work-hours backup restore validate" -- ${cur}) )
            return 0
            ;;
        activity)
            COMPREPLY=( $(compgen -W "--recent --today --summary --checks --actions --errors" -- ${cur}) )
            return 0
            ;;
        -r|--recent)
            # Suggest common numbers
            COMPREPLY=( $(compgen -W "10 20 50 100" -- ${cur}) )
            return 0
            ;;
    esac
    
    # First argument - complete commands
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
        return 0
    fi
    
    # Default - no completion
    return 0
}

# Register completion
complete -F _autonomy_complete autonomy
