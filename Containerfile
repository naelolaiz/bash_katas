# Frozen environment for bash-katas.
# Run via the Makefile (`make lint`, `make test`, `make shell`) or directly:
#   podman build -t bash-katas .
#   podman run --rm -it -v "$PWD:/work:rw" -w /work bash-katas
FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        coreutils \
        findutils \
        grep \
        sed \
        gawk \
        bsdmainutils \
        bsdextrautils \
        diffutils \
        util-linux \
        procps \
        bc \
        jq \
        moreutils \
        parallel \
        shellcheck \
        bats \
        git \
        ca-certificates \
        less \
        locales \
        strace \
        time \
    && rm -rf /var/lib/apt/lists/*

# Generate a non-C locale so locale-and-sorting (ex. 23) demos work.
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/; s/^# *\(de_DE.UTF-8\)/\1/; s/^# *\(tr_TR.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

ENV LANG=C.UTF-8

WORKDIR /work
CMD ["bash"]
