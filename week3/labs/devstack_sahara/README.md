# Lab: Hadoop over OpenStack DevStack using Sahara

## Part 1: Provision and Configure VSes

### Provision VSes
Use `slcli` to provision a VS with the latest version of 64bit CentOS, 2 or more cores, 8gb RAM, 1gbps internal and external nics and 100gb local hard drive.

#### VS Creation example:
    slcli vs create --datacenter=sjc01 --hostname=lab3 --domain=openstack.dye.zone --billing=hourly --key=IBM_local-2 --cpu=2 --memory=8192 --network=1000 --disk=100 --os=CENTOS_LATEST_64

### Order additional IPs

Order 4 static public IPs for your new openstack VS using the SL portal, https://control.softlayer.com/. Select the machine from the "Devices" menu and follow the link "order IPs".  You'll need to choose an endpoint address, choose the primary public IP of the system you provisioned.

Once the subnet order is complete, you'll receive an email message from SoftLayer specifying the range. Retain this information for configuration later.

### Configure and start DevStack

SSH to the machine and configure the _stack_ user:

    adduser stack
    echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

Clone DevStack Repository, switch to "Juno" build:

    yum install -y git
    su - stack
    git clone https://git.openstack.org/openstack-dev/devstack
    cd devstack
    git checkout stable/juno

Create the file `local.conf` and add the following content. Note that you must replace lines with values enclosed in `{}` with those appropriate to your system:

    [[local|localrc]]
    FLOATING_RANGE={first of your additional ips}/30
    FIXED_RANGE=10.11.12.0/24
    FIXED_NETWORK_SIZE=256
    FLAT_INTERFACE=eth0
    ADMIN_PASSWORD=changeme
    MYSQL_PASSWORD=changeme
    RABBIT_PASSWORD=changeme
    SERVICE_PASSWORD=changeme
    SERVICE_TOKEN=changeme
    enable_service sahara
    HOST_IP={public IP address of your VM}

Start DevStack and flush the iptables rules in the filter chain:

    sudo yum install -y iptables-services
    ./stack.sh
    sudo iptables -F INPUT

### Configure a Cluster

Connect to the dashboard by browsing to ``.

Browse to the "Images" area in the web UI. Import this image: http://sahara-files.mirantis.com/sahara-icehouse-vanilla-1.2.1-ubuntu-13.10.qcow2

Register the image in the image registry section of the data processing tab. Give your image a name, tag it as "vanilla, 1.2.1". The `userid` should be "ubuntu".

Create an "all in one" node group template. Include both job and task trackers, data and name nodes as well as __oozie__.

