# 25. Here-docs, [here-string](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Strings)s, and quoting operators


**Goal:** Pick the right form of "embedded literal" and the right quoting transform for the situation.

### Techniques

#### Trick: `<<EOF` (expansion) vs. `<<'EOF'` (no expansion)

```bash
name='alice'
cat <<EOF       # expansion happens
hello $name
EOF
# hello alice

cat <<'EOF'     # quoting the marker -> no expansion
hello $name
EOF
# hello $name
```

**What's happening:** without quoting on the delimiter, `$VAR`, `$(cmd)`, and `\` escapes are expanded in the heredoc body — same rules as inside double quotes. Quoting the delimiter (any quotes — `'EOF'`, `"EOF"`, even `\EOF`) suppresses ALL expansion.
**Gotcha:** `<<EOF` heredocs containing `$something` where `something` *might* be unset can break silently. For embedding arbitrary code/SQL/config, default to `<<'EOF'` and explicitly do substitution where needed (via `sed` or `envsubst`).
**When to use:** `<<EOF` only when you specifically *want* substitution. `<<'EOF'` for anything that should be treated as literal text.

#### Trick: `<<-EOF` — strip leading TABS

```bash
if true; then
    cat <<-EOF
        line one
        line two
    EOF
fi
```

**What's happening:** `<<-` (note the dash) strips LEADING TAB characters from each line of the body AND from the closing delimiter. Lets you indent the heredoc visually without that indentation appearing in the output.
**Gotcha:** **only tabs, not spaces** — if your editor expands tabs, `<<-` silently does nothing. Use a tab-aware editor or fall back to other indentation strategies. The closing `EOF` itself must also be tab-indented (or at column 0); space-indented closers are not recognised.
**When to use:** heredocs inside indented blocks where you want the heredoc body to look indented in the source.

#### Trick: `<<<` here-string

```bash
read -r first second third <<< 'one two three'
echo "$second"     # two

[[ 'hello' =~ ^h(.+)o$ ]] <<< 'unused; here-string is the operand of the [[ ]] redirect... wait, no'
# That doesn't make sense. Here's a real example:
grep -c 'foo' <<< 'foofoo bar foo'    # 1 (lines containing 'foo', not occurrences)
```

**What's happening:** `<<< STRING` redirects STRING (with a trailing newline added) to the command's stdin. Shorter than a one-line heredoc. Variable substitution happens normally.
**Gotcha:** `<<<` adds a trailing newline. `printf %s "$x" | cmd` gives you control over that; `cmd <<< "$x"` always appends `\n`. For passing a value to `read`, the trailing newline doesn't matter.
**When to use:** "I want to feed exactly one short string to a command's stdin" — common with `read`, `grep`, `bc`.

#### Trick: capturing stdout + stderr together

```bash
# both to the same file
some-command &> /tmp/out          # bash shortcut for > /tmp/out 2>&1
some-command > /tmp/out 2>&1      # POSIX form

# capture combined output into a variable
combined=$(some-command 2>&1)

# tee both to terminal AND file
some-command 2>&1 | tee /tmp/out

# tee, but keep separate streams:
some-command > >(tee /tmp/out.log) 2> >(tee /tmp/err.log >&2)
```

**What's happening:** `&>` and `&>>` are bash shortcuts; the long form `> file 2>&1` is POSIX. Order matters (see ex. 6). To split them again into separate sinks, use [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html) (ex. 6).
**Gotcha:** in `cmd1 2>&1 | cmd2`, the `2>&1` redirects stderr to wherever stdout points *at that moment* — which is the pipe to `cmd2`. `cmd1 | cmd2 2>&1` is different: it sends `cmd2`'s stderr (NOT `cmd1`'s) to the terminal-or-wherever stdout points.
**When to use:** `&> file` for "I just want everything in one log". The split-tee form when you want both interleaved on the terminal but separately archived.

#### Trick: [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) operators `@Q`, `@P`, `@A`, `@E`, `@K`

```bash
weird=$'hello\nworld'

echo "${weird@Q}"   # 'hello'$'\n''world'  — re-parseable
echo "${weird@A}"   # weird='hello'$'\n''world'  — re-parseable as an assignment
echo "${weird@K}"   # bash 5+: like @A but for arrays — round-trippable serialization

PS1_template='\u@\h:\w\$ '
echo "${PS1_template@P}"   # nael@host:~/x$  — expanded as if it were a prompt string

x='\t\n'
echo "${x@E}"       # actual TAB and NEWLINE — interprets backslash escapes

arr=(a b c)
declare -p arr      # declare -a arr=([0]="a" [1]="b" [2]="c")  — same idea but works on bash 3+
```

**What's happening:** `@Q` quotes for re-parsing. `@A` makes it an assignment (`name=value`). `@P` interprets prompt-string escapes (`\u`, `\h`, `\w`, etc.). `@E` interprets backslash escapes (`\t`, `\n`, `\xNN`). `@K` (bash 5+) serialises arrays in a re-parseable way.
**Gotcha:** `@Q`, `@P`, etc. require bash 4.4+. For older bash, use `printf '%q'`, `eval`-based prompt expansion, `printf '%b'` for escape interpretation.
**When to use:** `@Q` for safe logging. `@A` and `declare -p` for serialising state to disk and reading it back. `@E` for processing user input that contains escape sequences (`\n` should become a newline).

#### Trick: `declare -p` for round-trippable serialisation

```bash
arr=(a "b c" $'d\ne')
declare -A m=([one]=1 [two]=2)
declare -p arr m > /tmp/state

# later:
source /tmp/state
echo "${arr[1]}"     # b c
echo "${m[two]}"     # 2
```

**What's happening:** `declare -p NAME` prints a `declare` command that recreates the variable exactly — with all flags, all attributes, full quoting. Source the file back to restore state.
**Gotcha:** `source` (or `.`) runs the file in the current shell — security-sensitive. Don't `source` files you don't fully trust. For untrusted state, parse it explicitly.
**When to use:** snapshotting bash state to disk (long-running batch jobs that resume after a restart), caching expensive associative-array computations.

### The exercise

Write `bin/template` — a minimal templating tool:

```
template [--strict] TEMPLATE.tmpl
```

- substitutes `$VAR` and `${VAR}` from the environment
- with `--strict`, errors out on any unset variable
- supports `${VAR:-default}` syntax inside the template
- preserves all other characters exactly (including `\` and `$$` literals)

Implement **three ways**:

1. `eval "cat <<EOF"` — abusing heredoc expansion (compact, but dangerous if template contains backticks)
2. `envsubst` (gettext) — purpose-built, safe
3. `awk` substitution — most control, most code

Then write `bin/snapshot-state` that uses `declare -p` to serialise an [associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html) to a file, plus `bin/restore-state` that reads it back.

### Variants comparison: "embed a multi-line literal"

| Form              | Expansion | Tab strip | Use case                            |
| ----------------- | --------- | --------- | ----------------------------------- |
| `<<EOF`           | yes       | no        | dynamic templates                   |
| `<<'EOF'`         | no        | no        | embedded scripts, configs, SQL      |
| `<<-EOF`          | yes       | yes (tabs)| heredocs inside indented blocks     |
| `<<-'EOF'`        | no        | yes (tabs)| same, no expansion                  |
| `<<< "$str"`      | yes       | n/a       | one-line input to stdin             |

### Optional: locked variant

Implement `template` **without `eval`** and **without `envsubst`** — pure bash. Parse `$VAR` and `${VAR}` and `${VAR:-default}` yourself with a state machine (or regex + loop). Why is this safer than the `eval` version?

### Optional: scoring rubric

- [ ] all three template variants handle `$VAR`, `${VAR}`, `${VAR:-default}`
- [ ] `--strict` errors on unset variables (exit 2)
- [ ] template containing `` ` `` (backtick) doesn't execute under any variant
- [ ] template containing `$(...)` doesn't execute under any variant
- [ ] `snapshot-state` + `restore-state` round-trip an assoc-array with weird keys/values
- [ ] passes `shellcheck` clean

### Break it

- [ ] template containing `$$` (the shell PID variable) — should it expand or stay literal?
- [ ] template with a `$VAR` where `VAR` contains a `$` — does it re-expand?
- [ ] template with embedded `\n` (literal backslash-n) — preserved?
- [ ] heredoc with a closing delimiter that appears as a substring of a body line
- [ ] state file containing values with `\n`, `'`, `"`, `\`
- [ ] `source` a state file written by a different bash version



---

[← ex. 24](../24-arithmetic-gotchas/) · [ex. 26 →](../26-signal-handling/)
