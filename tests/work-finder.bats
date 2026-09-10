#!/usr/bin/env bats

setup() {
  repo="$BATS_TEST_TMPDIR/repo"
  branch="fix/calendar-week-selection"

  git init -q -b master "$repo"
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"

  printf 'base\n' >"$repo/work.txt"
  git -C "$repo" add work.txt
  GIT_AUTHOR_DATE='2026-09-08T10:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-08T10:00:00+00:00' \
    git -C "$repo" commit -qm 'Initial commit'

  git -C "$repo" switch -q -c "$branch"
  printf 'feature\n' >>"$repo/work.txt"
  git -C "$repo" add work.txt
  GIT_AUTHOR_DATE='2026-09-09T10:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-09T10:00:00+00:00' \
    git -C "$repo" commit -qm 'Keep calendar week selection'

  printf 'follow-up\n' >>"$repo/work.txt"
  git -C "$repo" add work.txt
  GIT_AUTHOR_DATE='2026-09-09T11:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-09T11:00:00+00:00' \
    git -C "$repo" commit -qm 'Refine calendar week selection'

  git -C "$repo" switch -q master
  GIT_AUTHOR_DATE='2026-09-09T12:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-09T12:00:00+00:00' \
    git -C "$repo" merge --no-ff -qm "Merge branch '$branch' into 'master'" "$branch"
  merge_sha="$(git -C "$repo" rev-parse --short HEAD)"

  unmerged_branch="chore/document-work"
  git -C "$repo" switch -q -c "$unmerged_branch"
  GIT_AUTHOR_DATE='2026-09-09T13:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-09T13:00:00+00:00' \
    git -C "$repo" commit --allow-empty -qm 'Document work finder output'
  unmerged_sha="$(git -C "$repo" rev-parse --short HEAD)"
  git -C "$repo" switch -q master

  second_repo="$BATS_TEST_TMPDIR/second-repo"
  git init -q -b main "$second_repo"
  git -C "$second_repo" config user.name "Test User"
  git -C "$second_repo" config user.email "test@example.com"
  GIT_AUTHOR_DATE='2026-09-09T09:00:00+00:00' \
    GIT_COMMITTER_DATE='2026-09-09T09:00:00+00:00' \
    git -C "$second_repo" commit --allow-empty -qm 'Second repository work'
  second_sha="$(git -C "$second_repo" rev-parse --short HEAD)"
}

@test "reports merged branches separately with their merge commit and date" {
  run env WORK_FINDER_JOBS=1 "$BATS_TEST_DIRNAME/../scripts/work-finder" \
    -d 2026-09-09 -a 'Test User' -G -L "$BATS_TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"merged-via: $merge_sha  Merge branch '$branch' into 'master'"* ]]
  [[ "$output" == *"merged-branch: $branch"* ]]
  [[ "$output" == *"merged branches:"* ]]
  [[ "$output" == *"-> $branch merged in $merge_sha at 2026-09-09T12:00:00Z"* ]]
  [[ "$output" != *"time spent:"* ]]
}

@test "requires an explicit report option" {
  run "$BATS_TEST_DIRNAME/../scripts/work-finder" "$BATS_TEST_TMPDIR"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Select at least one report option: -L, -T, or -S TIME_WINDOWS."* ]]
}

@test "rejects invalid timeline windows" {
  run env TZ=UTC "$BATS_TEST_DIRNAME/../scripts/work-finder" \
    -d 2026-09-09 -a 'Test User' -S '08:00-12:00,11:00-13:00' "$BATS_TEST_TMPDIR"

  [ "$status" -eq 1 ]
  [[ "$output" == *"Time windows must not overlap: 11:00-13:00"* ]]
}

@test "prints all changed branches in each changed repo with elapsed time when requested" {
  run env WORK_FINDER_JOBS=1 "$BATS_TEST_DIRNAME/../scripts/work-finder" \
    -d 2026-09-09 -a 'Test User' -G -T "$BATS_TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"branch commit tables:"* ]]
  [[ "$output" != *"  commit: "* ]]
  [[ "$output" == *$'branch commit tables:\n\n    +'* ]]
  [[ "$output" == *"| merged / branch: $branch"* ]]
  [[ "$output" == *"| merged / branch: master "*" |     | merged / branch: $branch"* ]]
  [[ "$output" != *$'\n     +'* ]]
  [[ "$output" == *"| date "*" | hash "*" | msg "*" |"* ]]
  [[ "$output" == *"| 2026-09-09T10:00:00Z"*" | "*" | Keep calendar week selection"*" |"* ]]
  [[ "$output" == *"| 2026-09-09T11:00:00Z"*" | "*" | Refine calendar week selection"*" |"* ]]
  [[ "$output" == *"| time spent: 01:00 "*" |"* ]]
  [[ "$output" == *"| merged / branch: master"* ]]
  [[ "$output" == *"| 2026-09-09T12:00:00Z"*" | $merge_sha"*" | Merge branch '$branch' into 'master'"*" |"* ]]
  [[ "$output" == *"| merged / branch: $unmerged_branch"* ]]
  [[ "$output" == *"| 2026-09-09T13:00:00Z"*" | $unmerged_sha"*" | Document work finder output"*" |"* ]]
  [[ "$output" == *"REPO: $second_repo"* ]]
  [[ "$output" == *"| merged / branch: main"* ]]
  [[ "$output" == *"| 2026-09-09T09:00:00Z"*" | $second_sha"*" | Second repository work"*" |"* ]]
}

@test "combines list, branch tables, and timeline summaries" {
  run env TZ=UTC WORK_FINDER_JOBS=1 "$BATS_TEST_DIRNAME/../scripts/work-finder" \
    -d 2026-09-09 -a 'Test User' -G -L -T \
    -S '08:00-12:30,13:30-18:00' "$BATS_TEST_TMPDIR"

  [ "$status" -eq 0 ]
  [[ "$output" == *"  commit: $merge_sha  Merge branch '$branch' into 'master'"* ]]
  [[ "$output" == *"branch commit tables:"* ]]
  [[ "$output" == *"Timeline:"* ]]
  [[ "$output" == *"08:00 - 09:00  on $second_repo in main"* ]]
  [[ "$output" == *"09:00 - 10:00  on $repo in $branch"* ]]
  [[ "$output" == *"10:00 - 11:00  on $repo in $branch"* ]]
  [[ "$output" == *"11:00 - 12:00  on $repo in master"* ]]
  [[ "$output" == *"12:00 - 12:30  unknown"* ]]
  [[ "$output" == *"13:30 - 18:00  unknown"* ]]
  [[ "$output" == *"Timeline summary:"* ]]
  [[ "$output" == *"| repo: $repo"* ]]
  [[ "$output" == *"| $branch "*" | 02:00 "*" |"* ]]
  [[ "$output" == *"| master "*" | 01:00 "*" |"* ]]
  [[ "$output" == *"| $unmerged_branch "*" | 00:00 "*" |"* ]]
  [[ "$output" == *"| total time on repo "*" | 03:00 "*" |"* ]]
  [[ "$output" == *"| repo: $second_repo"* ]]
  [[ "$output" == *"| main "*" | 01:00 "*" |"* ]]
  [[ "$output" == *"total tracked time: 04:00"* ]]
  [[ "$output" == *"total unknown time: 05:00"* ]]
}