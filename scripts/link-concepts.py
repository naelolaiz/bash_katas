#!/usr/bin/env python3
"""Add first-mention-per-file documentation links to per-exercise READMEs.

Idempotent: skips a substitution if the linked form is already present
anywhere in the file.

Intentionally avoids touching:
- code blocks (lines inside ``` ... ```)
- existing markdown links
"""
import re
import sys
from pathlib import Path

# (pattern as a literal substring, linked-form replacement)
LINKS = [
    # bash language features (backtick-wrapped names)
    ("`mapfile`",       "[`mapfile`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-mapfile)"),
    ("`readarray`",     "[`readarray`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-readarray)"),
    ("`coproc`",        "[`coproc`](https://www.gnu.org/s/bash/manual/html_node/Coprocesses.html)"),
    ("`getopts`",       "[`getopts`](https://www.gnu.org/s/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts)"),
    ("`complete`",      "[`complete`](https://www.gnu.org/s/bash/manual/html_node/Programmable-Completion-Builtins.html#index-complete)"),
    ("`compgen`",       "[`compgen`](https://www.gnu.org/s/bash/manual/html_node/Programmable-Completion-Builtins.html#index-compgen)"),
    ("`COMPREPLY`",     "[`COMPREPLY`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-COMPREPLY)"),
    ("`BASH_REMATCH`",  "[`BASH_REMATCH`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fREMATCH)"),
    ("`PIPESTATUS`",    "[`PIPESTATUS`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PIPESTATUS)"),
    ("`BASH_XTRACEFD`", "[`BASH_XTRACEFD`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-BASH_005fXTRACEFD)"),
    ("`PS4`",           "[`PS4`](https://www.gnu.org/s/bash/manual/html_node/Bash-Variables.html#index-PS4)"),
    ("`declare -A`",    "[`declare -A`](https://www.gnu.org/s/bash/manual/html_node/Bash-Builtins.html#index-declare)"),
    ("`set -e`",        "[`set -e`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)"),
    ("`set -u`",        "[`set -u`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)"),
    ("`pipefail`",      "[`pipefail`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)"),
    ("`errexit`",       "[`errexit`](https://www.gnu.org/s/bash/manual/html_node/The-Set-Builtin.html)"),
    ("`shopt`",         "[`shopt`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html)"),
    ("`globstar`",      "[`globstar`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-globstar)"),
    ("`nullglob`",      "[`nullglob`](https://www.gnu.org/s/bash/manual/html_node/The-Shopt-Builtin.html#index-nullglob)"),
    # plain-prose concepts
    ("parameter expansion", "[parameter expansion](https://www.gnu.org/s/bash/manual/html_node/Shell-Parameter-Expansion.html)"),
    ("process substitution","[process substitution](https://www.gnu.org/s/bash/manual/html_node/Process-Substitution.html)"),
    ("associative array",   "[associative array](https://www.gnu.org/s/bash/manual/html_node/Arrays.html)"),
    ("word splitting",      "[word splitting](https://www.gnu.org/s/bash/manual/html_node/Word-Splitting.html)"),
    ("pathname expansion",  "[pathname expansion](https://www.gnu.org/s/bash/manual/html_node/Filename-Expansion.html)"),
    ("here-document",       "[here-document](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Documents)"),
    ("here-string",         "[here-string](https://www.gnu.org/s/bash/manual/html_node/Redirections.html#Here-Strings)"),
    # external tools (backticked)
    ("`xargs`",     "[`xargs`](https://man7.org/linux/man-pages/man1/xargs.1.html)"),
    ("`flock`",     "[`flock`](https://man7.org/linux/man-pages/man1/flock.1.html)"),
    ("`mktemp`",    "[`mktemp`](https://man7.org/linux/man-pages/man1/mktemp.1.html)"),
    ("`strace`",    "[`strace`](https://man7.org/linux/man-pages/man1/strace.1.html)"),
    ("`jq`",        "[`jq`](https://jqlang.github.io/jq/)"),
    ("`dash`",      "[`dash`](https://man7.org/linux/man-pages/man1/dash.1.html)"),
    # standards
    ("BashPitfalls",        "[BashPitfalls](https://mywiki.wooledge.org/BashPitfalls)"),
    ("BashFAQ/001",         "[BashFAQ/001](https://mywiki.wooledge.org/BashFAQ/001)"),
    ("BashFAQ/105",         "[BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105)"),
]


def replace_first_outside_codeblocks_and_links(text: str, needle: str, replacement: str) -> str:
    """Replace only the first occurrence of `needle` that is NOT inside a
    fenced code block (``` ... ```) and NOT already part of a markdown link.
    Returns the modified text, or the original if no eligible match found.
    """
    if replacement in text:
        return text  # already linked somewhere; leave alone

    out_lines = []
    in_fence = False
    replaced = False

    for line in text.splitlines(keepends=True):
        stripped = line.lstrip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            out_lines.append(line)
            continue
        if in_fence or replaced:
            out_lines.append(line)
            continue
        # Skip if needle is inside an existing [text](url) link on this line
        # — too fiddly to detect perfectly; use a simple heuristic: if the
        # exact occurrence is preceded by `[`, skip.
        idx = line.find(needle)
        if idx == -1:
            out_lines.append(line)
            continue
        # Heuristic: if needle is preceded by `[` it's already in a link label
        if idx > 0 and line[idx - 1] == "[":
            out_lines.append(line)
            continue
        # Replace just this occurrence
        line = line[:idx] + replacement + line[idx + len(needle):]
        out_lines.append(line)
        replaced = True

    return "".join(out_lines)


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: link-concepts.py FILE [FILE...]", file=sys.stderr)
        return 2
    for arg in sys.argv[1:]:
        p = Path(arg)
        text = p.read_text()
        original = text
        for needle, replacement in LINKS:
            text = replace_first_outside_codeblocks_and_links(text, needle, replacement)
        if text != original:
            p.write_text(text)
            print(f"linked: {arg}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
