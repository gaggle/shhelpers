assert_github_output() {
  run cat "$GITHUB_OUTPUT"
  assert_success

  for expected in "$@"; do
    assert_line "$expected"
  done
}

assert_github_env() {
  run cat "$GITHUB_ENV"
  assert_success

  for expected in "$@"; do
    assert_line "$expected"
  done
}
