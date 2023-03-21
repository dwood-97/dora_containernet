#!/usr/bin/python

from mininet.net import Containernet
from mininet.node import Controller
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import info, setLogLevel
setLogLevel('info')

net = Containernet(controller=Controller)

info('*** Adding controller\n')
net.addController('c0')

info('*** Adding docker containers\n')
d1 = net.addDocker('d1', ip='10.0.0.1', dimage="dora",
                   volumes=["/home/dwood/dora:/dora"])
d2 = net.addDocker('d2', ip='10.0.0.3', dimage="dora")

info('*** Adding switches\n')
s1 = net.addSwitch('s1')
s2 = net.addSwitch('s2')

info('*** Creating links\n')
net.addLink(d1, s1)
net.addLink(s1, s2, cls=TCLink, delay='100ms', bw=1)
net.addLink(s2, d2)

info('*** Starting network\n')
net.start()

info('*** Testing connectivity\n')
net.ping([d1, d2])

CLI(net)
