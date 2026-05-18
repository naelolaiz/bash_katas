# Exercises

26 exercises, grouped into 7 stages. Each stage builds on the previous one,
but every exercise is self-contained — techniques are demonstrated with
runnable code first, then the exercise spec follows.

## Tools and references

The exercises rely on the following tools and standards. Full reading list
in [REFERENCES.md](../REFERENCES.md).

| Topic                    | Reference                                                                                  |
| ------------------------ | ------------------------------------------------------------------------------------------ |
| bash language            | [GNU Bash Reference Manual](https://www.gnu.org/s/bash/manual/bash.html)                   |
|   parameter expansion    | [§3.5.3](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html)        |
|   redirections           | [§3.6](https://www.gnu.org/s/bash/manual/html_node/Redirections.html)                       |
|   process substitution   | [§3.5.6](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html)             |
|   arrays                 | [§6.7](https://www.gnu.org/s/bash/manual/html_node/Arrays.html)                             |
|   coprocesses            | [§3.2.5](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html)                      |
|   word splitting / IFS   | [§3.5.7](https://www.gnu.org/s/bash/manual/html_node/Word-Splitting.html)                   |
|   filename expansion     | [§3.5.8](https://www.gnu.org/s/bash/manual/html_node/Filename-Expansion.html)               |
|   quoting                | [§3.1.2](https://www.gnu.org/s/bash/manual/html_node/Quoting.html)                          |
|   conditional constructs | [§3.2.5](https://www.gnu.org/s/bash/manual/html_node/Conditional-Constructs.html)           |
|   arithmetic             | [§6.5](https://www.gnu.org/s/bash/manual/html_node/Shell-Arithmetic.html)                   |
|   set builtin (`-e`/`-u`)| [§4.3.1](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)                  |
|   programmable completion| [§8.7](https://www.gnu.org/s/bash/manual/html_node/Programmable-Completion.html)            |
| antipatterns / pitfalls  | [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls), [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105) |
| linter                   | [ShellCheck](https://www.shellcheck.net/) · [wiki](https://www.shellcheck.net/wiki/)        |
| test framework           | [Bats-core](https://github.com/bats-core/bats-core) ([docs](https://bats-core.readthedocs.io/)) |
| `flock(1)`               | [man page](https://man7.org/linux/man-pages/man1/flock.1.html)                              |
| `jq`                     | [jqlang.github.io/jq](https://jqlang.github.io/jq/)                                         |
| `dash` (POSIX shell)     | [man page](https://man7.org/linux/man-pages/man1/dash.1.html)                               |
| `awk` (GNU)              | [GNU Awk manual](https://www.gnu.org/software/gawk/manual/)                                 |
| `sed`                    | [GNU sed manual](https://www.gnu.org/software/sed/manual/)                                  |
| `grep`                   | [GNU grep manual](https://www.gnu.org/software/grep/manual/)                                |
| `find` / `xargs`         | [findutils manual](https://www.gnu.org/software/findutils/manual/)                           |
| coreutils                | [GNU coreutils manual](https://www.gnu.org/software/coreutils/manual/)                      |
| signals                  | [`signal(7)`](https://man7.org/linux/man-pages/man7/signal.7.html)                          |
| locale                   | [`locale(7)`](https://man7.org/linux/man-pages/man7/locale.7.html)                          |

## How to read an exercise

Every per-exercise `README.md` follows the same shape:

| Section                     | What it contains                                                |
| --------------------------- | --------------------------------------------------------------- |
| **Goal**                    | one-line statement of what the exercise covers                  |
| **Techniques**              | 3–6 worked snippets, each with *what's happening / gotcha / when to use* |
| **The exercise**            | the problem; required to produce ≥2 distinct implementations    |
| **Variants comparison**     | side-by-side table of approaches (forks, portability, ergonomics) |
| **Optional: locked variant**| one tool banned — forces you to wield a specific technique above |
| **Optional: scoring rubric**| 4–6 self-check items                                            |
| **Break it**                | adversarial inputs (mapped 1-to-1 to `tests.bats` `@test`s)     |

## Suggested order

| Stage | Exercises | Main skill |
| ----: | --------- | ---------- |
| 1 | [01](01-expansion-prediction/), [02](02-nul-safe-collector/), [03](03-path-components/), [16](16-printf-deep-dive/), [25](25-heredocs-and-quoting/) | [Expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html), [quoting](https://www.gnu.org/s/bash/manual/html_node/Quoting.html), strings, [`printf`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-printf), [here-docs](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Documents) |
| 2 | [04](04-log-summariser/), [05](05-cli-parsing/), [17](17-bash-rematch/), [18](18-read-and-mapfile/) | Data structures, CLI design, [regex](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html), [`read`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-read)/[`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile) |
| 3 | [06](06-fd-drill/), [07](07-manifest-diff/), [08](08-traps-and-cleanup/), [19](19-find-deep-dive/), [20](20-xargs-patterns/), [22](22-locking-and-atomic-writes/) | [FDs](https://www.gnu.org/s/bash/manual/html_node/Redirections.html), [`find`](https://www.gnu.org/software/findutils/manual/html_node/find_html/), [`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html), [locking](https://man7.org/linux/man-pages/man1/flock.1.html) and [atomic writes](https://man7.org/linux/man-pages/man2/rename.2.html) |
| 4 | [09](09-parallel-worker-pool/), [10](10-coprocess-mini-client/), [26](26-signal-handling/) | Concurrency, [coprocesses](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html), [signals](https://man7.org/linux/man-pages/man7/signal.7.html) |
| 5 | [11](11-debug-flags/), [12](12-programmable-completion/) | Debugging and interactive tooling |
| 6 | [13](13-bash-vs-posix/), [14](14-performance-kata/), [21](21-awk-sed-grep-tricks/), [23](23-locale-and-sorting/), [24](24-arithmetic-gotchas/) | [Portability](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html), performance, classic tools, [locale](https://man7.org/linux/man-pages/man7/locale.7.html), [arithmetic](https://www.gnu.org/s/bash/manual/html_node/Shell-Arithmetic.html) |
| 7 | [15](15-capstone-repo-janitor/) | Capstone: full tool design |

## All exercises

| # | Title | Headline technique |
| -: | ----- | ------------------ |
| [1](01-expansion-prediction/)   | Expansion prediction lab                      | [`${var@Q}`](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html), [quoting](https://www.gnu.org/s/bash/manual/html_node/Quoting.html), [glob expansion](https://www.gnu.org/s/bash/manual/html_node/Filename-Expansion.html) order |
| [2](02-nul-safe-collector/)     | NUL-safe file collector                       | [`find -print0`](https://www.gnu.org/software/findutils/manual/html_node/find_html/) + [`read -d ''`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-read), [globstar](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-globstar), [`git ls-files -z`](https://git-scm.com/docs/git-ls-files) |
| [3](03-path-components/)        | Path components, three ways                   | [parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) vs. [coreutils](https://www.gnu.org/software/coreutils/manual/) vs. [`awk -F/`](https://www.gnu.org/software/gawk/manual/) |
| [4](04-log-summariser/)         | Log summariser, three ways                    | bash [assoc-array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html) vs. [awk](https://www.gnu.org/software/gawk/manual/) vs. `sort \| uniq -c` |
| [5](05-cli-parsing/)            | Command-line parsing, three ways              | [`getopts`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts) vs. [GNU `getopt`](https://man7.org/linux/man-pages/man1/getopt.1.html) vs. hand-rolled |
| [6](06-fd-drill/)               | Redirections and file-descriptor drill        | [`2>&1` order](https://www.gnu.org/s/bash/manual/html_node/Redirections.html), named FDs `{fd}>`, [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html), [`PIPESTATUS`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PIPESTATUS) |
| [7](07-manifest-diff/)          | Manifest diff                                 | [process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html) + stable serialisation, [`comm`](https://www.gnu.org/software/coreutils/manual/html_node/comm-invocation.html) for set-diff |
| [8](08-traps-and-cleanup/)      | Traps, cleanup, and atomic file replacement   | [`trap`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-trap) `EXIT/INT/TERM`, [`mv` atomic-rename](https://man7.org/linux/man-pages/man2/rename.2.html), [BashFAQ/105 errexit pitfalls](https://mywiki.wooledge.org/BashFAQ/105) |
| [9](09-parallel-worker-pool/)   | Bounded parallel worker pool                  | [`wait -n`](https://www.gnu.org/s/bash/manual/html_node/Job-Control-Builtins.html), signal-safe child cleanup, exit-status aggregation |
| [10](10-coprocess-mini-client/) | Coprocess mini-client                         | [`coproc`](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html) vs. [`mkfifo`](https://man7.org/linux/man-pages/man1/mkfifo.1.html), timeout + crash recovery |
| [11](11-debug-flags/)           | Debuggable script exercise                    | rich [`PS4`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PS4), [`BASH_XTRACEFD`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fXTRACEFD), `printf %q` for dry-run, [`trap ERR`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-trap) |
| [12](12-programmable-completion/) | Programmable completion                     | [`COMP_WORDS`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-COMP_005fWORDS), [`compgen`](https://www.gnu.org/s/bash/manual/html_node/Programmable-Completion-Builtins.html#index-compgen), `--key=value` completion |
| [13](13-bash-vs-posix/)         | Bash-vs-POSIX rewrite                         | `[[ ]]` vs `[ ]`, [arrays](https://www.gnu.org/s/bash/manual/html_node/Arrays.html) vs `$@`, no-[POSIX](https://pubs.opengroup.org/onlinepubs/9699919799/) features ([mapfile](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile)/[coproc](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html)/[`<()`](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html)) |
| [14](14-performance-kata/)      | Performance kata: fork minimisation           | [`time`](https://www.gnu.org/s/bash/manual/html_node/Pipelines.html), [`strace -c`](https://man7.org/linux/man-pages/man1/strace.1.html), breakeven between bash loop and one [awk](https://www.gnu.org/software/gawk/manual/) |
| [15](15-capstone-repo-janitor/) | Capstone: repository janitor                  | combines everything; [Bats](https://github.com/bats-core/bats-core) test suite required |
| [16](16-printf-deep-dive/)      | `printf` deep-dive                            | `%q`, `%(...)T`, [`printf -v`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-printf), `%'d`, repeating format strings |
| [17](17-bash-rematch/)          | Regex with `[[ =~ ]]` and [`BASH_REMATCH`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fREMATCH) | the unquoted-pattern rule, capture groups, [ERE vs PCRE](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html) |
| [18](18-read-and-mapfile/)      | [`read`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-read) variants and [`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile) | `-t`/`-N`/`-n`/`-s`/`-a`/`-d ''`, `mapfile -d ''` callback |
| [19](19-find-deep-dive/)        | [`find`](https://www.gnu.org/software/findutils/manual/html_node/find_html/) deep-dive | `-prune`, `-execdir`, `+` vs `\;`, `-printf` formats |
| [20](20-xargs-patterns/)        | [`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html) patterns | `-0`, `-I{}`, `-P N`, `-r`, why `ls \| xargs` is broken |
| [21](21-awk-sed-grep-tricks/)   | [`awk`](https://www.gnu.org/software/gawk/manual/) / [`sed`](https://www.gnu.org/software/sed/manual/) / [`grep`](https://www.gnu.org/software/grep/manual/) tricks for bash users | `FNR==NR` two-file, `sed -i` portability, `grep -oP`, `comm` set ops |
| [22](22-locking-and-atomic-writes/) | Locking, atomic writes, single-instance scripts | [`flock`](https://man7.org/linux/man-pages/man1/flock.1.html), [`set -C`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html), [atomic `mv`](https://man7.org/linux/man-pages/man2/rename.2.html), PID-file races |
| [23](23-locale-and-sorting/)    | [Locale](https://man7.org/linux/man-pages/man7/locale.7.html) and sorting | `LC_ALL=C sort`, `[A-Z]` vs `[[:upper:]]`, Turkish dotless-i |
| [24](24-arithmetic-gotchas/)    | [Arithmetic](https://www.gnu.org/s/bash/manual/html_node/Shell-Arithmetic.html) gotchas | `((x=0))` errexit trap, leading-zero octal, base prefixes, no floats |
| [25](25-heredocs-and-quoting/)  | [Here-docs](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Documents), here-strings, and quoting operators | `<<EOF` vs `<<'EOF'` vs `<<-EOF`, `@Q`/`@P`/`@A`, [`declare -p`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-declare) |
| [26](26-signal-handling/)       | [Signal](https://man7.org/linux/man-pages/man7/signal.7.html) handling beyond EXIT/INT | `trap ERR/DEBUG/RETURN`, surviving SIGPIPE, `128+N` propagation |
