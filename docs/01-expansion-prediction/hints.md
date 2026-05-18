# Hints for `buggy.sh` (exercise 1)

Five bugs are planted. Read hints in order; stop as soon as one is enough.

## Hint 1 — vague

Four of the bugs are about **quoting**. One is about **picking the wrong
parameter-expansion operator**.

## Hint 2 — categories

- Three places loop or iterate over variables WITHOUT quotes — they break
  on arguments containing whitespace.
- One place prints a label and value WITHOUT quotes — the `printf %q` call
  needs each argument as a single token, but it's getting word-split.
- One place uses a `%` (suffix-strip) operator where `#` (prefix-strip) is
  the right operator for "extract the extension".

## Hint 3 — locations

Look at:

1. `for arg in $@`            — needs proper iteration form
2. `printf … %q\n' $label $value` — values get word-split before printf sees them
3. `echo "  $label = $value"` — `echo` mangles values starting with `-` or
   containing `\`; `printf` is the safe form
4. `for path in ${args[@]}`   — array expansion without quotes
5. `emit ext "${path%.*}"`    — `%` strips a suffix; for the final
   extension you want `${path##*.}`

## Hint 4 — full diff

Compare:
```
diff -u docs/01-expansion-prediction/buggy.sh \
        docs/01-expansion-prediction/solutions/expand-lab.sh
```

But: the reference solution restructures more than the bug-fix needs.
The minimal fixes are:

1. `for arg in $@` → `for arg in "$@"` (and ideally use `while/case` to
   support `--`)
2. `printf '  %-8s = %q\n' $label $value` → `printf '  %-8s = %q\n' "$label" "$value"`
3. `echo "  $label = $value"` → `printf '  %-8s = %s\n' "$label" "$value"`
4. `for path in ${args[@]}` → `for path in "${args[@]}"`
5. `emit ext "${path%.*}"` → `emit ext "${path##*.}"`

## Why these matter

| Bug | Antipattern reference |
| --- | --------------------- |
| 1   | BashPitfalls #1 (Unquoted variables) |
| 2   | BashPitfalls #1 |
| 3   | BashFAQ/072 — Why doesn't echo do what I mean? |
| 4   | BashPitfalls #1, especially for `[@]` arrays |
| 5   | the exercise's own "Trick: `${path##*/}` and `${path%.*}`" section |
