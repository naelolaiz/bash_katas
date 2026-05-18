#!/usr/bin/env bash
# Generate starter.sh + tests.bats for every per-exercise directory under docs/.
# Idempotent: only writes if the target file doesn't already exist (so you
# won't lose work in progress). Re-run to add stubs for new exercises.

set -euo pipefail
cd "$(dirname "$0")/.."

# Map of exercise number -> (slug, command-name, one-line summary).
# Command-name is what the learner's main script gets called as in bin/.
declare -a META=(
  '1|01-expansion-prediction|expand-lab|labelled dump of every parameter expansion applied to its argument'
  '2|02-nul-safe-collector|collect-ext|list files under DIR with extension EXT, NUL-safe'
  '3|03-path-components|pathinfo|print original/dir/base/stem/ext for each path argument'
  '4|04-log-summariser|log-count|count log lines grouped by (level, component) from stdin'
  '5|05-cli-parsing|filter-lines|grep-like filter with -i/-v/-n/--limit (three parsing styles)'
  '6|06-fd-drill|runlog|run COMMAND while teeing stdout+stderr to LOGFILE'
  '7|07-manifest-diff|manifest-diff|diff two directories by reproducible content manifest'
  '8|08-traps-and-cleanup|safe-edit|edit FILE via COMMAND on a temp copy, atomic-replace on success'
  '9|09-parallel-worker-pool|pmap|run at most -j COMMAND invocations concurrently'
  '10|10-coprocess-mini-client|bc-client|persistent bc -l client with timeout + crash recovery'
  '11|11-debug-flags|debug-runner|wrap a command with --quiet/--verbose/--debug/--dry-run'
  '12|12-programmable-completion|filter-lines-completion|bash completion file for ex. 5 filter-lines'
  '13|13-bash-vs-posix|tool|same tool in two scripts: tool.bash and tool.sh (POSIX)'
  '14|14-performance-kata|perf-kata|process 100k+ lines; benchmark naive vs builtin vs awk vs pipeline'
  '15|15-capstone-repo-janitor|repo-janitor|find large/duplicate/junk/broken-symlinks under DIR; dry-run by default'
  '16|16-printf-deep-dive|timestamp-log|read <unix_ts>\\t<msg> on stdin, print <ISO-8601>\\t<msg>'
  '17|17-bash-rematch|parse-log|parse structured log lines with [[ =~ ]] + BASH_REMATCH'
  '18|18-read-and-mapfile|count-lines|count lines four ways; demo read/mapfile flags'
  '19|19-find-deep-dive|repo-find|list files with size + mtime, pruning node_modules/.git/etc.'
  '20|20-xargs-patterns|parallel-hash|hash every regular file under DIR in parallel'
  '21|21-awk-sed-grep-tricks|log-analyse|top-IPs, top-error-URLs, set-diff against allowlist'
  '22|22-locking-and-atomic-writes|single-instance|wrap a command so only one instance runs at a time'
  '23|23-locale-and-sorting|locale-bomb|demo locale-induced bugs; show LC_ALL=C fix'
  '24|24-arithmetic-gotchas|uptime-summary|parse /proc/uptime; report days/hours/minutes + idle %'
  '25|25-heredocs-and-quoting|template|substitute env variables in a template file'
  '26|26-signal-handling|run-with-cleanup|wrap a command; propagate signals as 128+N, ignore SIGPIPE'
)

write_starter() {
  local n=$1 slug=$2 cmd=$3 summary=$4
  local path="docs/$slug/starter.sh"
  if [[ -e "$path" ]]; then
    return 0
  fi
  cat > "$path" <<EOF
#!/usr/bin/env bash
# Exercise $n — $(echo "$slug" | sed 's/^..-//; s/-/ /g')
#
# Summary: $summary
#
# Read docs/$slug/README.md for the full tutorial and Break-it checklist.
# When ready, copy this file to bin/$cmd and edit there:
#
#   cp docs/$slug/starter.sh bin/$cmd
#
# Required: produce at least 2 distinct solutions for the same problem
# (see "The exercise" section in the README) and a short trade-off paragraph.

set -euo pipefail

# Common helpers (info/verbose/debug/err/die — see lib/log.sh).
# shellcheck source=/dev/null
source "\$(dirname "\$0")/../../lib/log.sh"

usage() {
  cat >&2 <<USAGE
usage: $cmd [options] [args...]
  see docs/$slug/README.md
USAGE
  exit 2
}

main() {
  # TODO: parse options (see ex. 5 for three styles)
  # TODO: validate inputs
  # TODO: do the work
  # TODO: emit results to stdout, logs to stderr (via info/verbose/debug)
  die 2 'not implemented yet — see docs/$slug/README.md'
}

main "\$@"
EOF
  chmod +x "$path"
}

write_tests() {
  local n=$1 slug=$2 cmd=$3 _summary=$4
  local path="docs/$slug/tests.bats"
  if [[ -e "$path" ]]; then
    return 0
  fi
  cat > "$path" <<EOF
#!/usr/bin/env bats
# Tests for exercise $n — see docs/$slug/README.md

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  STARTER="\$BATS_TEST_DIRNAME/starter.sh"
  # Prefer bin/ over starter.sh once the learner has copied it over.
  BIN="\$(project_root)/bin/$cmd"
  CMD="\$( [[ -x \$BIN ]] && echo "\$BIN" || echo "\$STARTER" )"
}

teardown() {
  teardown_tmpdir
}

@test "[$n] starter script exists and is executable" {
  [ -x "\$STARTER" ]
}

@test "[$n] shellcheck passes on starter" {
  run shellcheck --norc --rcfile="\$(project_root)/.shellcheckrc" -x "\$STARTER"
  assert_status 0
}

# --- Break-it cases (skipped until implemented) ---
# Each @test below corresponds to a checkbox in the README's "Break it" section.
# Remove the \`skip\` line as you implement each case.

@test "[$n] handles empty input / no arguments" {
  skip 'TODO: implement break-it case from README'
}

@test "[$n] handles filenames with embedded newlines" {
  skip 'TODO: implement break-it case from README'
}

@test "[$n] exits with a sensible status on error" {
  skip 'TODO: implement break-it case from README'
}
EOF
}

for spec in "${META[@]}"; do
  IFS='|' read -r n slug cmd summary <<< "$spec"
  if [[ ! -d "docs/$slug" ]]; then
    printf 'warning: docs/%s missing (run scripts/split-plan.sh first)\n' "$slug" >&2
    continue
  fi
  write_starter "$n" "$slug" "$cmd" "$summary"
  write_tests   "$n" "$slug" "$cmd" "$summary"
done

# Count what was written.
starters=$(find docs -name 'starter.sh' | wc -l)
testsuites=$(find docs -name 'tests.bats' | wc -l)
printf 'scaffolded: %d starter.sh, %d tests.bats\n' "$starters" "$testsuites"
