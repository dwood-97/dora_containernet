# Define variables
CARGO_HOME=/usr/local/cargo
PATH=$CARGO_HOME/bin:$PATH

# Wait for lock file to become available
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
    echo "Waiting for dpkg lock file to become available..."
    sleep 1
done

# Install Dependencies
echo -e "\nUpdating system packages..."
if ! ( apt update -qq && apt upgrade -qqy );
then
    { echo -e "\nBuild failed at: Updating system packages..."; exit 1; }
fi
echo -e "\nInstalling required packages..."
if ! DEBIAN_FRONTEND=noninteractive apt-get -qq install \
     build-essential \
     curl            \
     git             \
     libssl-dev      \
     pkg-config
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

# Clone Dora
echo -e "\nCloning Dora repository..."
if ! git clone https://github.com/bluecatengineering/dora $HOME/dora;
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
