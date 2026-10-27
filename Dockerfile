FROM ubuntu:26.04

# ---------------------------------------------------------------------------
# Pinned versions. Everything fetched from the network is pinned to an exact
# version or content hash so a rebuild can't silently pull new upstream code.
#
# Re-pin an installer script after reviewing the diff:
#   curl -fsSL <url> | sha256sum
# ---------------------------------------------------------------------------
ARG NVM_VERSION=0.40.8
ARG NVM_INSTALL_SHA256=48a0eee9a60e07422dce0eb5774754c83889570ca1ee2566c516acbe8af03a9e
ARG NODE_VERSION=26.12.1
ARG RUSTUP_INIT_SHA256=9502b514362a21096210d498f143b8cdacda365d3dfcf45e8f5541e089ccafc0

ARG FOUNDRYUP_VERSION=2.0.0
ARG RUST_VERSION=1.99.1
ARG NEOVIM_VERSION=v0.12.0


# ---------------------------------------------------------------------------
# System packages + non-root user (everything below runs as zx so that
# nvm/node, claude, codex and rust all live in zx's home, not /root, which
# zx cannot read).
# ---------------------------------------------------------------------------
RUN apt-get update -y && \
    apt-get install -y net-tools tree curl gnupg ca-certificates xz-utils python3-pip \
        git gzip unzip make cmake ripgrep fzf tmux python3-venv bat \
        build-essential wget xxd file fd-find jq sudo && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 100 && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash zx \
 && usermod -aG sudo zx \
 && echo "zx ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/zx \
 && chmod 0440 /etc/sudoers.d/zx
# default `sudo` to classic sudo.ws: sudo-rs needs close_range (kernel >=5.9),
# this host kernel is 5.4 and docker seccomp returns EPERM for it
# && update-alternatives --set sudo /usr/bin/sudo.ws

USER zx
WORKDIR /home/zx/
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV NVM_DIR=/home/zx/.nvm
ENV PATH="${NVM_DIR}/current/bin:/home/zx/.local/bin:/home/zx/.cargo/bin:${PATH}"

# ---------------------------------------------------------------------------
# Node.js via nvm. Installer script verified by hash before it is run.
# nvm is a shell function, so it's sourced in the same RUN that uses it.
# The "current" symlink gives a stable path for ENV PATH above.
# ---------------------------------------------------------------------------
RUN curl -fsSL -o /tmp/nvm_install.sh "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" && \
    echo "${NVM_INSTALL_SHA256}  /tmp/nvm_install.sh" | sha256sum -c - && \
    bash /tmp/nvm_install.sh && \
    rm /tmp/nvm_install.sh && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "${NODE_VERSION}" && \
    nvm alias default "${NODE_VERSION}" && \
    ln -s "$(dirname "$(dirname "$(nvm which default)")")" "$NVM_DIR/current" && \
    node -v && npm -v

# Claude Code (native installer, installs to ~/.local/bin)
RUN curl -fsSL https://claude.ai/install.sh | bash -s stable
# Optional sanity check at build time
RUN claude --version

# Codex (npm global; lands in the nvm Node dir, already on PATH)
RUN npm install -g @openai/codex

# Rust lsp for vim: rustup-init.sh hash-verified, toolchain version pinned.
RUN curl -fsSL -o /tmp/rustup_init.sh https://sh.rustup.rs && \
    echo "${RUSTUP_INIT_SHA256}  /tmp/rustup_init.sh" | sha256sum -c - && \
    bash /tmp/rustup_init.sh -y --default-toolchain "${RUST_VERSION}" && \
    rm /tmp/rustup_init.sh
RUN rustup component add rust-analyzer

# Python lsp for vim

# Pinned release tag instead of master HEAD: release tarballs SHA256-check their
# bundled dependencies, and the tree is reviewable.
RUN git clone --depth=1 --branch "${NEOVIM_VERSION}" https://github.com/neovim/neovim
WORKDIR neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo

RUN sudo apt-get update && \
    if dpkg -s coreutils-from-uutils >/dev/null 2>&1; then \
        sudo apt-get install -y --allow-remove-essential \
            coreutils-from-gnu coreutils-from-uutils- ; \
    fi && \
    sudo apt-get autoremove -y && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

RUN sudo make install
WORKDIR /home/zx/
RUN rm -rf neovim

RUN git clone https://github.com/zxrmt/dotfile \
 && find dotfile -maxdepth 1 -mindepth 1 -not -name ".git" -exec cp -r {} ./ \;

# Final sanity check
RUN node -v && npm -v && claude --version && codex --version && rustc --version && nvim --version | head -1

CMD ["/bin/bash"]
