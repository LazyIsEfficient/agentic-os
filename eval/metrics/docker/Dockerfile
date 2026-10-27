# Image for run-release-arms.sh --sandbox docker: per-sample model containers,
# the API proxy, and the per-sample scorer all run from it. The build context
# is staged by run-release-arms.sh (this Dockerfile + harness/ from the HEAD
# export); the repo itself is never mounted into any container.
# Every tool is pinned. To bump: change the pin, and for gitleaks also its sha256
# (from the release's checksums.txt).
FROM node:22.22.0-bookworm-slim@sha256:dd9d21971ec4395903fa6143c2b9267d048ae01ca6d3ea96f16cb30df6187d94

ARG CLAUDE_CODE_VERSION=2.1.311
ARG SEMGREP_VERSION=1.182.1
ARG GITLEAKS_VERSION=8.30.1
ARG GITLEAKS_SHA256_X64=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb
ARG GITLEAKS_SHA256_ARM64=e4a487ee7ccd7d3a7f7ec08657610aa3606637dab924210b3aee62570fb4b080

RUN apt-get update \
 && apt-get install -y --no-install-recommends bash ca-certificates curl git jq python3 python3-venv \
 && rm -rf /var/lib/apt/lists/*

# gitleaks: release binary, checksum-verified before extraction.
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
      amd64) a=x64; sum="$GITLEAKS_SHA256_X64" ;; \
      arm64) a=arm64; sum="$GITLEAKS_SHA256_ARM64" ;; \
      *) echo "unsupported arch" >&2; exit 1 ;; \
    esac; \
    f="gitleaks_${GITLEAKS_VERSION}_linux_${a}.tar.gz"; \
    curl -fsSL -o "/tmp/$f" "https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/$f"; \
    echo "$sum  /tmp/$f" | sha256sum -c -; \
    tar -xzf "/tmp/$f" -C /usr/local/bin gitleaks; \
    rm -f "/tmp/$f"

# semgrep in its own venv, linked onto PATH.
RUN python3 -m venv /opt/semgrep \
 && /opt/semgrep/bin/pip install --no-cache-dir "semgrep==${SEMGREP_VERSION}" \
 && ln -s /opt/semgrep/bin/semgrep /usr/local/bin/semgrep

RUN npm install -g --no-fund --no-audit "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# The proxy is small and harmless to the model (it holds no scoring code), so
# it ships here; the model and proxy containers run from THIS image. The
# scoring code and exploit vectors are NOT here — they live only in the scorer
# image (Dockerfile.scorer), so a sample container cannot read the grader.
COPY harness/lib/api-proxy.mjs /opt/harness/lib/api-proxy.mjs
RUN chown -R root:root /opt/harness && chmod -R a+rX,go-w /opt/harness

ENV GIT_OPTIONAL_LOCKS=0
USER node
WORKDIR /home/node
