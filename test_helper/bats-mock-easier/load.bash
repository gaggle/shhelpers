restub() {
  safe_unstub "$1"
  stub "$1" "$2"
}

safe_unstub() {
  unstub "$1" 2>/dev/null || true
}
