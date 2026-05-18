# bash-katas

A reference and a progressive set of practice exercises for advanced bash.

Each exercise covers one topic with runnable snippets, then specifies a
task with at least two distinct implementations and a written trade-off.
Topics include parameter expansion, quoting, `printf`, here-docs, `find`,
`xargs`, `awk` / `sed` / `grep`, regex, `read` / `mapfile`, traps,
process substitution, coprocesses, parallel jobs, locking, atomic file
replacement, signals, locale, arithmetic, and POSIX portability — 26
exercises in total.

The repo is self-contained. Each exercise has its own README, starter,
and Bats tests under [docs/](docs/); the full index is in
[docs/README.md](docs/README.md). External references live in
[REFERENCES.md](REFERENCES.md). Open items are tracked in [TODO.md](TODO.md).

## Per-exercise structure

Every `docs/NN-slug/README.md` is laid out the same way:

```
# N. Title

**Goal:** one line.

### Techniques
  #### Trick: <name>
    <runnable bash snippet>
    What's happening: ...
    Gotcha: ...
    When to use: ...
  (3–6 of these per exercise)

### The exercise
  the problem statement; ≥2 implementations required; written trade-off

### Variants comparison
  table of approaches with fork count / portability / ergonomics

### Optional: locked-arena variant
  one tool forbidden; only listed after every approach was shown above

### Optional: scoring rubric
  4–6 self-checkable items

### Break it
  adversarial inputs to feed each solution before declaring it done
```

## Quick start

```bash
# 1. browse the exercise index
$EDITOR docs/README.md

# 2. pick an exercise; read its README
$EDITOR docs/01-expansion-prediction/README.md

# 3. copy the starter into bin/ and fill it in
cp docs/01-expansion-prediction/starter.sh bin/expand-lab
$EDITOR bin/expand-lab

# 4. lint and test inside the container
podman run --rm -v "$PWD:/work:rw" -w /work localhost/bash-katas:dev \
    scripts/shellcheck-all.sh
podman run --rm -v "$PWD:/work:rw" -w /work localhost/bash-katas:dev \
    bash -c 'find docs -name tests.bats -print0 | xargs -0 -r bats'

# 5. or drop into an interactive shell with the same toolchain
podman run --rm -it -v "$PWD:/work:rw" -w /work localhost/bash-katas:dev
```

(`make lint`, `make test`, `make shell` wrap the above when invoking
`make` from the host is acceptable.)

## Repository layout

```
.
├── README.md                       — this file
├── REFERENCES.md                   — manuals, books, tools, comparable exercise sets
├── TODO.md                         — open items
├── Containerfile                   — frozen toolchain: bash + shellcheck + bats + coreutils + gnu utils
├── Makefile                        — `make lint | test | bench | shell`
├── .shellcheckrc                   — project-wide lint config
├── docs/
│   ├── README.md                   — exercise index + suggested order
│   ├── 01-expansion-prediction/
│   │   ├── README.md                   exercise content (techniques + task + break-it)
│   │   ├── starter.sh                  skeleton to fill in
│   │   ├── tests.bats                  Bats suite
│   │   └── solutions/                  reference implementations
│   ├── 02-nul-safe-collector/
│   └── …                            (26 exercises total)
├── bin/                            — working solutions live here
├── test/                           — cross-exercise Bats helpers
├── data/                           — fixtures (log corpora, weird-filename trees)
├── scripts/
│   ├── gen-log-corpus.sh               generate fixtures (access.log, weird-tree, repo-tree, locale corpus)
│   ├── bench.sh                        time the perf-kata modes
│   ├── scaffold-exercises.sh           regenerate starter.sh / tests.bats stubs (idempotent)
│   ├── shellcheck-all.sh               lint every script
│   └── run-in-container.sh             open a container shell with the frozen toolchain
├── lib/
│   ├── log.sh                          shared info/verbose/debug/err/die helpers
│   └── test_helpers.bash               shared Bats helpers
└── .github/workflows/ci.yml        — runs shellcheck + bats on every push
```

## Workflow per exercise

1. Read the **Techniques** section in `docs/NN-name/README.md`, running each
   snippet.
2. Read **The exercise**, **Variants comparison**, **Break it**.
3. Copy `docs/NN-name/starter.sh` to `bin/`, fill it in.
4. Treat the **Break-it** checklist as acceptance criteria — each item
   has a corresponding `@test` in `tests.bats`.
5. Lint and run tests until clean.
6. Re-solve in a different dialect (pure-bash, `awk`, coreutils pipeline)
   and write a one-paragraph trade-off comparison.

### Running tests against a candidate implementation

Each `tests.bats` resolves its solution paths as
`${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/<file>.sh`. Override
`KATA_SOL_DIR` to point at any directory whose filenames match
`docs/NN-slug/solutions/*.sh`:

```bash
# run every exercise's suite against bin/
KATA_SOL_DIR=$PWD/bin bats docs/*/tests.bats

# convenience wrapper:
scripts/test-against.sh bin            # all exercises
scripts/test-against.sh bin 09         # only exercise 9
```

When `KATA_SOL_DIR` is unset the suite runs against the reference
solutions under `docs/NN-slug/solutions/` (the default green state).

## Container

The Containerfile freezes the toolchain (bash, shellcheck, bats, gnu coreutils,
findutils, gawk, parallel, locales) so the worked snippets behave identically
on every machine. The default OCI runtime is `podman`; set `OCI=docker` in
the Makefile to switch.
