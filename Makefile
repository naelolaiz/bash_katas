# bash-katas — lint / test / bench targets
#
# Everything runs inside the container by default (see Containerfile).
# Override OCI=docker if you don't have podman.

OCI       ?= podman
IMAGE     ?= localhost/bash-katas:dev
RUN        = $(OCI) run --rm -v "$(CURDIR):/work:rw" -w /work $(IMAGE)
RUN_TTY    = $(OCI) run --rm -it -v "$(CURDIR):/work:rw" -w /work $(IMAGE)

# Find scripts to lint. Order: bin/, scripts/, lib/, docs/*/starter.sh, docs/*/solutions/*.
LINT_TARGETS = $(shell find bin scripts lib docs \
    \( -name '*.sh' -o -name '*.bash' -o -name 'starter.sh' \) \
    -type f 2>/dev/null)

.PHONY: help image lint test bench shell clean

help:
	@printf 'targets:\n'
	@printf '  make image    — build the container image\n'
	@printf '  make lint     — shellcheck all scripts inside the container\n'
	@printf '  make test     — run Bats suites inside the container\n'
	@printf '  make bench    — generate corpora and run benchmarks\n'
	@printf '  make shell    — open a shell in the container\n'
	@printf '  make clean    — remove tmp/, data/generated/\n'

image:
	$(OCI) build -t $(IMAGE) .

lint: image
	$(RUN) scripts/shellcheck-all.sh

test: image
	$(RUN) bash -c 'find docs -name "tests.bats" -print0 | xargs -0 -r bats'

bench: image
	$(RUN) bash -c 'scripts/gen-log-corpus.sh && bats test/bench.bats || true'

shell: image
	$(RUN_TTY)

clean:
	rm -rf tmp/ data/generated/
