FROM node:20

ARG TZ
ENV TZ=$TZ

ENV NODE_ENV=production

RUN apt-get update && apt-get install -y --no-install-recommends \
  exa \
  less \
  git \
  fzf \
  unzip \
  nano \
  vim \
  neovim \
  tmux \
  man-db \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /workspace /home/node/.claude \
    && chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

RUN mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R node:node /commandhistory

RUN mkdir -p /usr/local/share/npm-global \
    && chown -R node:node /usr/local/share/npm-global

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

USER node

ENV SHELL=/bin/bash
ENV EDITOR=nvim
ENV VISUAL=nvim

RUN echo "alias ls='exa -la --group-directories-first'" >> ~/.bashrc

ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@$CLAUDE_CODE_VERSION

CMD ["bash"]
