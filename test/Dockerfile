# Minimal Debian image for testing ./setup from a near-bare system.
#
# We install only what's needed to *bootstrap* the setup script (curl, git,
# sudo, locales); everything else is left for ./setup to install, so the test
# exercises the real install path.
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo curl ca-certificates git locales ncurses-base ncurses-term && \
    sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen && \
    useradd -m -s /bin/bash tester && \
    echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

USER tester
WORKDIR /home/tester
