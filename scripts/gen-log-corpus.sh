#!/usr/bin/env bash
# Generate realistic-ish test corpora for several exercises.
# Outputs into data/generated/ (gitignored).
#
# Used by exercises 4 (log-count), 14 (perf), 18 (read variants), 21 (awk/sed/grep).

set -euo pipefail

cd "$(dirname "$0")/.."
out=data/generated
mkdir -p "$out"

# --- access-log style (exercise 21) ---------------------------------------
gen_access_log() {
  local n=${1:-100000} dst=$2
  awk -v n="$n" 'BEGIN{
    srand(42)
    levels[0]="INFO"; levels[1]="WARN"; levels[2]="ERROR"
    comps[0]="api"; comps[1]="db"; comps[2]="auth"; comps[3]="cache"; comps[4]="ingest"
    for (i = 0; i < n; i++) {
      ip = sprintf("10.0.%d.%d", int(rand()*256), int(rand()*256))
      lv = levels[int(rand()*3)]
      cp = comps[int(rand()*5)]
      status = (rand() < 0.95) ? 200 : (rand() < 0.6 ? 404 : 500)
      url = sprintf("/api/v1/users/%d", int(rand()*10000))
      printf "%s - - [18/May/2026:%02d:%02d:%02d +0000] \"GET %s HTTP/1.1\" %d %d %s/%s\n",
             ip, int(rand()*24), int(rand()*60), int(rand()*60),
             url, status, int(rand()*5000)+100, lv, cp
    }
  }' > "$dst"
}

# --- log-count corpus (exercise 4) ---------------------------------------
gen_log_count() {
  local n=${1:-100000} dst=$2
  awk -v n="$n" 'BEGIN{
    srand(43)
    levels[0]="INFO"; levels[1]="WARN"; levels[2]="ERROR"
    comps[0]="api"; comps[1]="db"; comps[2]="auth"
    msgs[0]="started"; msgs[1]="ready"; msgs[2]="failed"; msgs[3]="slow"
    for (i = 0; i < n; i++) {
      lv = levels[int(rand()*3)]
      cp = comps[int(rand()*3)]
      ms = msgs[int(rand()*4)]
      printf "2026-05-18 %s %s %s\n", lv, cp, ms
    }
    print ""             # one blank line
    print "malformed"    # one bad line for validation testing
  }' > "$dst"
}

# --- weird filenames tree (exercises 2, 19, 20) --------------------------
gen_weird_tree() {
  local root=$1
  rm -rf "$root"
  mkdir -p "$root/sub dir" "$root/.hidden"
  : >  "$root/a b.txt"
  : >  "$root/sub dir/normal.txt"
  : >  "$root/.hidden/dotfile.txt"
  : >  "$root/--danger"
  : >  "$root/"$'embedded\nnewline'.txt
  : >  "$root/"'*.txt'
}

# --- "repo-shaped" tree with pruneable dirs (exercise 19) -----------------
gen_repo_tree() {
  local root=$1
  rm -rf "$root"
  mkdir -p "$root"/{src,test,node_modules,.git,target,dist,.cache}
  local n=${2:-200}
  awk -v n="$n" -v root="$root" 'BEGIN{
    srand(44)
    dirs[0]="src"; dirs[1]="test"; dirs[2]="node_modules"
    dirs[3]=".git"; dirs[4]="target"; dirs[5]="dist"
    for (i = 0; i < n; i++) {
      d = dirs[int(rand()*6)]
      printf "%s/%s/file-%05d.txt\n", root, d, i
    }
  }' | while IFS= read -r path; do
    : > "$path"
  done
}

# --- locale corpus: ASCII + UTF-8 mixed (exercise 23) ---------------------
gen_locale_corpus() {
  local out_a=$1 out_b=$2
  printf '%s\n' Apple banana Cherry date Elephant > "$out_a"
  printf '%s\n' Über apple Çumberbatch Banana date > "$out_b"
}

# --- main ----------------------------------------------------------------
echo 'generating access.log (100k lines)...'   ; gen_access_log 100000 "$out/access.log"
echo 'generating big-access.log (1M lines)...' ; gen_access_log 1000000 "$out/big-access.log"
echo 'generating log-count.txt (100k lines)...' ; gen_log_count 100000 "$out/log-count.txt"
echo 'generating weird-tree/...'                ; gen_weird_tree "$out/weird-tree"
echo 'generating repo-tree/ (ex. 19)...'        ; gen_repo_tree "$out/repo-tree" 200
echo 'generating locale corpus (ex. 23)...'     ; gen_locale_corpus "$out/locale-a" "$out/locale-b"
echo "done: $(find "$out" -mindepth 1 -maxdepth 1 -printf '.' | wc -c) artefact(s) in $out"
