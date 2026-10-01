#!/usr/bin/env bats
# nixvm tests use an isolated Nix stub and never build or download packages.

load "/workspace/tests/bats/helpers/common.bash"

NIXVM_BASE_PATH="$PATH"

setup() {
  NIXVM_TEST_ROOT="$BATS_TEST_TMPDIR/nixvm"
  NIXVM_TEST_BIN="$NIXVM_TEST_ROOT/bin"
  NIXVM_NO_NIX_BIN="$NIXVM_TEST_ROOT/bin-without-nix"
  mkdir -p "$NIXVM_TEST_BIN" "$NIXVM_NO_NIX_BIN" \
    "$NIXVM_TEST_ROOT/data" "$NIXVM_TEST_ROOT/fake-store"

  export XDG_DATA_HOME="$NIXVM_TEST_ROOT/data"
  export NIXVM_SCRIPT="$REPO_DIR/scripts/nixvm"
  export NIXVM_NIX_OUTPUTS="$NIXVM_TEST_ROOT/fake-store"
  export NIXVM_NIX_LOG="$NIXVM_TEST_ROOT/nix.log"

  cat > "$NIXVM_TEST_BIN/uname" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  -s) printf 'Darwin\n' ;;
  -m) printf 'arm64\n' ;;
  *) printf 'Darwin\n' ;;
esac
EOF
  chmod +x "$NIXVM_TEST_BIN/uname"
  ln -s "$NIXVM_TEST_BIN/uname" "$NIXVM_NO_NIX_BIN/uname"

  cat > "$NIXVM_TEST_BIN/nix" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >> "$NIXVM_NIX_LOG"

nix_command=''
experimental_features=''
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --extra-experimental-features)
      experimental_features="${2:-}"
      shift 2
      ;;
    eval|build)
      nix_command="$1"
      shift
      break
      ;;
    *)
      printf 'unexpected mock Nix argument: %s\n' "$1" >&2
      exit 13
      ;;
  esac
done

if [[ "${NIXVM_REQUIRE_NIX_FEATURES:-0}" == 1 && "$experimental_features" != "nix-command flakes" ]]; then
  printf "error: experimental Nix feature 'nix-command' is disabled\n" >&2
  exit 14
fi

case "$nix_command" in
  eval)
    if [[ "${NIXVM_NIX_EVAL_JDK23_EOL:-0}" == 1 && "$*" != *"builtins.tryEval"* ]]; then
      printf 'error: OpenJDK 23 was removed as it has reached its end of life\n' >&2
      exit 15
    fi
    if [[ "${NIXVM_NIX_EVAL_FAIL:-0}" == 1 ]]; then
      printf 'mock Nix evaluation failed\n' >&2
      exit 10
    fi
    if [[ -n "${NIXVM_NIX_EVAL_OUTPUT:-}" ]]; then
      printf '%s\n' "$NIXVM_NIX_EVAL_OUTPUT"
    else
      printf '%s\n' \
        'java|17|jdk17' \
        'java|21|jdk21' \
        'ruby|3.3|ruby_3_3' \
        'python|3.12|python312'
    fi
    ;;
  build)
    if [[ "${NIXVM_NIX_BUILD_FAIL:-0}" == 1 ]]; then
      printf 'mock Nix build failed\n' >&2
      exit 11
    fi
    out_link=''
    attribute=''
    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --out-link)
          out_link="$2"
          shift 2
          ;;
        nixpkgs#*)
          attribute="${1#nixpkgs#}"
          shift
          ;;
        *) shift ;;
      esac
    done
    if [[ -z "$out_link" || -z "$attribute" ]]; then
      printf 'mock Nix build received invalid arguments\n' >&2
      exit 12
    fi
    mkdir -p "$NIXVM_NIX_OUTPUTS/$attribute/bin"
    ln -s "$NIXVM_NIX_OUTPUTS/$attribute" "$out_link"
    ;;
  *)
    printf 'unexpected mock Nix command: %s\n' "$*" >&2
    exit 13
    ;;
esac
EOF
  chmod +x "$NIXVM_TEST_BIN/nix"

  export PATH="$NIXVM_TEST_BIN:$NIXVM_BASE_PATH"
}

install_test_runtimes() {
  "$REPO_DIR/scripts/nixvm" install java 21 >/dev/null
  "$REPO_DIR/scripts/nixvm" install ruby 3.3 >/dev/null
  "$REPO_DIR/scripts/nixvm" install python 3.12 >/dev/null
}

@test "install retains supported Java, Ruby, and Python outputs" {
  run "$REPO_DIR/scripts/nixvm" install java 21
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed java 21 (jdk21)"* ]]
  [[ -L "$XDG_DATA_HOME/nixvm/installed/java/21" ]]

  run "$REPO_DIR/scripts/nixvm" install ruby 3.3
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed ruby 3.3 (ruby_3_3)"* ]]
  [[ -L "$XDG_DATA_HOME/nixvm/installed/ruby/3.3" ]]

  run "$REPO_DIR/scripts/nixvm" install python 3.12
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed python 3.12 (python312)"* ]]
  [[ -L "$XDG_DATA_HOME/nixvm/installed/python/3.12" ]]
}

@test "list distinguishes installed and Nixpkgs-available versions" {
  run "$REPO_DIR/scripts/nixvm" install java 17
  [[ "$status" -eq 0 ]]

  run "$REPO_DIR/scripts/nixvm" list java
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed java versions: 17"* ]]
  [[ "$output" == *"Available java versions: 17, 21"* ]]

  run "$REPO_DIR/scripts/nixvm" list ruby --available
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Available ruby versions: 3.3"* ]]
  [[ "$output" != *"Installed ruby versions:"* ]]
}

@test "available versions and install attributes are discovered from Nixpkgs" {
  local nixpkgs_catalog nix_log
  nixpkgs_catalog=$'java|17|jdk17\njava|21|jdk21\njava|26|jdk26\nruby|3.3|ruby_3_3\nruby|3.6|ruby_3_6\npython|3.12|python312\npython|3.15|python315'

  run env NIXVM_NIX_EVAL_OUTPUT="$nixpkgs_catalog" \
    "$REPO_DIR/scripts/nixvm" list --available
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Available java versions: 17, 21, 26"* ]]
  [[ "$output" == *"Available ruby versions: 3.3, 3.6"* ]]
  [[ "$output" == *"Available python versions: 3.12, 3.15"* ]]

  nix_log="$(<"$NIXVM_NIX_LOG")"
  [[ "$nix_log" == *"builtins.attrNames pkgs"* ]]

  run env NIXVM_NIX_EVAL_OUTPUT="$nixpkgs_catalog" \
    "$REPO_DIR/scripts/nixvm" install java 26
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed java 26 (jdk26)"* ]]
  [[ -L "$XDG_DATA_HOME/nixvm/installed/java/26" ]]

  run env NIXVM_NIX_EVAL_OUTPUT="$nixpkgs_catalog" \
    "$REPO_DIR/scripts/nixvm" install ruby 3.6
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed ruby 3.6 (ruby_3_6)"* ]]

  run env NIXVM_NIX_EVAL_OUTPUT="$nixpkgs_catalog" \
    "$REPO_DIR/scripts/nixvm" install python 3.15
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed python 3.15 (python315)"* ]]
}

@test "available listing skips retired Nixpkgs attributes that fail evaluation" {
  run env NIXVM_NIX_EVAL_JDK23_EOL=1 "$REPO_DIR/scripts/nixvm" list --available java
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Available java versions: 17, 21"* ]]
  [[ "$output" != *"23"* ]]
}

@test "installed-only listing works without Nix" {
  run "$REPO_DIR/scripts/nixvm" install python 3.12
  [[ "$status" -eq 0 ]]

  run env PATH="$NIXVM_NO_NIX_BIN:/usr/bin:/bin" \
    "$REPO_DIR/scripts/nixvm" list python --installed
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed python versions: 3.12"* ]]
}

@test "install rejects unknown runtimes and unsupported version labels" {
  run "$REPO_DIR/scripts/nixvm" install golang 1.24
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Unknown runtime 'golang'"* ]]

  run "$REPO_DIR/scripts/nixvm" install java 21.0.1
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Unsupported java version '21.0.1'"* ]]
}

@test "missing Nix and failed Nix operations report actionable errors" {
  run env PATH="$NIXVM_NO_NIX_BIN:/usr/bin:/bin" \
    "$REPO_DIR/scripts/nixvm" install java 21
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Nix is required"* ]]

  run env NIXVM_NIX_EVAL_FAIL=1 "$REPO_DIR/scripts/nixvm" list --available java
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"mock Nix evaluation failed"* ]]
  [[ "$output" == *"Ensure nix-command and flakes are enabled"* ]]

  run env NIXVM_NIX_BUILD_FAIL=1 "$REPO_DIR/scripts/nixvm" install java 21
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"mock Nix build failed"* ]]
  [[ "$output" == *"Nix failed to build Nixpkgs attribute 'jdk21'"* ]]
}

@test "supplies required experimental features to Nix operations" {
  run env NIXVM_REQUIRE_NIX_FEATURES=1 "$REPO_DIR/scripts/nixvm" install java 21
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Installed java 21 (jdk21)"* ]]

  local nix_log
  nix_log="$(<"$NIXVM_NIX_LOG")"
  [[ "$nix_log" == *"--extra-experimental-features nix-command flakes eval"* ]]
  [[ "$nix_log" == *"--extra-experimental-features nix-command flakes build"* ]]
}

@test "use persists an installed version independently for each runtime" {
  run "$REPO_DIR/scripts/nixvm" use java 21
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"java version '21' is not installed"* ]]
  [[ ! -e "$XDG_DATA_HOME/nixvm/active/java" ]]

  install_test_runtimes
  run "$REPO_DIR/scripts/nixvm" use java 21
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Using java 21"* ]]
  run "$REPO_DIR/scripts/nixvm" use ruby 3.3
  [[ "$status" -eq 0 ]]
  run "$REPO_DIR/scripts/nixvm" use python 3.12
  [[ "$status" -eq 0 ]]

  local active_version
  IFS= read -r active_version < "$XDG_DATA_HOME/nixvm/active/java"
  [[ "$active_version" == 21 ]]
  IFS= read -r active_version < "$XDG_DATA_HOME/nixvm/active/ruby"
  [[ "$active_version" == 3.3 ]]
  IFS= read -r active_version < "$XDG_DATA_HOME/nixvm/active/python"
  [[ "$active_version" == 3.12 ]]
}

@test "direct use warns when the current shell integration is not loaded" {
  install_test_runtimes

  run zsh -c '
    unset JAVA_HOME
    "$NIXVM_SCRIPT" use java 21
    java_bin="$XDG_DATA_HOME/nixvm/installed/java/21/bin"
    case ":$PATH:" in
      *":$java_bin:"*) has_java_bin=1 ;;
      *) has_java_bin=0 ;;
    esac
    print -r -- "JAVA_HOME=${JAVA_HOME-}"
    print -r -- "HAS_JAVA_BIN=$has_java_bin"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Using java 21."* ]]
  [[ "$output" == *"current shell was not updated"* ]]
  [[ "$output" == *"nixvm --shell-integration"* ]]
  [[ "$output" == *$'JAVA_HOME=\nHAS_JAVA_BIN=0'* ]]
  [[ -f "$XDG_DATA_HOME/nixvm/active/java" ]]
}

@test "shell integration restores selected runtime paths and JAVA_HOME at startup" {
  install_test_runtimes
  "$REPO_DIR/scripts/nixvm" use java 21 >/dev/null
  "$REPO_DIR/scripts/nixvm" use ruby 3.3 >/dev/null
  "$REPO_DIR/scripts/nixvm" use python 3.12 >/dev/null

  run zsh -c '
    eval "$("$NIXVM_SCRIPT" --shell-integration)"
    print -r -- "JAVA_HOME=$JAVA_HOME"
    print -r -- "PATH=$PATH"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"JAVA_HOME=$XDG_DATA_HOME/nixvm/installed/java/21"* ]]
  [[ "$output" == *"$XDG_DATA_HOME/nixvm/installed/java/21/bin"* ]]
  [[ "$output" == *"$XDG_DATA_HOME/nixvm/installed/ruby/3.3/bin"* ]]
  [[ "$output" == *"$XDG_DATA_HOME/nixvm/installed/python/3.12/bin"* ]]
}

@test "current Zsh use refreshes PATH for every runtime without duplicates" {
  install_test_runtimes
  local java_bin system_bin
  java_bin="$XDG_DATA_HOME/nixvm/installed/java/21/bin"
  system_bin="$NIXVM_TEST_ROOT/system-bin"
  mkdir -p "$system_bin"
  printf '#!/usr/bin/env sh\nprintf "system-java\\n"\n' > "$system_bin/java"
  printf '#!/usr/bin/env sh\nprintf "managed-java\\n"\n' > "$java_bin/java"
  chmod +x "$system_bin/java" "$java_bin/java"
  export NIXVM_TEST_SYSTEM_BIN="$system_bin"

  run zsh -c '
    export PATH="$NIXVM_TEST_SYSTEM_BIN:/workspace/scripts:$PATH"
    eval "$("$NIXVM_SCRIPT" --shell-integration)"
    nixvm use java 21
    nixvm use java 21
    nixvm use ruby 3.3
    nixvm use python 3.12

    java_bin="$XDG_DATA_HOME/nixvm/installed/java/21/bin"
    ruby_bin="$XDG_DATA_HOME/nixvm/installed/ruby/3.3/bin"
    python_bin="$XDG_DATA_HOME/nixvm/installed/python/3.12/bin"
    typeset -i java_count=0 ruby_count=0 python_count=0
    for entry in "${path[@]}"; do
      if [[ "$entry" == "$java_bin" ]]; then (( java_count += 1 )); fi
      if [[ "$entry" == "$ruby_bin" ]]; then (( ruby_count += 1 )); fi
      if [[ "$entry" == "$python_bin" ]]; then (( python_count += 1 )); fi
    done
    print -r -- "JAVA_COUNT=$java_count"
    print -r -- "RUBY_COUNT=$ruby_count"
    print -r -- "PYTHON_COUNT=$python_count"
    print -r -- "JAVA_HOME=$JAVA_HOME"
    print -r -- "JAVA_COMMAND=$(command -v java)"
    print -r -- "JAVA_OUTPUT=$(java)"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"JAVA_COUNT=1"* ]]
  [[ "$output" == *"RUBY_COUNT=1"* ]]
  [[ "$output" == *"PYTHON_COUNT=1"* ]]
  [[ "$output" == *"JAVA_HOME=$XDG_DATA_HOME/nixvm/installed/java/21"* ]]
  [[ "$output" == *"JAVA_COMMAND=$XDG_DATA_HOME/nixvm/installed/java/21/bin/java"* ]]
  [[ "$output" == *"JAVA_OUTPUT=managed-java"* ]]
  [[ "$output" != *"current shell was not updated"* ]]
}

@test "remove rejects invalid requests and non-manager install paths" {
  run "$REPO_DIR/scripts/nixvm" remove golang 1.24
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Unknown runtime 'golang'"* ]]

  run "$REPO_DIR/scripts/nixvm" remove java 21.0.1
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Unsupported java version '21.0.1'"* ]]

  run "$REPO_DIR/scripts/nixvm" remove java 21
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"java version '21' is not installed"* ]]

  mkdir -p "$XDG_DATA_HOME/nixvm/installed/java"
  printf 'keep this file\n' > "$XDG_DATA_HOME/nixvm/installed/java/21"
  run "$REPO_DIR/scripts/nixvm" remove java 21
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"is not a nixvm-managed reference"* ]]
  [[ -f "$XDG_DATA_HOME/nixvm/installed/java/21" ]]
}

@test "remove releases only the selected manager reference for an inactive version" {
  "$REPO_DIR/scripts/nixvm" install java 17 >/dev/null
  "$REPO_DIR/scripts/nixvm" install java 21 >/dev/null
  "$REPO_DIR/scripts/nixvm" use java 21 >/dev/null

  run "$REPO_DIR/scripts/nixvm" remove java 17
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Removed java 17."* ]]
  [[ ! -e "$XDG_DATA_HOME/nixvm/installed/java/17" ]]
  [[ ! -L "$XDG_DATA_HOME/nixvm/installed/java/17" ]]
  [[ -L "$XDG_DATA_HOME/nixvm/installed/java/21" ]]
  [[ -d "$NIXVM_NIX_OUTPUTS/jdk17" ]]

  local active_version
  IFS= read -r active_version < "$XDG_DATA_HOME/nixvm/active/java"
  [[ "$active_version" == 21 ]]
}

@test "remove of an active version clears state and refreshes the current Zsh" {
  install_test_runtimes
  "$REPO_DIR/scripts/nixvm" use java 21 >/dev/null
  "$REPO_DIR/scripts/nixvm" use python 3.12 >/dev/null

  run zsh -c '
    export PATH="/workspace/scripts:$PATH"
    export JAVA_HOME=/system/java
    eval "$("$NIXVM_SCRIPT" --shell-integration)"
    nixvm remove java 21

    java_bin="$XDG_DATA_HOME/nixvm/installed/java/21/bin"
    python_bin="$XDG_DATA_HOME/nixvm/installed/python/3.12/bin"
    typeset -i java_count=0 python_count=0
    for entry in "${path[@]}"; do
      if [[ "$entry" == "$java_bin" ]]; then (( java_count += 1 )); fi
      if [[ "$entry" == "$python_bin" ]]; then (( python_count += 1 )); fi
    done
    print -r -- "JAVA_COUNT=$java_count"
    print -r -- "PYTHON_COUNT=$python_count"
    print -r -- "JAVA_HOME=$JAVA_HOME"
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Removed java 21 and cleared its active selection."* ]]
  [[ "$output" == *"JAVA_COUNT=0"* ]]
  [[ "$output" == *"PYTHON_COUNT=1"* ]]
  [[ "$output" == *"JAVA_HOME=/system/java"* ]]
  [[ ! -e "$XDG_DATA_HOME/nixvm/active/java" ]]
  [[ -f "$XDG_DATA_HOME/nixvm/active/python" ]]
  [[ ! -e "$XDG_DATA_HOME/nixvm/installed/java/21" ]]
  [[ -d "$NIXVM_NIX_OUTPUTS/jdk21" ]]
}