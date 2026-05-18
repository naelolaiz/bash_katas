# TODO

Deferred items. The repo is usable without them.

## Reference solutions

Every exercise (1–26) ships at least one reference solution under
`docs/NN-slug/solutions/`. The multi-variant exercises (3, 13, 16)
ship every variant. The rest ship the primary implementation only,
with alternates noted in a comment at the top.

Contributing additional variants is a useful drill: pick an alternate
approach mentioned in the exercise's `README.md`, implement it, drop it
under `docs/NN-slug/solutions/`. Conventions:

- one file per implementation (`expand-lab.sh`, `expand-lab-awk.sh`, …)
- `shellcheck`-clean (CI enforces)
- a 1-paragraph trade-off comment at the top citing fork count and the
  input-size range where the approach is the right choice

## Bats coverage

`docs/NN-slug/tests.bats` ships real assertions for every exercise
(126 tests total; CI runs them on every push). The coverage is
not exhaustive — most tests target the canonical happy path plus 2–4
Break-it items per exercise.

To deepen coverage: pick an unchecked item from the exercise's
**Break it** checklist in `README.md`, add a corresponding `@test`.

## Helper scripts

- `scripts/gen-log-corpus.sh` — generates fixtures for exercises 2, 4,
  14, 19, 21, 23.
- `scripts/bench.sh` — wraps exercise 14's `perf-kata.sh` against the
  generated corpus and reports wall/user/sys + strace summary.

## Container / CI

- `Containerfile` pins Debian trixie + the GNU toolchain. Pinning bash
  to a specific minor version (e.g. via `bash:5.2.21`) would make the
  `coproc` / `mapfile -d ''` / `printf '%(%T)T'` snippets even more
  deterministic across system updates.
- CI runs `shellcheck` and `bats` on every push. No bench job — bench
  numbers are for human reading, not gating.

## Failing-exercises branch

A separate `failing-exercises` branch holds buggy versions of every
exercise's script — tricky misleading code planted with the classic
BashPitfalls failures (unquoted globs, wrong `read` flags, `ls | xargs`,
errexit-suspended-in-conditional, etc.). The job is to find and fix
them, rather than write from scratch.

Each exercise has a `buggy.sh` + a progressive-disclosure `hints.md`
on that branch. See `BUGS.md` (branch) for the workflow.

## Naming

The project name `bash-katas` appears in `README.md`, `Containerfile`,
`Makefile`, and `scripts/run-in-container.sh`. The on-disk directory is
`bash_exercises`. A future cleanup could rename one to match the other.
