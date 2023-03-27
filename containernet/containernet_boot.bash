# Define variables

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
     ansible                    \
     curl                       \
     dnsutils                   \
     git                        \
     ifupdown                   \
     iproute2                   \
     iptables                   \
     iputils-ping               \
     net-tools                  \
     openvswitch-switch         \
     openvswitch-testcontroller \
     sudo                       \
     tcpdump

then
    { echo -e "\nBuild failed at: Installing required packages..."; exit 1; }
fi

# #Testing iwaseyusuke example
# echo -e "\nTesting iwaseyusuke example"
# if ! ( rm -rf /var/lib/apt/lists/* && touch /etc/network/interfaces && chmod +x /ENTRYPOINT.sh );
# then
#     { echo -e "\nBuild failed at: Testing iwaseyusuke example..."; exit 1; }
# fi
# echo -e "\nTesting iwaseyusuke example"
# if ! ( iptables -A INPUT -p tcp --dport 6633 -j ACCEPT &&
#        iptables -A INPUT -p tcp --dport 6640 -j ACCEPT
#      );
# then
#     { echo -e "\nBuild failed at: Testing iwaseyusuke example..."; exit 1; }
# fi

# Clone & install Containernet
echo -e "\nCloning Containernet repository..."
if ! git clone https://github.com/containernet/containernet.git $HOME/containernet;
then
    { echo -e "\nBuild failed at: Cloning Containernet repository..."; exit 1; }
fi


# echo -e "\nInstalling Containernet..."
# if ! ansible-playbook -i "localhost," -c local $HOME/containernet/ansible/install.yml;
# then
#     { echo -e "\nBuild failed at: Installing Containernet..."; exit 1; }
# fi

# echo -e "\nTesting iwaseyusuke example"
# if ! bash ENTRYPOINT.sh;
# then
#     { echo -e "\nBuild failed at: Testing iwaseyusuke example..."; exit 1; }
# fi

# #run test
# echo -e "\nTesting example.py"
# if ! sudo python3 $HOME/containernet/examples/containernet_example.py;
# then
#     { echo -e "\nBuild failed at: Testing example.py..."; exit 1; }
# fi

# sudo docker run -it --rm --privileged -e DISPLAY \
#     -v /tmp/.X11-unix:/tmp/.X11-unix \
#     -v /lib/modules:/lib/modules \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     docker_mininet


# MAY NEED TO EXPOSE PORTS 6633 6653 6640