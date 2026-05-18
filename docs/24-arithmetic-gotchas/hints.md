# Hints for `buggy.sh` (exercise 24)

Six bugs. Some fire only at specific times of day (08:xx, 09:xx) or under
specific uptime values.

## Hint 1 — locations
1. `read up idle < /proc/uptime`  — works but missing `-r`. Floats also
   can't be used in `(( ))` directly.
2. `(( total = up_int ))`           — `(( ))` returns exit status 1 when the
   result is 0. Under `set -e`, an uptime of 0 (theoretical) exits.
3. `idle_int * 100 / up_int`        — integer division. For 0.05 idle,
   you get 0. Use `bc -l` with `scale`, or `awk`.
4. `next_hour=$((hour + 1))`        — at 08:xx or 09:xx, `$hour` is `08`/`09`
   → bash parses as octal → error. Use `$((10#$hour + 1))`.
5. `printf "%d\n"` (no `%'d`)        — no thousands separator. Locale-aware
   needs `%'d` and `LC_ALL` with grouping enabled (e.g. `en_US.UTF-8`).
6. `bc` without `-l` (and without `scale`) — bc's default is `scale=0`
   so division truncates. `bc -l` sets `scale=20` by default.

## Hint 2 — fix sketch
```diff
-read up idle < /proc/uptime
+read -r up idle < /proc/uptime

-(( total = up_int ))
+: $(( total = up_int ))     # `:` swallows the (( )) exit code

-pct=$((idle_int * 100 / up_int))
+pct=$(awk -v a="$idle_int" -v b="$up_int" 'BEGIN{printf "%.1f", a*100/b}')

-hour=$(date +%H)
-next_hour=$((hour + 1))
+hour=$(date +%H)
+next_hour=$(( 10#$hour + 1 ))

-printf "total seconds: %d\n" "$up_int"
+LC_ALL=en_US.UTF-8 printf "total seconds: %'d\n" "$up_int"

-ratio=$(echo "$idle_int / $up_int" | bc)
+ratio=$(echo "scale=4; $idle_int / $up_int" | bc -l)
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 18 `read -r` |
| 2   | ex. 24 "Trick: `((expr))` exit status — 0 when result is 0"; BashFAQ/105 |
| 3,6 | ex. 24 "Trick: floating point — bash doesn't have it" |
| 4   | ex. 24 "Trick: leading-zero octal trap" |
| 5   | ex. 24 "Trick: `%-20s`, `%5d`, `%'d`" |
