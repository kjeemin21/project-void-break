#!/usr/bin/env bash
# Run all headless GDScript tests in scripts/tests/.
#
# Each test is an `extends SceneTree` script that quit(0) on pass / quit(1) on fail.
# Godot is not assumed to be on PATH — resolve it from (in order):
#   1. first CLI argument:   ./run_tests.sh /path/to/godot
#   2. $GODOT environment variable
#   3. a bare `godot` on PATH
#
# Exit code is 0 only if every test passes.

set -u

GODOT="${1:-${GODOT:-godot}}"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "error: Godot binary '$GODOT' not found." >&2
  echo "       pass a path (./run_tests.sh /path/to/godot) or set \$GODOT." >&2
  exit 127
fi

# Run from the project root (this script's directory) so res:// paths resolve.
cd "$(dirname "$0")" || exit 1

TESTS=(
  scripts/tests/test_ship_movement.gd
  scripts/tests/test_health.gd
  scripts/tests/test_weapon.gd
  scripts/tests/test_feedback.gd
)

failed=0
for t in "${TESTS[@]}"; do
  echo "=== $t ==="
  if "$GODOT" --headless --script "$t"; then
    echo "  -> PASS"
  else
    echo "  -> FAIL"
    failed=$((failed + 1))
  fi
  echo
done

if [ "$failed" -eq 0 ]; then
  echo "All ${#TESTS[@]} test file(s) passed."
  exit 0
else
  echo "$failed of ${#TESTS[@]} test file(s) FAILED."
  exit 1
fi
