#!/usr/bin/env bats

root_dir="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"
load "$root_dir/test_helper/load"

setup() {
    shhelpers_dir="$root_dir/.shhelpers"
}

# Helper function to run a command; then echo PATH for specified shell
run_and_echo_path() {
    run_shell "$1" "$2 && echo \$PATH"
}

assert_added_to_path() {
    assert_output --partial "$shhelpers_dir"
    assert_success
}

assert_no_duplicates() {
    count=$(echo "$output" | tr ':' '\n' | grep -c "$shhelpers_dir")
    assert_equal $count 1
    assert_success
}

# Tests for Bash
@test "register adds its directory to PATH (Bash)" {
    run_and_echo_path "bash" "source $shhelpers_dir/register"
    assert_added_to_path
}

@test "register adds its directory to PATH (Zsh)" {
    run_and_echo_path "zsh" "source $shhelpers_dir/register"
    assert_added_to_path
}

@test "register also works with errexit and nounset (Bash)" {
    run_and_echo_path "bash" "set -eu; source $shhelpers_dir/register"
    assert_added_to_path
}

@test "register also works with errexit and nounset (Zsh)" {
    run_and_echo_path "zsh" "set -eu; source $shhelpers_dir/register"
    assert_added_to_path
}

@test "register does not add duplicate entries to PATH (Bash)" {
    run_and_echo_path "bash" "source $shhelpers_dir/register; source $shhelpers_dir/register"
    assert_no_duplicates
}

@test "register does not add duplicate entries to PATH (Zsh)" {
    run_and_echo_path "zsh" "source $shhelpers_dir/register; source $shhelpers_dir/register"
    assert_no_duplicates
}

@test "is an error if not sourced (Bash)" {
    run_and_echo_path "bash" "$shhelpers_dir/register"
    assert_failure
}

@test "is an error if not sourced (Zsh)" {
    run_and_echo_path "bash" "$shhelpers_dir/register"
    assert_failure
}
