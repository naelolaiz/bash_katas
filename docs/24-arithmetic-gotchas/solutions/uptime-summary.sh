#!/usr/bin/env bash
# Reference: parse /proc/uptime; print days/hours/mins, idle %, total seconds.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

src=${1:-/proc/uptime}
[[ -r $src ]] || die 2 "no such file: $src"

read -r up idle < "$src"
up_int=${up%.*}
idle_int=${idle%.*}

# Avoid the leading-zero octal trap on /proc/uptime (no leading zeros there,
# but the pattern is general): force decimal with 10# if parsing from `date`.
days=$(( up_int / 86400 ))
hours=$(( up_int % 86400 / 3600 ))
mins=$(( up_int % 3600 / 60 ))

# Integer math can't do floats — hand off to awk for the percentage.
pct=$(awk -v a="$idle_int" -v b="$up_int" 'BEGIN { if (b>0) printf "%.1f", a*100/b; else print "n/a" }')

LC_ALL=en_US.UTF-8 printf "uptime:   %dd %dh %dm\n" "$days" "$hours" "$mins"
LC_ALL=en_US.UTF-8 printf "idle:     %s%%\n" "$pct"
LC_ALL=en_US.UTF-8 printf "seconds:  %'d\n" "$up_int"
