run_shell() {
    _execute_in_shell "$1" "$2" true
}

shell() {
    _execute_in_shell "$1" "$2" false
}

_execute_in_shell() {
    local shell="$1"
    local command="$2"
    local use_run="${3:-false}"

    case "$shell" in
    bash)
        local shell_command="bash --noprofile --norc -c"
        ;;
    zsh)
        local shell_command="zsh -f -c"
        ;;
    *)
        echo "Unsupported shell: $shell" >&2
        return 1
        ;;
    esac

    if [ "$use_run" = true ]; then
        run $shell_command "$command"
    else
        $shell_command "$command"
    fi
}
