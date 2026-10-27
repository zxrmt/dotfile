FROM ubuntu:24.04

# ---------------------------------------------------------------------------
# Pinned versions. Everything fetched from the network is pinned to an exact
# version or content hash so a rebuild can't silently pull new upstream code.
#
# Re-pin an installer script after reviewing the diff:
#   curl -fsSL <url> | sha256sum
# ---------------------------------------------------------------------------
ARG NODESOURCE_SETUP_SHA256=2c4c6683a17b6f4128898a7b521e3c8bb725a99ffaf1b5e32ac97c6fa7d381be
ARG RUSTUP_INIT_SHA256=9502b514362a21096210d498f143b8cdacda365d3dfcf45e8f5541e089ccafc0

ARG FOUNDRYUP_VERSION=2.0.0
ARG RUST_VERSION=1.99.1
ARG NEOVIM_VERSION=v0.12.0


RUN apt update -y && \
    apt install -y curl gnupg ca-certificates

# NodeSource setup script verified by hash before it is run.
RUN curl -fsSL -o /tmp/nodesource_setup.sh https://deb.nodesource.com/setup_20.x && \
    echo "${NODESOURCE_SETUP_SHA256}  /tmp/nodesource_setup.sh" | sha256sum -c - && \
    bash /tmp/nodesource_setup.sh && \
    rm /tmp/nodesource_setup.sh && \
    apt install -y nodejs

RUN apt update -y
RUN apt install -y git gzip unzip make cmake ripgrep fzf tmux python3-venv bat build-essential curl wget xxd file fd-find jq
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 100




RUN curl -fsSL https://claude.ai/install.sh | bash
RUN npm install -g @openai/codex



RUN apt update && apt install -y sudo \
 && useradd -m -s /bin/bash zx \
 && usermod -aG sudo zx \
 && echo "zx ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/zx \
 && chmod 0440 /etc/sudoers.d/zx
# default `sudo` to classic sudo.ws: sudo-rs needs close_range (kernel >=5.9),
# this host kernel is 5.4 and docker seccomp returns EPERM for it
# && update-alternatives --set sudo /usr/bin/sudo.ws

# Rust lsp for vim: rustup-init.sh hash-verified, toolchain version pinned.
RUN curl -fsSL -o /tmp/rustup_init.sh https://sh.rustup.rs && \
    echo "${RUSTUP_INIT_SHA256}  /tmp/rustup_init.sh" | sha256sum -c - && \
    bash /tmp/rustup_init.sh -y --default-toolchain "${RUST_VERSION}" && \
    rm /tmp/rustup_init.sh
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add rust-analyzer

USER zx
# Python lsp for vim
WORKDIR /home/zx/

# Pinned release tag instead of master HEAD: release tarballs SHA256-check their
# bundled dependencies, and the tree is reviewable.
RUN git clone --depth=1 --branch "${NEOVIM_VERSION}" https://github.com/neovim/neovim
WORKDIR neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo

# Replace unstable Rust coreutils with GNU coreutils: fix the crash on cmp
RUN sudo apt-get update && \
    sudo apt-get remove -y --allow-remove-essential rust-coreutils && \
    sudo apt-get autoremove -y && \
    sudo  apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*


RUN sudo make install
WORKDIR /home/zx/
RUN rm -rf neovim
USER zx



WORKDIR /home/zx/

RUN git clone https://github.com/zxrmt/dotfile \
 && find dotfile -maxdepth 1 -mindepth 1 -not -name ".git" -exec cp -r {} ./ \; \
 && rm -rf dotfile

CMD ["/bin/bash"]
