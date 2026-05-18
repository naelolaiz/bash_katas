# Hints for `buggy.sh` (exercise 23)

Run the script under different `LC_ALL` values (`C`, `en_US.UTF-8`,
`tr_TR.UTF-8`, `de_DE.UTF-8`) and watch the answers diverge.

## Hint 1 — locations
1. `comm -23 <(sort A) <(sort B)`  — sort uses LC_COLLATE; on different
   machines you get different alignments and silent comm misbehaviour.
2. `grep -o '[A-Z]'`               — `[A-Z]` is a RANGE, ordered by
   collation. Under some locales it includes lowercase letters. Use
   `[[:upper:]]` for "uppercase letters" semantics.
3. `tr A-Z a-z`                    — operates on bytes. `Ü` is a 2-byte
   UTF-8 sequence, not one ASCII byte; `tr` leaves it alone. For Unicode
   case-folding you need `awk` with locale, or `python3 -c`.
4. `sort` (no `-V`)                — lexical: `v1.10` < `v1.2` < `v1.20`
   < `v2.1`. Use `-V` for version-aware sort.
5. `[[ $s == *[[:alpha:]]* ]]`     — `[[:alpha:]]` is locale-aware in bash;
   `naïve` matches under `en_US.UTF-8` but may fail under `LC_ALL=C`
   because `ï` isn't ASCII-alpha there.

## Hint 2 — fix sketch
```diff
-comm -23 <(sort "$a") <(sort "$b")
+comm -23 <(LC_ALL=C sort "$a") <(LC_ALL=C sort "$b")

-echo 'Hello WORLD' | grep -o '[A-Z]'
+echo 'Hello WORLD' | LC_ALL=C grep -o '[[:upper:]]'

-echo 'TÜRKİYE' | tr A-Z a-z
+# byte-level (boring but safe): leaves Ü intact
+echo 'TÜRKİYE' | tr 'A-Z' 'a-z'
+# Unicode-aware:
+echo 'TÜRKİYE' | python3 -c 'import sys; print(sys.stdin.read().lower(), end="")'

-printf '%s\n' v1.10 v1.2 v1.20 v2.1 | sort
+printf '%s\n' v1.10 v1.2 v1.20 v2.1 | sort -V

+# locale-stable alpha test:
+LC_ALL=C
+[[ $s == *[[:alpha:]]* ]]
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 23 "Trick: deterministic CSV/TSV pipelines" |
| 2   | ex. 23 "Trick: `[A-Z]` and `[[:upper:]]` differ by locale" |
| 3   | ex. 23 "Trick: Turkish dotless-i and other Unicode surprises" |
| 4   | ex. 23 "Trick: numeric vs. lexical sort" |
| 5   | same as #2; locale-dependent character classes |
