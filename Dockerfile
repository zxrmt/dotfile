FROM ubuntu:25.10



RUN apt update -y && \
    apt install -y curl gnupg && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs

RUN apt update -y
RUN apt install -y git gzip unzip make cmake ripgrep fzf tmux python3-venv bat lazygit build-essential 
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


USER root
RUN make install
USER zx



WORKDIR /home/zx/

RUN git clone https://github.com/zxrmt/dotfile
RUN find dotfile -maxdepth 1 -mindepth 1 -not -name "." -not -name ".." -exec cp -r {} ./ \;
RUN rm -rf .git


CMD ["/bin/bash"]
