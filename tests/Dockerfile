FROM ubuntu:22.04

# Disable interactive prompts during apt
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies including kcov for coverage
RUN apt-get update && apt-get install -y \
    sudo curl jq whiptail kcov bash git \
    && rm -rf /var/lib/apt/lists/*

# Mock destructive/system commands that shouldn't run in a container
RUN echo '#!/bin/bash\nexit 0' > /usr/local/bin/systemctl && chmod +x /usr/local/bin/systemctl
RUN echo '#!/bin/bash\necho "America/New_York"' > /usr/local/bin/timedatectl && chmod +x /usr/local/bin/timedatectl
RUN echo '#!/bin/bash\necho "test.ts.net"' > /usr/local/bin/tailscale && chmod +x /usr/local/bin/tailscale
# Mock docker so compose commands don't fail headlessly
RUN echo '#!/bin/bash\nexit 0' > /usr/local/bin/docker && chmod +x /usr/local/bin/docker
RUN git config --global --add safe.directory /workspace

WORKDIR /workspace
CMD ["/bin/bash", "./tests/docker_test_runner.sh"]
