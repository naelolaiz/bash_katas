#!/usr/bin/env bash
# FAILING EXERCISE — repo-janitor that's destructive on purpose. SEVEN bugs.
# CAUTION: this version will delete your files. Run only against a throwaway tree.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

dry_run=0                                                         # BUG #1 (should default to 1)
dir=$1; shift || true

# Find duplicates by hash.
declare -A first

find $dir -type f | while read path; do                          # BUG #2 (NUL-unsafe; subshell)
  h=$(sha256sum "$path" | cut -d' ' -f1)
  if [[ -n "${first[$h]}" ]]; then                                # BUG #3 (no :- under set -u)
    if (( dry_run )); then
      echo "would delete $path"
    else
      rm -f $path                                                  # BUG #4 (unquoted; no --)
    fi
  else
    first[$h]=$path
  fi
done

# Broken symlinks.
find $dir -type l -xtype l -print0 | xargs -0 rm                  # BUG #5 (always deletes, even in dry-run)

# Find generated junk.
find $dir -type d \( -name node_modules -o -name .cache \) -exec rm -rf {} \;  # BUG #6 (rm -rf in walk path race)

# All done.
exit 0                                                            # BUG #7 (no flock; concurrent runs race)
