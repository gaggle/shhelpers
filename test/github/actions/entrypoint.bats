#!/usr/bin/env bats

root_dir="$(cd "$(dirname "$BATS_TEST_DIRNAME")/../.." && pwd)"
load "$root_dir/test_helper/load"

setup() {
    version_dir="$root_dir/.github/actions/version"
    GITHUB_OUTPUT=$(mktemp)
    GITHUB_ENV=$(mktemp)
    stub_gh_release_list "echo 'no releases found'"
    stub_git_show_ref "exit 1"
}

teardown() {
    rm -f $GITHUB_OUTPUT $GITHUB_ENV
    safe_unstub gh
    safe_unstub git
}

stub_gh_release_list() {
    restub gh "release list : $1"
}

stub_git_show_ref() {
    restub git "show-ref : $1"
}

run_entrypoint() {
    run_shell $1 "GITHUB_OUTPUT=$GITHUB_OUTPUT GITHUB_ENV=$GITHUB_ENV $2 $version_dir/entrypoint"
}

# is-default-branch

@test "is-default-branch is false if GITHUB_REF doesn't target INPUT_DEFAULT_BRANCH" {
    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=refs/heads/some-branch"

    assert_success
    assert_github_output "is-default-branch=false"
    assert_github_env "IS_DEFAULT_BRANCH=false"
}

@test "is-default-branch is true if GITHUB_REF targets INPUT_DEFAULT_BRANCH" {
    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=refs/heads/main"

    assert_success
    assert_github_output "is-default-branch=true"
    assert_github_env "IS_DEFAULT_BRANCH=true"
}

# is_releasable

@test "is-releasable is true when on default branch and tag is new" {
    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=refs/heads/main INPUT_SEMVER=1.2.3"

    assert_success
    assert_github_output "is-releasable=true"
    assert_github_env "IS_RELEASABLE=true"
}

@test "is-releasable is false when not on default branch" {
    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=refs/heads/some-branch"

    assert_success
    assert_github_output "is-releasable=false"
    assert_github_env "IS_RELEASABLE=false"
}

@test "is-releasable is false when on default branch but tag exists" {
    stub_git_show_ref "exit 0"
    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=refs/heads/main INPUT_SEMVER=1.2.3"

    assert_success
    unstub git
    assert_github_output "is-releasable=false"
    assert_github_env "IS_RELEASABLE=false"
}

# semver, major, minor, patch

@test "outputs semver from INPUT_SEMVER" {
    run_entrypoint "bash" "INPUT_SEMVER=1.2.3"

    assert_success
    assert_github_output "semver=1.2.3" "major=1" "minor=2" "patch=3"
    assert_github_env "SEMVER=1.2.3" "MAJOR=1" "MINOR=2" "PATCH=3"
}

@test "outputs semver if INPUT_SEMVER is prefixed with v" {
    run_entrypoint "bash" "INPUT_SEMVER=v1.2.3"

    assert_success
    assert_github_output "semver=1.2.3" "major=1" "minor=2" "patch=3"
    assert_github_env "SEMVER=1.2.3" "MAJOR=1" "MINOR=2" "PATCH=3"
}

@test "semver is empty if no INPUT_SEMVER" {
    run_entrypoint "bash"

    assert_success
    assert_github_output "semver=" "major=" "minor=" "patch="
    assert_github_env "SEMVER=" "MAJOR=" "MINOR=" "PATCH="
}

@test "it's an error if INPUT_SEMVER is not a valid semver" {
    run_entrypoint "bash" "INPUT_SEMVER=foo"

    assert_failure 1
    assert_line "Error: INPUT_SEMVER is not a valid semver: foo"
}

@test "handles zero version semver" {
    run_entrypoint "bash" "INPUT_SEMVER=0.0.0"
    assert_success
    assert_github_output "semver=0.0.0" "major=0" "minor=0" "patch=0"
    assert_github_env "SEMVER=0.0.0" "MAJOR=0" "MINOR=0" "PATCH=0"
}

# previous-release-tag

@test "previous-release-tag is empty if 'gh release list' reports no releases" {
    stub_gh_release_list "echo 'no releases found'"

    run_entrypoint "bash"

    assert_success
    unstub gh
    assert_github_output "previous-release-tag="
    assert_github_env "PREVIOUS_RELEASE_TAG="
}

@test "previous-release-tag finds top release tag" {
    stub_gh_release_list "echo -e v0.1.2\\\nv0.1.1"

    run_entrypoint "bash"

    assert_success
    unstub gh
    assert_github_output "previous-release-tag=v0.1.2"
    assert_github_env "PREVIOUS_RELEASE_TAG=v0.1.2"
}

@test "previous-release-tag skips non-semver tags" {
    stub_gh_release_list "echo -e foo\\\nvery-foo\\\nv0.1.2"

    run_entrypoint "bash" "INPUT_DEFAULT_BRANCH=main GITHUB_REF=123"

    assert_success
    unstub gh
    assert_github_output "previous-release-tag=v0.1.2"
    assert_github_env "PREVIOUS_RELEASE_TAG=v0.1.2"
}

# tag

@test "tag is empty if no INPUT_SEMVER" {
    run_entrypoint "bash"

    assert_success
    assert_github_output "tag="
    assert_github_env "TAG="
}

@test "outputs tag from INPUT_SEMVER" {
    run_entrypoint "bash" "INPUT_SEMVER=1.2.3"

    assert_success
    assert_github_output "tag=v1.2.3"
    assert_github_env "TAG=v1.2.3"
}

# tag-exists

@test "tag-exists is empty if no INPUT_SEMVER" {
    run_entrypoint "bash"

    assert_success
    assert_github_output "tag-exists="
    assert_github_env "TAG_EXISTS="
}

@test "tag-exists is false if INPUT_SEMVER->tag is new" {
    stub_git_show_ref "exit 1"

    run_entrypoint "bash" "INPUT_SEMVER=1.2.3"

    assert_success
    unstub git
    assert_github_output "tag-exists=false"
    assert_github_env "TAG_EXISTS=false"
}

@test "tag-exists is true if INPUT_SEMVER->tag is already released" {
    stub_git_show_ref "exit 0"

    run_entrypoint "bash" "INPUT_SEMVER=1.2.3"

    assert_success
    unstub git
    assert_github_output "tag-exists=true"
    assert_github_env "TAG_EXISTS=true"
}

# logging
@test "logs all the outputs" {
  run_entrypoint "bash" "INPUT_SEMVER=1.2.3"

  assert_output --regexp '^::group::Set outputs
GITHUB_OUTPUT:
is-default-branch=.+
is-releasable=.+
major=.+
minor=.+
patch=.+
previous-release-tag=.*
semver=.+
tag=.+
tag-exists=.+
GITHUB_ENV:
IS_DEFAULT_BRANCH=.+
IS_RELEASABLE=.+
MAJOR=.+
MINOR=.+
PATCH=.+
PREVIOUS_RELEASE_TAG=.*
SEMVER=.+
TAG=.+
TAG_EXISTS=.+
::endgroup::$'
}
