FROM ubuntu:24.04

RUN apt update -y && \
    apt install -y curl gnupg && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs

RUN apt update -y
RUN apt install -y git gzip unzip make cmake ripgrep fzf tmux python3-venv bat build-essential curl wget xxd file fd-find jq
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 100

RUN curl -L https://foundry.paradigm.xyz | bash

ENV PATH="/root/.foundry/bin:${PATH}"

RUN foundryup
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g @openai/codex



RUN apt update && apt install -y sudo \
 && useradd -m -s /bin/bash zx \
 && usermod -aG sudo zx \
 && echo "zx ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/zx \
 && chmod 0440 /etc/sudoers.d/zx
# default `sudo` to classic sudo.ws: sudo-rs needs close_range (kernel >=5.9),
# this host kernel is 5.4 and docker seccomp returns EPERM for it
# && update-alternatives --set sudo /usr/bin/sudo.ws

# Rust lsp for vim
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup component add rust-analyzer

USER zx
# Python lsp for vim
WORKDIR /home/zx/

RUN git clone https://github.com/neovim/neovim --depth=1
WORKDIR neovim
RUN make CMAKE_BUILD_TYPE=RelWithDebInfo

# Replace unstable Rust coreutils with GNU coreutils: fix the crash on cmp
RUN sudo apt-get update && \
    sudo apt-get remove -y --allow-remove-essential rust-coreutils && \
    sudo apt-get autoremove -y && \
    sudo  apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*


RUN sudo make install
USER zx



WORKDIR /home/zx/

RUN git clone https://github.com/zxrmt/dotfile
RUN find dotfile -maxdepth 1 -mindepth 1 -not -name "." -not -name ".." -exec cp -r {} ./ \;
RUN rm -rf .git


CMD ["/bin/bash"]
