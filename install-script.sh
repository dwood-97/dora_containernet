#!/bin/bash

###################################
# Install Dora & Containernet on VM
###################################

# Define variables
CARGO_HOME=/usr/local/cargo
PATH=$CARGO_HOME/bin:$PATH

# Wait for lock file to become available
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    echo "Waiting for dpkg lock file to become available..."
    sleep 1
done

# Update system clock
echo "Installing NTP..."
if ! sudo apt install ntpdate -qqy;
then
    { echo -e "\nBuild failed at: Installing NTP..."; exit 1; }
fi
echo -e "\nUpdating system clock..."
if ! sudo ntpdate -u ca.pool.ntp.org;
then
    { echo -e "\nBuild failed at: Updating system clock..."; exit 1; }
fi
echo -e "\nUpdating system packages..."
if ! (sudo apt update && sudo apt upgrade -qqy);
then
    { echo -e "\nBuild failed at: Updating system packages..."; exit 1; }
fi

# Install Dependencies
echo -e "\nInstalling required packages..."
if ! sudo apt install -qqy \
    ansible \
    build-essential \
    git \
    libssl-dev;
then
    { echo -e "\nBuild failed at: Installing required packages..."; exit 1; }
fi

# Install Rust
echo -e "\nInstalling Rust..."
if ! curl https://sh.rustup.rs -sSf | sh -s -- -y;
then
    { echo -e "\nBuild failed at: Installing Rust..."; exit 1; }
fi
# Activate Rust environment
# shellcheck source=/dev/null
source "$HOME"/.cargo/env
ls -a
pwd
# Clone Dora
echo -e "\nCloning Dora repository..."
if ! git clone https://github.com/bluecatengineering/dora;
then
    { echo -e "\nBuild failed at: Cloning Dora repository..."; exit 1; }
fi

# Install & deploy SQLx database
echo -e "\nInstalling SQLx CLI..."
if ! cargo install sqlx-cli;
then
    { echo -e "\nBuild failed at: Installing SQLx CLI..."; exit 1; }
fi
echo -e "\nCreating SQLx database..."
if ! (cd "$HOME"/dora && sqlx database create);
then
    { echo -e "\nBuild failed at: Creating SQLx database..."; exit 1; }
fi
echo -e "\nRunning SQLx migrations..."
if ! (cd "$HOME"/dora && sqlx migrate run);
then
    { echo -e "\nBuild failed at: Running SQLx migrations..."; exit 1; }
fi

# Build Dora
echo -e "\nBuilding Dora..."
if ! (cd "$HOME"/dora && cargo build);
then
    { echo -e "\nBuild failed at: Building Dora..."; exit 1; }
fi
PATH="$HOME"/dora/target/debug:$PATH

# Clone & install Containernet
echo -e "\nCloning Containernet repository..."
if ! git clone https://github.com/containernet/containernet.git;
then
    { echo -e "\nBuild failed at: Cloning Containernet repository..."; exit 1; }
fi
echo -e "\nInstalling Containernet..."
if ! ansible-playbook -i "localhost," -c local containernet/ansible/install.yml;
then
    { echo -e "\nBuild failed at: Installing Containernet..."; exit 1; }
fi

###############################
# Starting up Containernet/Dora
###############################

function stop_network {
    # Stop the network
    echo -e "\nStopping Containernet..."
    sudo mn -c
}

echo -e "\nCopying files..."
if ! (cp newest/mostly_working.py containernet/examples/mostly_working.py &&
      cp newest/Dockerfile.dylan containernet/examples/example-containers/Dockerfile.dylan &&
      cp newest/d1.yaml dora/d1.yaml)
then
    { echo -e "\nBuild failed at copying files..."; exit 1; }
fi

echo -e "\nBuilding Dora image..."
if ! { sudo docker build -f containernet/examples/example-containers/Dockerfile.dylan -t dora .; }
then
    { echo -e "\nBuild failed at building Dora image..."; exit 1; }
fi

echo -e "\nStarting Containernet..."
if ! sudo python3 containernet/examples/mostly_working.py;
then
    { echo -e "\nBuild failed at: Starting Containernet..."; stop_network; exit 1; }
fi

# Enter the network namespace of the container and execute a command
echo -e "\nChange netmask and broadcast on mn.d1..."
if ! sudo docker exec mn.d1 ifconfig d1-eth0 netmask 255.255.255.0 broadcast 10.0.0.255;
then
    { echo -e "\nBuild failed at: Change netmask and broadcast on mn.d1..."; stop_network; exit 1; }
fi

# EVERYTHING ABOVE WORKING
echo -e "\nRun Dora on mn.d1..."
if ! sudo docker exec mn.d1 DORA_LOG="debug" dora/target/debug/dora -c dora/d1.yaml -d dora/d1.db;
then
    { echo -e "\nBuild failed at: Run Dora on mn.d1..."; stop_network; exit 1; }
fi

echo -e "\nRun ifconfig on mn.d2..."
if ! sudo docker exec mn.d2 ifconfig d1-eth0 | awk '/inet /{print $2}';
then
    { echo -e "\nBuild failed at: ifconfig on mn.d2..."; stop_network; exit 1; }
fi

echo -e "\nDrop IP on mn.d2..."
if ! sudo docker exec mn.d2 -c "ip addr del 10.0.0.3/8 dev d2-eth0";
then
    { echo -e "\nBuild failed at: Drop IP on mn.d2..."; stop_network; exit 1; }
fi

echo -e "\nAsking Dora for a new IP..."
if ! sudo docker exec mn.d2 -c "dhclient -4";
then
    { echo -e "\nBuild failed at: Ask mn.d1 (Dora) for IP on mn.d2..."; stop_network; exit 1; }
fi

echo -e "\nRun ifconfig on mn.d2..."
if ! sudo docker exec mn.d2 ifconfig d1-eth0 | awk '/inet /{print $2}';
then
    { echo -e "\nBuild failed at: ifconfig on mn.d2..."; stop_network; exit 1; }
fi

sleep 60

# Stop the network
stop_network

echo -e "\nDone!"