FROM ubuntu:20.04
LABEL maintainer="manuel@peuster.de"

# Set the working directory
WORKDIR /root

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    dnsutils \
    tcpdump \
    vim \
    git \
    net-tools \
    iputils-ping \
    ifupdown \
    hostapd \
    bridge-utils \
    iptables \
    sudo \
    python3 \
    curl \
    gettext \
    gcc \
    iproute2 \
    libssl-dev \
    libdbus-1-dev \
    libidn11-dev \
    libnetfilter-conntrack-dev \
    nettle-dev \
    openvswitch-switch \
    x11-xserver-utils \
    xterm \
    software-properties-common \
    ansible \
    build-essential \
    python3-setuptools \
    python3-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && touch /etc/network/interfaces

# Install Rust and sqlx-cli
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh \
    -s -- -y; \
    export CARGO_HOME=/usr/local/cargo; \
    export PATH=$CARGO_HOME/bin:$PATH; \
    cargo install sqlx-cli;

# Install Containernet
RUN git clone https://github.com/containernet/containernet.git && \
    cd containernet/ansible && \
    ansible-playbook -i "localhost," -c local --skip-tags "notindocker" install.yml && \
    cd .. && \
    make develop

# Hotfix: https://github.com/pytest-dev/pytest/issues/4770
RUN pip3 install "more-itertools<=5.0.0"

# Expose necessary ports
EXPOSE 6633 6653 6640

# Set up environment variables
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=$CARGO_HOME/bin:$PATH
ENV CONTAINERNET_NESTED 1

# Copy necessary files into the image
COPY dora /root/dora
COPY ENTRYPOINT.sh /

# Set the Dora binary as the command to run when the container starts
WORKDIR /root/dora
RUN cargo build --release && \
    cp target/release/dora /usr/local/bin && \
    chmod +x /usr/local/bin/dora

# Start the OVS service
ENTRYPOINT ["util/docker/entrypoint.sh"]
CMD ["python3", "examples/containernet_example.py"]
