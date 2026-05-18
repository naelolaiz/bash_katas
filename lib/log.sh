# shellcheck shell=bash
# Shared logging helpers. Source from starter scripts.
#
#   source "$(dirname "$0")/../../lib/log.sh"
#
# Conventions:
#   - all log output goes to stderr (never stdout — that's reserved for data)
#   - LOG_LEVEL: 0=quiet, 1=info (default), 2=verbose, 3=debug
#   - log() prefixes with level + timestamp

LOG_LEVEL=${LOG_LEVEL:-1}

log() {
  local level=$1; shift
  (( level > LOG_LEVEL )) && return 0
  local prefix
  case $level in
    1) prefix='INFO ' ;;
    2) prefix='VERB ' ;;
    3) prefix='DEBUG' ;;
    *) prefix='?    ' ;;
  esac
  printf '%s [%(%F %T)T] %s\n' "$prefix" -1 "$*" >&2
}

info()    { log 1 "$@"; }
verbose() { log 2 "$@"; }
debug()   { log 3 "$@"; }

err() {
  printf 'ERROR [%(%F %T)T] %s\n' -1 "$*" >&2
}

die() {
  local code=$1; shift
  err "$@"
  exit "$code"
}
