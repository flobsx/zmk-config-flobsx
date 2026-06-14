FROM zmkfirmware/zmk-build-arm:stable

# Install flash tools and yq for YAML parsing
RUN apt-get update && apt-get install -y \
    dfu-util \
    wget \
    && wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && chmod +x /usr/local/bin/yq \
    && rm -rf /var/lib/apt/lists/*

# Copy build scripts
COPY setup.sh build.sh flash.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Create workspace directory and set as WORKDIR
RUN mkdir -p /zmk/workspace
WORKDIR /zmk/workspace
