#!/usr/bin/env bats
# Git filter bootstrap checks.

load "/workspace/tests/bats/helpers/common.bash"
load "/workspace/tests/bats/helpers/assertions.bash"

@test "git filter commands remain valid after a repository move" {
  local repo="$BATS_TEST_TMPDIR/filter-repo"
  local checkout="$BATS_TEST_TMPDIR/checkout"
  mkdir -p "$repo/setup/general" "$repo/ssh/config.d" "$checkout"

  cp "$REPO_DIR/.gitattributes" "$repo/"
  cp "$REPO_DIR/setup/general/common.bash" "$REPO_DIR/setup/general/02-git-filters.sh" "$repo/setup/general/"
  cp "$REPO_DIR/ssh/pkcs11-filter.sh" "$REPO_DIR/ssh/providers.mac" "$REPO_DIR/ssh/providers.fedora" "$repo/ssh/"
  cp "$REPO_DIR/ssh/config.d/private" "$repo/ssh/config.d/"
  "$REPO_DIR/ssh/pkcs11-filter.sh" clean < "$repo/ssh/config.d/private" > "$repo/ssh/config.d/private.tmp"
  mv "$repo/ssh/config.d/private.tmp" "$repo/ssh/config.d/private"

  git -C "$repo" init --quiet
  git -C "$repo" config filter.pkcs11-provider.clean cat
  git -C "$repo" config filter.pkcs11-provider.smudge cat
  git -C "$repo" add .
  git -C "$repo" config filter.pkcs11-provider.smudge /stale/ssh/pkcs11-filter.sh
  git -C "$repo" config filter.pkcs11-provider.required true

  run git -C "$repo" checkout-index --force --prefix="$checkout/stale/" -- ssh/config.d/private
  assert_failure

  run bash -c 'cd "$1" && "$1/setup/general/02-git-filters.sh" run' _ "$repo"
  assert_success

  run git -C "$repo" config --get filter.pkcs11-provider.smudge
  assert_success
  assert_output "ssh/pkcs11-filter.sh smudge"

  run git -C "$repo" checkout-index --force --prefix="$checkout/portable/" -- ssh/config.d/private
  assert_success
  local expected_provider
  case "$(uname -s)" in
    Darwin) expected_provider="/opt/homebrew/lib/libykcs11.dylib" ;;
    *) expected_provider="/usr/lib64/libykcs11.so.2" ;;
  esac
  run grep -F "PKCS11Provider $expected_provider" "$checkout/portable/ssh/config.d/private"
  assert_success
}

@test "git pull can update a filtered file after bootstrap" {
  local origin="$BATS_TEST_TMPDIR/filter-origin.git"
  local producer="$BATS_TEST_TMPDIR/filter-producer"
  local repo="$BATS_TEST_TMPDIR/filter-clone"
  mkdir -p "$producer/setup/general" "$producer/ssh/config.d"

  cp "$REPO_DIR/.gitattributes" "$producer/"
  cp "$REPO_DIR/setup/general/common.bash" "$REPO_DIR/setup/general/02-git-filters.sh" "$producer/setup/general/"
  cp "$REPO_DIR/ssh/pkcs11-filter.sh" "$REPO_DIR/ssh/providers.mac" "$producer/ssh/"
  cp "$REPO_DIR/ssh/config.d/private" "$producer/ssh/config.d/"
  "$REPO_DIR/ssh/pkcs11-filter.sh" clean < "$producer/ssh/config.d/private" > "$producer/ssh/config.d/private.tmp"
  mv "$producer/ssh/config.d/private.tmp" "$producer/ssh/config.d/private"

  git init --bare --quiet "$origin"
  git -C "$producer" init --quiet
  git -C "$producer" config user.email test@example.com
  git -C "$producer" config user.name "Filter Test"
  git -C "$producer" config filter.pkcs11-provider.clean cat
  git -C "$producer" config filter.pkcs11-provider.smudge cat
  git -C "$producer" add .
  git -C "$producer" commit --quiet -m initial
  git -C "$producer" remote add origin "$origin"
  git -C "$producer" push --quiet -u origin HEAD
  git clone --quiet "$origin" "$repo"

  printf '\n# remote update\n' >> "$producer/ssh/config.d/private"
  git -C "$producer" add ssh/config.d/private
  git -C "$producer" commit --quiet -m update
  git -C "$producer" push --quiet

  git -C "$repo" config filter.pkcs11-provider.smudge /stale/ssh/pkcs11-filter.sh
  git -C "$repo" config filter.pkcs11-provider.required true
  run git -C "$repo" pull --ff-only
  assert_failure

  run bash -c 'cd "$1" && "$1/setup/general/02-git-filters.sh" run' _ "$repo"
  assert_success
  run git -C "$repo" config --get filter.pkcs11-provider.smudge
  assert_output "ssh/pkcs11-filter.sh smudge"

  run git -C "$repo" pull --ff-only
  assert_success
  run grep -F "# remote update" "$repo/ssh/config.d/private"
  assert_success
}