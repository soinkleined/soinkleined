# Base image
FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Copy repository
COPY . /metrics
WORKDIR /metrics

# Setup
# The fork Dockerfile installs systemd as a dependency, and its dpkg trigger
# calls journalctl. In a BuildKit build that call can sit forever on
# "Processing triggers for systemd". Divert the binaries the package ships
# under /bin so the trigger hits a no-op instead. policy-rc.d stops apt from
# trying to start services.
RUN for cmd in systemctl journalctl systemd-sysusers systemd-tmpfiles; do \
      dpkg-divert --local --rename --add "/bin/${cmd}" \
      && printf '#!/bin/sh\nexit 0\n' > "/bin/${cmd}" \
      && chmod +x "/bin/${cmd}"; \
    done \
  && printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
  && chmod +x /usr/sbin/policy-rc.d \
  && chmod +x /metrics/source/app/action/index.mjs \
  # Install latest chrome dev package, fonts to support major charsets and skip chromium download on puppeteer install
  # Based on https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#running-puppeteer-in-docker
  && apt-get update \
  && apt-get install -y wget gnupg ca-certificates libgconf-2-4 \
  build-essential \
  libxml2-dev \
  libxslt1-dev \
  zlib1g-dev \
  pkg-config \
  ruby-dev\
  && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 libx11-xcb1 libxtst6 lsb-release --no-install-recommends \
  # Chrome pulls in systemd. Its later dpkg trigger runs journalctl --update-catalog,
  # which blocks under BuildKit. Replace the real binaries before the next apt.
  && for p in /bin/journalctl /usr/bin/journalctl /bin/systemctl /usr/bin/systemctl /bin/systemd-sysusers /usr/bin/systemd-sysusers /bin/systemd-tmpfiles /usr/bin/systemd-tmpfiles; do \
       printf '#!/bin/sh\nexit 0\n' > "$p" && chmod +x "$p"; \
     done \
  # Install deno for miscellaneous scripts
  && apt-get install -y curl unzip \
  && curl -fsSL https://deno.land/x/install/install.sh | DENO_INSTALL=/usr/local sh \
  # Install ruby to support github licensed gem
  && apt-get install -y ruby-full git g++ cmake pkg-config libssl-dev \
  && gem install licensed \
  # Install python for node-gyp
  && apt-get install -y python3 \
  # Clean apt/lists
  && rm -rf /var/lib/apt/lists/* \
  # Install node modules and rebuild indexes
  && npm ci \
  && npm run build

# Environment variables
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_BROWSER_PATH "google-chrome-stable"

# Execute GitHub action
ENTRYPOINT node /metrics/source/app/action/index.mjs
