#!/usr/bin/env bash
# FAILING EXERCISE — buggy uptime-summary. SIX arithmetic gotchas.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

# /proc/uptime: "<seconds_up> <seconds_idle>"
read up idle < /proc/uptime                                       # BUG #1 (no -r; floats need bc)

up_int=${up%.*}
idle_int=${idle%.*}

days=$((up_int / 86400))
hours=$((up_int % 86400 / 3600))
mins=$((up_int % 3600 / 60))

# Initialise counters — under set -e, this exits if total is 0
total=0
(( total = up_int ))                                              # BUG #2 ((( x=0 )) trap when up_int happens to be 0)

# Idle percentage — INTEGER division gives 0 for small ratios
pct=$((idle_int * 100 / up_int))                                  # BUG #3 (integer; no decimal)

# At 8 AM, $(date +%H) is "08" which is invalid octal:
hour=$(date +%H)
next_hour=$((hour + 1))                                           # BUG #4 (08/09 trap)

# Large numbers — thousand separator, the bash way... or no way
printf "total seconds: %d\n" "$up_int"                            # BUG #5 (no %'d)

# Floating math via bc, but no scale:
ratio=$(echo "$idle_int / $up_int" | bc)                          # BUG #6 (default scale=0 -> "0")
echo "ratio: $ratio"

echo "up: ${days}d ${hours}h ${mins}m"
echo "idle: ${pct}%"
