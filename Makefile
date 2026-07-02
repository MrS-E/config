# Podman + bats-core test harness for the OS setup system.
#
# Targets:
#   make build              build all container images
#   make test-fedora        run bats in a disposable Fedora container
#   make test-manjaro       run bats in a disposable Manjaro container
#   make test-fedora-atomic run bats in a Fedora Atomic (mocked rpm-ostree) container
#   make test-macos         run bats in a mocked macOS container
#   make test               run the full matrix
#   make baseline           run the matrix and record results under tests/baselines/
#   make compare-baseline   re-run the matrix and diff against the recorded baseline

PODMAN      ?= podman
BATS        ?= bats
IMAGE_PREFIX ?= setup-test
REPO_ROOT   := $(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
WORKSPACE   := /workspace

# bats files executed per target (paths relative to the repo root / WORKDIR)
BATS_COMMON  := tests/bats/smoke.bats tests/bats/idempotency.bats
BATS_FEDORA  := $(BATS_COMMON) tests/bats/assertions-fedora.bats
BATS_MANJARO := $(BATS_COMMON) tests/bats/assertions-manjaro.bats
BATS_ATOMIC  := $(BATS_COMMON) tests/bats/assertions-fedora-atomic.bats
BATS_MACOS   := $(BATS_COMMON) tests/bats/assertions-macos.bats

OS_LIST := fedora manjaro fedora-atomic macos

.PHONY: build $(addprefix build-,$(OS_LIST)) \
        test $(addprefix test-,$(OS_LIST)) \
        baseline compare-baseline

# ---------------------------------------------------------------------------
# Image builds
# ---------------------------------------------------------------------------
build: $(addprefix build-,$(OS_LIST))

build-fedora:
	$(PODMAN) build -t $(IMAGE_PREFIX)/fedora -f tests/containers/Containerfile.fedora .

build-manjaro:
	$(PODMAN) build -t $(IMAGE_PREFIX)/manjaro -f tests/containers/Containerfile.manjaro .

build-fedora-atomic:
	$(PODMAN) build -t $(IMAGE_PREFIX)/fedora-atomic -f tests/containers/Containerfile.fedora-atomic .

build-macos:
	$(PODMAN) build -t $(IMAGE_PREFIX)/macos -f tests/containers/Containerfile.macos-mock .

# ---------------------------------------------------------------------------
# Runner macro: $(call run_bats,<os>,<bats files>)
# ---------------------------------------------------------------------------
define run_bats
	$(PODMAN) run --rm \
		-v $(REPO_ROOT):$(WORKSPACE):Z \
		-e HOME=/home/tester \
		-e TEST_OS=$(1) \
		--user tester \
		-w $(WORKSPACE) \
		$(IMAGE_PREFIX)/$(1) \
		$(BATS) --formatter tap $(2)
endef

# ---------------------------------------------------------------------------
# Per-OS test targets
# ---------------------------------------------------------------------------
test: $(addprefix test-,$(OS_LIST))

test-fedora: build-fedora
	$(call run_bats,fedora,$(BATS_FEDORA))

test-manjaro: build-manjaro
	$(call run_bats,manjaro,$(BATS_MANJARO))

test-fedora-atomic: build-fedora-atomic
	$(call run_bats,fedora-atomic,$(BATS_ATOMIC))

test-macos: build-macos
	$(call run_bats,macos,$(BATS_MACOS))

# ---------------------------------------------------------------------------
# Baseline recording (non-blocking) and comparison
# ---------------------------------------------------------------------------
baseline:
	@mkdir -p tests/baselines
	@for os in $(OS_LIST); do \
		echo "==> Recording baseline: $$os"; \
		{ echo "# Baseline: $$os"; \
		  echo "# recorded: $$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
		  echo "# host: $$(uname -srm)"; \
		  echo; } > tests/baselines/$$os.txt; \
		$(MAKE) test-$$os >> tests/baselines/$$os.txt 2>&1; \
		echo "# exit=$$?" >> tests/baselines/$$os.txt; \
	done
	@echo "==> Baselines written to tests/baselines/"

compare-baseline:
	@mkdir -p tests/baselines/current
	@for os in $(OS_LIST); do \
		echo "==> Re-running: $$os"; \
		{ echo "# Current: $$os"; \
		  echo "# recorded: $$(date -u +%Y-%m-%dT%H:%M:%SZ)"; \
		  echo; } > tests/baselines/current/$$os.txt; \
		$(MAKE) test-$$os >> tests/baselines/current/$$os.txt 2>&1; \
		echo "# exit=$$?" >> tests/baselines/current/$$os.txt; \
	done
	@for os in $(OS_LIST); do \
		echo "===== diff: $$os (baseline -> current) ====="; \
		diff -u tests/baselines/$$os.txt tests/baselines/current/$$os.txt || true; \
	done
