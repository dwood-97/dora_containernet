#!bin/bash

# Update the apt package index and install packages to allow apt to use a repository over HTTPS:
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get -qq install \
    ca-certificates \
    curl \
    gnupg

# Add Docker’s official GPG key:
mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Use the following command to set up the repository:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the apt package index:
apt-get update

# Install Docker Engine, containerd, and Docker Compose.
DEBIAN_FRONTEND=noninteractive apt-get -qq install \
 docker-ce \
 docker-ce-cli \
 containerd.io \
 docker-buildx-plugin \
 docker-compose-plugin

# Create the docker group.
groupadd docker

# Add your user to the docker group.
usermod -aG docker $USER

# You can also run the following command to activate the changes to groups:
newgrp docker

# Verify that the Docker Engine installation is successful by running the hello-world image:
docker run hello-world