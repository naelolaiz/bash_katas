# 12. Programmable completion


**Goal:** Write a `complete -F` function that knows your command's flags and positional args.

### Techniques

#### Trick: anatomy of a completion function

```bash
_manifest_diff() {
  local cur prev words cword
  _init_completion || return    # bash-completion helper; or do by hand below
  # cur  = word currently being completed
  # prev = previous word
  # words[] = full split command line
  # cword = index into words[] of `cur`

  case $prev in
    --output|-o) COMPREPLY=( $(compgen -f -- "$cur") ); return ;;
  esac

  if [[ $cur == -* ]]; then
    COMPREPLY=( $(compgen -W '--help --json --quiet --output' -- "$cur") )
  else
    COMPREPLY=( $(compgen -d -- "$cur") )    # directories
  fi
}
complete -F _manifest_diff manifest-diff
```

**What's happening:** bash gives the function `COMP_WORDS` (the parsed command line), `COMP_CWORD` (index of the word being completed), `COMP_LINE`, `COMP_POINT`. Your job is to set [`COMPREPLY`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-COMPREPLY) to an array of candidates. [`compgen`](https://www.gnu.org/s/bash/manual/html_node/Programmable-Completion-Builtins.html#index-compgen) generates candidates (`-W` from a wordlist, `-f` for files, `-d` for dirs, `-c` for commands, etc.).
**Gotcha:** without `_init_completion` (from `bash-completion`), you have to parse `COMP_WORDS` yourself — and the default word-splitting confuses `--key=value`. The `-- "$cur"` argument to `compgen` is important: it filters candidates to those starting with `$cur`.
**When to use:** any custom CLI you use more than once a week. Tab completion drops the cost-per-invocation noticeably.

#### Trick: filter out already-used options (no duplicates)

```bash
_dedupe_opts() {
  local opt seen=" ${COMP_WORDS[*]} "
  local pool=$1
  local out=()
  for opt in $pool; do
    [[ $seen == *" $opt "* ]] || out+=("$opt")
  done
  COMPREPLY=( $(compgen -W "${out[*]}" -- "$cur") )
}
```

**What's happening:** build a space-padded string of the current command line, then for each candidate option, check whether it already appears as a whole word. Pad with spaces on both ends so `--js` doesn't match `--json`.
**Gotcha:** the matching uses glob pattern `*" $opt "*`. If `$opt` contains glob metacharacters, you need extra escaping. Most flag names don't, but `--foo[bar]=` would break.
**When to use:** completion for flags that are sensibly one-shot (`--help`, `--verbose`, `--output FILE`).

#### Trick: completion for `--key=value`

```bash
case $cur in
  --output=*)
    local v=${cur#*=}
    COMPREPLY=( $(compgen -f -- "$v") )
    # strip the --output= prefix from each reply, bash will re-add it:
    COMPREPLY=( "${COMPREPLY[@]#--output=}" )
    return
    ;;
esac
```

**What's happening:** with `compopt -o nospace` and `--key=value` cases, the user completes the *value* part after `=`. The result must be a bare filename — bash re-prepends the prefix internally if the caller has used `compopt -o filenames`.
**Gotcha:** the `=` and `:` characters are word-break characters in `$COMP_WORDBREAKS` by default — they split `$COMP_WORDS` in surprising ways. Many completion scripts do `_get_comp_words_by_ref -n =:` to override.
**When to use:** modern CLIs that prefer `--key=value` style.

#### Trick: dynamic candidates (call the tool itself)

```bash
case $prev in
  --branch)
    COMPREPLY=( $(compgen -W "$(git branch --format='%(refname:short)' 2>/dev/null)" -- "$cur") )
    ;;
esac
```

**What's happening:** completion functions can fork. Branch names, container names, kube contexts, AWS profiles — all good candidates for "ask the underlying tool".
**Gotcha:** forks on every Tab press. Cache aggressively (`local cache_file=~/.cache/mytool-branches; [[ -f $cache_file && $(stat -c %Y "$cache_file") -gt $(($(date +%s) - 60)) ]] && ...`).
**When to use:** completion for ephemeral data (git refs, containers) where a static wordlist would be stale.

### The exercise

Write a completion file for one of your earlier scripts (recommend ex. 5 `filter-lines` or ex. 7 `manifest-diff`):

- complete `--help`, `--quiet`, all flags
- never repeat an already-supplied flag
- complete *directories* for positional args
- complete *files* for `--output FILE` / `--output=FILE`
- if the script supports `--from REF` (e.g. git ref), pull live candidates

Implement it **two ways**: (a) plain — parse `COMP_WORDS` directly, (b) using `bash-completion` helpers (`_init_completion`, `_get_comp_words_by_ref`, `_filedir`). Compare LOC and corner-case coverage.

### Variants comparison

| Approach                | LOC for typical case | Handles `--key=value` | External dep            |
| ----------------------- | -------------------- | --------------------- | ----------------------- |
| raw `COMP_WORDS`        | medium               | manual                | none                    |
| `bash-completion` helpers | small              | built-in              | bash-completion package |
| `argbash` / `argcomp`   | small + boilerplate  | yes                   | extra tool              |

### Optional: locked variant

Write the completion **without sourcing `/usr/share/bash-completion/bash_completion`** — pure `COMPREPLY` / `compgen`. Identify what `_init_completion` was providing. Where does the locked version break?

### Optional: scoring rubric

- [ ] tab on `--` shows all flags
- [ ] tab on `--ou` completes to `--output`
- [ ] tab after `--output ` completes filenames
- [ ] supplying `--help` once removes it from subsequent suggestions
- [ ] tab on a bare word at end of line completes directories
- [ ] no duplicate options
- [ ] survives [`set -u`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html) if sourced into a strict environment

### Break it

- [ ] complete in middle of command line, not just at the end
- [ ] complete after `--` (no more flags should be suggested)
- [ ] filename containing spaces — does it tab-complete with proper quoting?
- [ ] flag value with `=` (`--output=/tmp/x`)
- [ ] command typed with full path (`/usr/local/bin/manifest-diff`)



---

[← ex. 11](../11-debug-flags/) · [ex. 13 →](../13-bash-vs-posix/)
