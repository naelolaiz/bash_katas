# 1. Expansion prediction lab


**Goal:** Master what bash expands, when, and how — and predict the output before running.

### Techniques

#### Trick: `"$var"` vs `$var` — quoting decides [word splitting](https://www.gnu.org/s/bash/manual/html_node/Word-Splitting.html)

```bash
list="a b c"
printf 'quoted:   |%s|\n' "$list"   # one arg  -> |a b c|
printf 'unquoted: |%s|\n' $list     # three args -> |a|  |b|  |c|
```

**What's happening:** unquoted, `$list` is word-split on `IFS` (default: space/tab/newline) into separate tokens, each becoming a distinct argument. Quoted, it stays one token.
**Gotcha:** `for x in $list` is correct only while no element contains whitespace. When such an element appears, the loop splits it silently. An array (`for x in "${list[@]}"`) is the safe form.
**When to use:** quote by default. Drop quotes only when you explicitly want word splitting (which is rare in modern bash — arrays cover the use cases).

#### Trick: glob expansion follows word splitting

```bash
mkdir -p /tmp/exp && cd /tmp/exp && touch "a b.txt" c.txt
pattern='*.txt'
printf 'quoted:   |%s|\n' "$pattern"  # |*.txt|     (literal — no glob)
printf 'unquoted: |%s|\n' $pattern    # |a b.txt|  |c.txt|   (glob expanded)
```

**What's happening:** expansion order is variable substitution → word splitting → pathname (glob) expansion. Quoting suppresses both word splitting and glob expansion. Unquoted, `*.txt` becomes a glob *after* substitution, so it matches files in the current directory.
**Gotcha:** if the glob matches nothing, by default it expands to itself (the literal `*.txt`). Set `shopt -s failglob` for "match nothing = error", or [`nullglob`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-nullglob) for "match nothing = empty".
**When to use:** be deliberate. If you want a glob, leave it unquoted and consider `nullglob`. If you want a literal asterisk, quote it.

#### Trick: `"${arr[@]}"` vs `"${arr[*]}"` — element preservation vs concatenation

```bash
arr=("a b" "c d")
printf 'at:   |%s|\n' "${arr[@]}"   # |a b|  |c d|     (two args)
printf 'star: |%s|\n' "${arr[*]}"   # |a b c d|        (one arg, IFS-joined)
```

**What's happening:** quoted `[@]` expands to N separate words, one per element, preserving internal whitespace. Quoted `[*]` joins all elements with the first character of `IFS` (default: space).
**Gotcha:** `${arr[@]}` *unquoted* still splits on IFS inside each element — defeats the whole point of using an array. Always quote it: `"${arr[@]}"`.
**When to use:** `[@]` for iteration and command arguments. `[*]` only when you actually want one string (e.g. building a CSV line with `IFS=,`).

#### Trick: `${name:-default}`, `${name:=default}`, `${name:?error}`

```bash
unset n; echo "${n:-fallback}"   # fallback (substituted, n still unset)
n="";    echo "${n:-fallback}"   # fallback (empty matches :-)
n="";    echo "${n-fallback}"    #          (without : matches only unset, so empty stays empty)

unset n; echo "${n:=lazy}"; echo "n is now [$n]"   # lazy / n is now [lazy]

: "${REQUIRED:?must be set before running}"
# bash: REQUIRED: must be set before running   (and exits non-zero in a script)
```

**What's happening:** `:-` substitutes (read-only). `:=` substitutes AND assigns (sticky default). `:?` errors and exits if unset/empty. The `:` makes "" count as unset; drop the `:` to match only truly-unset.
**Gotcha:** `${1:=default}` is an error — you can't assign to positional parameters. `${REQUIRED:?...}` in an *interactive* shell just returns to the prompt instead of exiting — don't test the assertion idiom interactively and conclude it doesn't exit.
**When to use:** `:-` for read-only defaults, `:=` for compute-once lazy init, `:?` as a front-of-function precondition.

#### Trick: `${file##*/}` and `${file%.*}` — strip prefix/suffix without forks

```bash
path='/tmp/archive.tar.gz'
echo "${path##*/}"   # archive.tar.gz   (strip greediest matching prefix)
echo "${path%/*}"    # /tmp             (strip shortest matching suffix — dirname)
echo "${path%.*}"    # /tmp/archive.tar (strip shortest suffix at `.`)
echo "${path%%.*}"   # /tmp/archive     (strip greediest suffix at `.`)
echo "${path##*.}"   # gz               (final extension)
```

**What's happening:** `#`/`##` strip from the *front*; `%`/`%%` strip from the *back*. Doubling the operator makes it greedy. The pattern is a glob, not a regex.
**Gotcha:** these are silent: if the pattern doesn't match, the original string is returned unchanged — no error. Test for change explicitly when "no match" should be a failure.
**When to use:** any path manipulation. Lets you replace `basename`/`dirname`/`sed` in hot loops with zero forks.

#### Trick: `${var@Q}` — print in a re-parseable form

```bash
weird=$'name with\nnewline'
printf '%s\n' "$weird"            # prints the newline literally — output is on two lines
printf '%s\n' "${weird@Q}"        # 'name with'$'\n''newline'  — single re-parseable token
printf '%q\n' "$weird"            # same idea, works on older bash
```

**What's happening:** `@Q` produces a string that bash itself can re-parse (via `eval` or as an argument list) to reconstruct the original bytes. `printf '%q'` does the same thing pre-bash-4.4.
**Gotcha:** `@Q` is bash 4.4+. On macOS the system bash is 3.2 — use `printf '%q'` for portability.
**When to use:** debug/`--verbose` output, log lines you might want to copy-paste back into a shell, anywhere ambiguity matters.

### The exercise

Write `bin/expand-lab` that takes filenames as arguments and prints a labelled dump showing the result of every expansion above applied to each. Then create a test corpus of adversarial filenames:

```bash
mkdir -p /tmp/lab && cd /tmp/lab
touch -- "a b.txt" $'line\nbreak.txt' '*.txt' '--danger'
```

…and **predict the output for each filename before running**. Implement `expand-lab` **two ways**:

1. **Direct:** `printf '%s\n'` of each expansion. Notice how ambiguous filenames produce ambiguous output.
2. **Quoted:** use `${var@Q}` (or `printf '%q\n'`) so the diagnostic itself is unambiguous.

Compare the two outputs on the test corpus. Write a one-paragraph trade-off: which would you ship inside a real script's `--debug` mode, and why?

### Variants comparison: "safely print a filename to stdout"

| Approach                | Unambiguous? | Bash version  | Notes                                       |
| ----------------------- | ------------ | ------------- | ------------------------------------------- |
| `echo "$f"`             | no           | any           | breaks on `-e`, `-n`, embedded `\` sequences |
| `printf '%s\n' "$f"`    | partly       | any           | preserves bytes but newlines display literally |
| `printf '%q\n' "$f"`    | yes          | bash any      | re-parseable; bash-only                     |
| `printf '%s\n' "${f@Q}"`| yes          | bash 4.4+     | same idea, newer syntax                     |
| `declare -p var`        | yes          | any           | also captures name + type (good for serialising) |

### Optional: locked variant

Enumerate the test corpus **without `ls` and without `find`**. You may only use globs and [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html). You'll need `shopt -s nullglob dotglob` and a quoted array to handle empty matches and dot-files correctly:

```bash
shopt -s nullglob dotglob
files=(/tmp/lab/*)
printf '%s\n' "${files[@]}"   # zero output if the directory is empty — no spurious "*"
```

### Optional: scoring rubric

- [ ] both implementations produce identical *values* (only the rendering differs)
- [ ] correctly handles every filename in the Break-it list
- [ ] `expand-lab` itself passes `shellcheck` clean
- [ ] you wrote your prediction down before running, and noted where you were wrong
- [ ] (locked variant) enumeration produces zero output on an empty directory (no stray `*`)

### Break it

- [ ] empty filename argument: `bin/expand-lab ""`
- [ ] filename containing `$'a\nb'` (embedded newline)
- [ ] filename starting with `-` (looks like an option — use `--` separator)
- [ ] filename that is literally `*.txt` (looks like a glob)
- [ ] filename containing both `'` and `"`
- [ ] `IFS=:` set in the environment, then re-run
- [ ] script run under [`set -u`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) with a deliberately unset variable

### Reference

The bash manual's [parameter-expansion section](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) is worth reading slowly for this exercise.



---

[ex. 2 →](../02-nul-safe-collector/)
