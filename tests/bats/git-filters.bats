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
  cp "$REPO_DIR/ssh/config.d/global" "$repo/ssh/config.d/"
  "$REPO_DIR/ssh/pkcs11-filter.sh" clean < "$repo/ssh/config.d/global" > "$repo/ssh/config.d/global.tmp"
  mv "$repo/ssh/config.d/global.tmp" "$repo/ssh/config.d/global"

  git -C "$repo" init --quiet
  git -C "$repo" config filter.pkcs11-provider.clean cat
  git -C "$repo" config filter.pkcs11-provider.smudge cat
  git -C "$repo" add .
  git -C "$repo" config filter.pkcs11-provider.smudge /stale/ssh/pkcs11-filter.sh
  git -C "$repo" config filter.pkcs11-provider.required true

  run git -C "$repo" checkout-index --force --prefix="$checkout/stale/" -- ssh/config.d/global
  assert_failure

  run bash -c 'cd "$1" && "$1/setup/general/02-git-filters.sh" run' _ "$repo"
  assert_success

  run git -C "$repo" config --get filter.pkcs11-provider.smudge
  assert_success
  assert_output "ssh/pkcs11-filter.sh smudge"

  run git -C "$repo" checkout-index --force --prefix="$checkout/portable/" -- ssh/config.d/global
  assert_success
  local expected_provider
  case "$(uname -s)" in
    Darwin) expected_provider="/Users/simeon.stix/.nix-profile/lib/libykcs11.dylib" ;;
    *) expected_provider="/usr/lib64/pkcs11/opensc-pkcs11.so" ;;
  esac
  run grep -F "PKCS11Provider $expected_provider" "$checkout/portable/ssh/config.d/global"
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
  cp "$REPO_DIR/ssh/config.d/global" "$producer/ssh/config.d/"
  "$REPO_DIR/ssh/pkcs11-filter.sh" clean < "$producer/ssh/config.d/global" > "$producer/ssh/config.d/global.tmp"
  mv "$producer/ssh/config.d/global.tmp" "$producer/ssh/config.d/global"

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

  printf '\n# remote update\n' >> "$producer/ssh/config.d/global"
  git -C "$producer" add ssh/config.d/global
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
  run grep -F "# remote update" "$repo/ssh/config.d/global"
  assert_success
}

@test "macOS fallback uses the Home Manager PKCS11 paths without a provider file" {
  local mock_bin="$BATS_TEST_TMPDIR/mock-darwin-bin"
  local filter_dir="$BATS_TEST_TMPDIR/filter-without-providers"
  local input="$BATS_TEST_TMPDIR/pkcs11-input"
  mkdir -p "$mock_bin" "$filter_dir"
  cp "$REPO_DIR/ssh/pkcs11-filter.sh" "$filter_dir/"
  printf '%s\n' '#!/usr/bin/env bash' 'echo Darwin' > "$mock_bin/uname"
  chmod +x "$mock_bin/uname"
  printf '%s\n' \
    'PKCS11Provider @YKCS11@' \
    'PKCS11Provider @OPENSC@' \
    > "$input"

  run env PATH="$mock_bin:/usr/bin:/bin" \
    "$filter_dir/pkcs11-filter.sh" smudge < "$input"
  assert_success
  assert_output_partial "PKCS11Provider /Users/simeon.stix/.nix-profile/lib/libykcs11.dylib"
  assert_output_partial "PKCS11Provider /Users/simeon.stix/.nix-profile/lib/opensc-pkcs11.so"
}