# Failing exercises — find and fix the planted bugs

This branch (`failing-exercises`) adds a second mode of practice on top of
the same 26 exercises.

Each `docs/NN-slug/buggy.sh` is a script that **looks** like a reasonable
solution to its exercise but contains 3–5 deliberately-planted bugs taken
from the BashPitfalls / Break-it catalogue. Your job is to find and fix
them — *not* to rewrite from scratch.

The bugs are designed to be:

- **Tricky** — the script appears to work on the obvious inputs.
- **Misleading** — the code uses idioms that are almost right (and that
  experienced bash users do write).
- **Diagnosable from the Bats suite** — `tests.bats` (the same one as on
  `main`) reproduces the failure modes. A clean `bats` run is your goal.

## Workflow

```bash
# pick an exercise that has a buggy.sh on this branch
podman run --rm -v "$PWD:/work:rw" -w /work localhost/bash-katas:dev \
    bats docs/01-expansion-prediction/tests.bats
# observe which @test fails, and why

# read the buggy script
$EDITOR docs/01-expansion-prediction/buggy.sh

# OPTIONAL: peek at progressively-disclosed hints
$EDITOR docs/01-expansion-prediction/hints.md

# fix the bugs in place; re-run tests until clean
podman run --rm -v "$PWD:/work:rw" -w /work localhost/bash-katas:dev \
    bats docs/01-expansion-prediction/tests.bats

# when clean, diff against the reference solution to see what you missed
diff -u docs/01-expansion-prediction/buggy.sh \
        docs/01-expansion-prediction/solutions/expand-lab.sh | less
```

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

Read hints in order. The point is to give you the smallest nudge you
need, not the full diff.

## Scope on this branch

The branch ships buggy.sh for **exercises 1, 2, 3 only** — same scope as
the reference solutions on `main`. Adding more is a good way to deepen
your own understanding: pick an exercise that bit you, plant the bug
you fell for, write it up. (See TODO.md for the open list.)

## What the bugs come from

Every planted bug traces to one of:

- a BashPitfalls entry (`mywiki.wooledge.org/BashPitfalls`)
- a BashFAQ entry (especially FAQ/001 and FAQ/105)
- a ShellCheck rule (the wiki page is the reading list)
- a "Gotcha:" or "Break it" entry from the same exercise's `README.md`

If a bug doesn't trace to one of those, it's not a good failing-exercise
bug — it's just a typo. Don't plant those.
