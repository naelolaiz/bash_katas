# Failing exercises — find and fix the planted bugs

This branch (`failing-exercises`) adds a second mode of practice on top of
the same 26 exercises.

Each `docs/NN-slug/buggy.sh` is a script that **looks** like a reasonable
solution to its exercise but contains 4–7 deliberately-planted bugs taken
from the [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls) /
Break-it catalogue. Find and fix them — not rewrite from scratch.

The bugs are designed to be:

- **Tricky** — the script appears to work on the obvious inputs.
- **Misleading** — the code uses idioms that are almost right (and that
  experienced bash users do write).
- **Diagnosable from the Bats suite** — `tests.bats` (the same one as on
  `main`) reproduces the failure modes. A clean `bats` run is the goal.

## Workflow

The repo ships `scripts/run-buggy.sh`, a thin wrapper that runs an
exercise's tests against a candidate file (the buggy version by default,
or any fix path):

```bash
# 1. Run the tests against the buggy version. Several @tests fail —
#    that's expected. Read the failure messages.
scripts/run-buggy.sh 01

# 2. Read the buggy script.
$EDITOR docs/01-expansion-prediction/buggy.sh

# 3. Optional: peek at the progressively-disclosed hints.
$EDITOR docs/01-expansion-prediction/hints.md

# 4. Copy buggy.sh to a working location, edit, re-test.
mkdir -p bin
cp docs/01-expansion-prediction/buggy.sh bin/expand-lab.sh
chmod +x bin/expand-lab.sh
$EDITOR bin/expand-lab.sh

scripts/run-buggy.sh 01 bin/expand-lab.sh

# 5. When clean, diff against the reference solution.
diff -u bin/expand-lab.sh \
        docs/01-expansion-prediction/solutions/expand-lab.sh | less
```

### Behind the scenes

`run-buggy.sh` stages the candidate file in a temp dir under the filename
the exercise's `tests.bats` expects, then runs bats with
`KATA_SOL_DIR` pointed at that temp dir. The override mechanism is
documented in `README.md` ("Running tests against a candidate
implementation") and is also usable directly:

```bash
KATA_SOL_DIR=$PWD/bin bats docs/01-expansion-prediction/tests.bats
```

For multi-implementation exercises (3, 13, 16, 22), the buggy candidate
is staged as the **first** reference-solution filename only; the other
variants still come from `docs/NN-slug/solutions/`. To replace several
implementations, populate a directory with the matching filenames and
use `KATA_SOL_DIR` directly.

## Hints file format

Each `docs/NN-slug/hints.md` follows a progressive-disclosure layout:

```
## Hint 1 (vague)
Something about quoting is off in two places.

## Hint 2 (location)
Look at the `for x in $list` loop and at the `printf '%q'` line.

## Hint 3 (explanation)
Inside the loop, `$list` is unquoted — word-splits on IFS …
```

Read hints in order. The point is to give the smallest nudge needed, not
the full diff.

## Scope on this branch

`buggy.sh` and `hints.md` ship for **all 26 exercises**.

## What the bugs come from

Every planted bug traces to one of:

- a [BashPitfalls](https://mywiki.wooledge.org/BashPitfalls) entry
- a BashFAQ entry (especially [BashFAQ/001](https://mywiki.wooledge.org/BashFAQ/001) and [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105))
- a [ShellCheck](https://www.shellcheck.net/wiki/) rule
- a "Gotcha:" or "Break it" entry from the same exercise's `README.md`

If a bug doesn't trace to one of those, it's not a good failing-exercise
bug — it's just a typo. Don't plant those.
