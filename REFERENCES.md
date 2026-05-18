# References

Manuals, books, tools, and other exercise sets that the content here draws
on. The exercises are solvable using only the items in **Primary
references** — those are the canonical specs and lint tools to keep open
while working.

## Primary references (keep these open while doing exercises)

- **GNU Bash Reference Manual** — https://www.gnu.org/s/bash/manual/bash.html
  - Canonical for [Shell Parameter Expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html) (exercises 1, 3, 25)
  - Canonical for [Redirections](https://www.gnu.org/s/bash/manual/html_node/Redirections.html) (exercise 6)
  - Canonical for [Process Substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html) (exercises 6, 7)
  - Canonical for [Coprocesses](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html) (exercise 10)
- **BashFAQ** — https://mywiki.wooledge.org/BashFAQ
  - Especially [BashFAQ/105 — errexit gotchas](https://mywiki.wooledge.org/BashFAQ/105) (exercises 8, 11, 26)
  - And [BashFAQ/001 — process a file line by line](https://mywiki.wooledge.org/BashFAQ/001) (exercises 2, 18)
- **BashPitfalls** — https://mywiki.wooledge.org/BashPitfalls
  - The single best read-from-top antipattern catalogue. Every exercise's
    "Gotcha:" and "Break it" sections trace back to entries here.
- **BashGuide** — https://mywiki.wooledge.org/BashGuide
  - Slower-paced companion to BashFAQ/BashPitfalls; good for newer-to-bash readers.
- **ShellCheck wiki** — https://www.shellcheck.net/wiki/
  - Every rule page (`SC2086`, `SC2155`, etc.) is itself a mini-exercise:
    antipattern, why it fails, the fix. The repo's `.shellcheckrc` keeps
    every check on except two style-only ones.

## Tools

- **ShellCheck** — https://www.shellcheck.net — required, runs in CI.
- **Bats-core** — source: https://github.com/bats-core/bats-core ·
  docs: https://bats-core.readthedocs.io/ — test framework used by every
  `docs/NN-slug/tests.bats`. The Bats README is the primer; the project's
  `lib/test_helpers.bash` wraps the common setup.
- **GNU `parallel`** — https://www.gnu.org/software/parallel/ — alternative
  to the bash-only worker pool (exercises 9, 20).
- **`flock(1)`** from `util-linux` — https://man7.org/linux/man-pages/man1/flock.1.html
  — the locking exercise (22) depends on this.
- **`fd`** — https://github.com/sharkdp/fd — modern `find` replacement;
  mentioned as a variant in exercise 19.

## Linters, formatters, analysis

Tools that complement what's used in the repo. Most are not installed
in the Containerfile by default — install them via the host package
manager or run them via their own container image.

### Linters

- **[ShellCheck](https://www.shellcheck.net/)** — the canonical bash linter.
  Catches the BashPitfalls catalogue and most quoting/expansion bugs at
  static-analysis time. The repo runs it in CI via `scripts/shellcheck-all.sh`.

  ```bash
  shellcheck -x bin/expand-lab              # follow `source` statements
  shellcheck -s sh -x bin/portable-script   # treat input as POSIX sh
  shellcheck --severity=warning bin/        # suppress info-level notes
  ```

  Per-line suppressions: `# shellcheck disable=SC2086`. Project-wide
  config: `.shellcheckrc`.

- **[`checkbashisms`](https://manpages.debian.org/checkbashisms)** (Debian
  `devscripts`) — flags bash-specific syntax in scripts shebanged
  `#!/bin/sh`. Useful before claiming portability.

  ```bash
  checkbashisms docs/13-bash-vs-posix/solutions/tool.sh
  ```

- **[`bashate`](https://github.com/openstack/bashate)** (OpenStack) —
  style/formatting linter; complements ShellCheck's semantic checks
  with PEP-8-style rules (indent, line length, trailing whitespace).

  ```bash
  pip install bashate
  bashate -i E006 bin/   # ignore "line too long" rule
  ```

### Formatters

- **[`shfmt`](https://github.com/mvdan/sh)** (Go) — gofmt-style formatter
  for bash/sh/mksh. Re-indents, normalises quoting, simplifies redundant
  constructs.

  ```bash
  shfmt -d -i 2 -ci bin/foo   # show diff; 2-space indent; case branches indented
  shfmt -w -i 2 -ci bin/foo   # apply in place
  shfmt -ln bash -d bin/foo   # treat as bash (vs. POSIX sh)
  ```

### Editor integration

- **[bash-language-server](https://github.com/bash-lsp/bash-language-server)**
  — LSP server. Editors (VS Code, Neovim, Emacs) get inline ShellCheck
  diagnostics, hover docs, jump-to-definition for functions, completion
  for builtins and variables.

  ```bash
  npm i -g bash-language-server
  # then enable the bash LSP in the editor of choice
  ```

### Tracing / runtime analysis

- **`set -x` / `BASH_XTRACEFD`** — bash's built-in execution trace. See
  exercise 11.
- **[`bashdb`](https://bashdb.sourceforge.net/)** — gdb-style step
  debugger for bash. Built on top of `trap '...' DEBUG`.
- **[`strace`](https://man7.org/linux/man-pages/man1/strace.1.html)** —
  syscall tracer. The performance kata (exercise 14) uses
  `strace -f -c` to count fork/execve overhead.

  ```bash
  strace -f -c bin/some-script         # summary of syscall counts
  strace -f -e trace=openat bin/script # trace just openat() calls
  strace -ttT -f bin/script 2> trace   # microsecond timestamps + durations
  ```

- **[`pv`](https://www.ivarch.com/programs/pv.shtml)** — pipe-viewer;
  drop into a pipeline to see throughput.

  ```bash
  some-generator | pv | awk '{...}' > out
  ```

### Web / interactive

- **[explainshell.com](https://explainshell.com/)** — paste a shell
  command; get an annotated breakdown of every flag and operand.
- **[shellcheck.net](https://www.shellcheck.net/)** — the same linter
  in a browser, for one-off snippets.

## Books

These shaped the exercise selection beyond what the canonical docs cover.
Listed roughly in "how strongly the exercises echo each one" order.

- **Chris F. A. Johnson — *Pro Bash Programming*** (Apress, 2nd ed. 2015)
  Pushes pure-bash idioms hard. Exercises 3, 4, 14, 21 are most influenced
  by this book's "you didn't need that fork" sensibility.
- **Carl Albing & JP Vossen — *bash Idioms*** (O'Reilly, 2022)
  Modern, idiomatic-bash catalogue. Sources for exercises 16, 18, 25.
- **Robbins & Beebe — *Classic Shell Scripting*** (O'Reilly, 2005)
  Textbook on the classic Unix toolset (`awk`, `sed`, `find`, `xargs`).
  Backs exercises 19, 20, 21 directly.
- **Ian Miell — *Learn Bash the Hard Way*** (Leanpub, ongoing)
  Modern, exercise-driven. Inspired the "Break it" checklist convention.
- **William Shotts — *The Linux Command Line*** (No Starch, 2nd ed. 2019)
  Available free at https://linuxcommand.org/tlcl.php — good companion
  for readers newer to the surrounding GNU userspace.

## Comparable exercise sets / tutorials

- **exercism.io — Bash track** — https://exercism.org/tracks/bash —
  graded exercises with optional mentor review.
- **cmdchallenge.com** — one-liner shell puzzles.
- **commandlinechallenge / overthewire's Bandit** — wargame-style;
  covers the surrounding Unix environment more than bash-as-a-language.

## What to avoid

- **Mendel Cooper — *Advanced Bash-Scripting Guide* (ABS)** — comprehensive
  but promotes several patterns that BashPitfalls explicitly warns
  against (unquoted variables, `[ ]` over `[[ ]]`, `eval` for everything).
  Read alongside BashPitfalls to identify the patterns to skip.
