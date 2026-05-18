# Hints for `buggy.sh` (exercise 19)

Five bugs. Three are "works but slow"; two are "wrong result".

## Hint 1 — locations
1. `-not -path '*/node_modules/*'`  — descends INTO node_modules anyway,
   just doesn't print results. On a real tree this is 100× slower than
   `-prune`. Use `\( -name node_modules -o -name .git \) -prune -o -type f -print`.
2. `-exec stat ... \;`              — fork per file. Use `-exec stat ... +`
   for batching, OR replace stat with `find -printf` entirely.
3. `-mtime -1`                       — `-mtime` units are 24-HOUR PERIODS,
   rounded toward zero. `-mtime -1` means "modified in the last 0–24h
   exactly", but skips files whose mtime rounds to 1. Use `-mmin -1440`.
4. `-printf '%T@'`                   — emits Unix epoch seconds. The exercise
   asks for ISO format. Use `%TY-%Tm-%Td %TH:%TM:%TS`.
5. `-regex '.*/[a-z]+\.go'`         — default regex is POSIX BASIC, where
   `+` is literal. Add `-regextype posix-extended`.

## Hint 2 — fix sketch
```diff
-find "$dir" -type f \
-  -not -path '*/node_modules/*' \
-  -not -path '*/.git/*' \
-  -exec stat -c '%s %y %n' {} \;
+find "$dir" \
+  \( -name node_modules -o -name .git \) -prune -o \
+  -type f -printf '%s\t%TY-%Tm-%Td %TH:%TM:%TS\t%p\n'

-find "$dir" -type f -name '*.log' -mtime -1
+find "$dir" -type f -name '*.log' -mmin -1440

-find "$dir" -printf '%p %T@\n'
+find "$dir" -printf '%p\t%TY-%Tm-%Td %TH:%TM:%TS\n'

-find "$dir" -regex '.*/[a-z]+\.go'
+find "$dir" -regextype posix-extended -regex '.*/[a-z]+\.go'
```

## Why
| Bug | Reference |
| --- | --------- |
| 1   | ex. 19 "Trick: `-prune` — the *only* correct way to skip a subtree" |
| 2   | ex. 19 "Trick: `-exec ... +` vs `-exec ... \;`" |
| 3   | ex. 19 "Trick: `-newer` and `-newermt`" — *"`-mtime` units are 24h periods"* |
| 4   | ex. 19 "Trick: `-printf` formats" |
| 5   | ex. 19 "Trick: `-regex` and `-regextype`" |
