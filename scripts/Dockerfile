FROM zmkfirmware/zmk-build-arm:stable

# Install flash tools
RUN apt-get update && apt-get install -y \
    dfu-util \
    && rm -rf /var/lib/apt/lists/*

# Copy build scripts
COPY setup.sh build.sh flash.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Create workspace directory and set as WORKDIR
RUN mkdir -p /zmk/workspace
WORKDIR /zmk/workspace
