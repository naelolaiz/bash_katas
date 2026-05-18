# Hints for `buggy.sh` (exercise 3)

Five bugs. The script looks fine on `/tmp/archive.tar.gz` — every bug
fires on a different adversarial input from the README's "Break it" list.

## Hint 1 — vague

Try each input from the README:
- `pathinfo /foo.bar/baz`
- `pathinfo .hidden`
- `pathinfo /tmp/`
- `pathinfo -rf`
- `pathinfo $'a\nb/c'`
- `pathinfo "/tmp/file with spaces.txt"`

Each of these triggers a different bug.

## Hint 2 — categories

- Two bugs are about **deriving ext/stem from the wrong source string**.
  Should be derived from the basename, not from the full path.
- Two bugs are about using **backticks + unquoted variables** with
  `dirname`/`basename` — breaks on paths with spaces; doesn't disambiguate
  paths starting with `-`.
- One bug is about **`#` vs `##`** for extension extraction with
  multi-dot filenames (`a.b.c.gz`).

## Hint 3 — locations

1. `ext=${path##*.}`         — computed from `$path` not `$base`; breaks on
   `/foo.bar/baz` (ext becomes `bar/baz`)
2. `stem=${path%.*}`         — same root cause; for `/foo.bar/baz` the
   stem includes the dir
3. ``dir=`dirname $path` ``  — backticks; `$path` unquoted; no `--` separator
4. ``base=`basename $path` `` — same problems as #3
5. `ext=${base#*.}`          — `#` is shortest-prefix; for `a.b.c.gz` it
   returns `b.c.gz`. For an extension you want `##` (longest-prefix)

## Hint 4 — minimal fix sketch

```diff
-  ext=${path##*.}
-  stem=${path%.*}
-  dir=`dirname $path`
-  base=`basename $path`
-  if [[ $base == *.* ]]; then
-    ext=${base#*.}
-  fi
+  dir=$(dirname  -- "$path")
+  base=$(basename -- "$path")
+  if [[ $base == *.* && $base != .* ]]; then
+    ext=${base##*.}
+    stem=${base%.*}
+  else
+    ext=
+    stem=$base
+  fi
```

(`$(...)` over backticks for nestability; `--` to handle filenames
starting with `-`; quoting; basename-then-decompose pattern.)

## Why these matter

| Bug | Antipattern reference |
| --- | --------------------- |
| 1,2 | the README's "Trick: `${file##*/}`" — *extract base first, then ext/stem from base* |
| 3   | ShellCheck SC2006 (backticks), SC2086 (unquoted), SC2155 |
| 4   | same as 3 |
| 5   | the README's "Gotcha: extract `base` first, then `ext`/`stem` from `base`, not from `path`" |
