#Assignment 3: OpenStack Devstack Installation

##Instructions
###Setting up your VM 
Please use CentOS latest (7); these steps are documented with the current version of DevStack. 

You should already know how to provision a VM. Ensure that you give it a private key when you provision it. 

Recommended resources are 8 cpus, 32GB RAM, 100GB of disk. Once the VM is provisioned, go to the portal and order 16 Portable Private IP addresses on your VLAN by selecting your VM on the Devices list, then clicking "Order IPs" on the Private network section. Use ssh to connect once it comes up.

Enable iptables (to work around a new devstack installer bug)

    systemctl stop firewalld
    systemctl mask firewalld
    yum install -y iptables-services
    systemctl enable iptables

Install git

    yum install -y git yum-utils vim

You need a stack user to run the scripts. DevStack will not let you run them as root. Make a user, and then sign in as that user. 

    adduser stack

Give the stack user sudo permissions

    echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

Switch User to the stack user id

    su - stack 

Download DevStack 

    git clone https://github.com/openstack-dev/devstack.git 

Change to the new devstack directory

    cd devstack 

The devstack repo contains a script that installs OpenStack and templates for configuration files.

###Configure 
Look at these [configuration options](http://devstack.org/configuration.html) for reference. 

We will set up a minimal configuration file. 

First copy the file from `samples/local.conf` into the main devstack directory 

    cp ~/devstack/samples/local.conf ~/devstack/local.conf 

Then, edit the following arguments. Be sure to uncomment the HOST_IP and add your own IP. From here on we're assuming that the IP is 198.11.199.177. 

    SERVICE_TOKEN=stack 
    ADMIN_PASSWORD=stack 
    MYSQL_PASSWORD=stack 
    RABBIT_PASSWORD=stack 
    SERVICE_PASSWORD=$ADMIN_PASSWORD 
    HOST_IP=198.11.199.177
    # Enable heat services
    enable_service h-eng h-api h-api-cfn h-api-cw
    IMAGE_URLS+=",http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img,http://cdimage.debian.org/cdimage/openstack/8.0.0/debian-8.0.0-openstack-amd64.qcow2"

Open up firewall access

	sudo iptables -F INPUT

Start DevStack

    ./stack.sh

It takes a few minutes; we recommend reading the script while it is building. At the end, it will show you a summary. Follow the link to log on to Horizon. Log in with user `admin` and password `stack`, as printed.

Example Output:

    Horizon is now available at http://198.11.199.177/.
    Keystone is serving at http://198.11.199.177:5000/v2.0/.
    Examples on using novaclient command line is in exercise.sh.
    The default users are: admin and demo
    The password: stack
    This is your host ip: 198.11.199.177.
    stack.sh completed in 816 seconds.

Open a horizon port and novnc console port (use your own IP address)

    sudo iptables -I INPUT 3 -p tcp --dport 80 -s <YOUR_IP> -j ACCEPT
    sudo iptables -I INPUT 3 -p tcp --dport 6080 -s <YOUR_IP> -j ACCEPT

You can get your external IP with the ‘w’ command on your VM (it will be the address you appear to be logged in from if you connected with ssh directly from your machine) or from sites like http://ipaddress.org/ and http://whatismyip.com.

###Next steps 
Once you have completed the installation, use horizon to:

- Create a tenant/project
- Create a private/public keypair
- Create a security group
- Provision a VM using the keypair and security group you created
    - Connect to it (ubuntu images have a user called “ubuntu” and debian has “debian”)
    - Create a dummy file - avoid /tmp, and remember where it is, i.e.
    
	        touch ~/somefile
- Capture an image from the VM
- Kill the original VM
- Provision a new VM from from the image
- Ensure that the dummy file is there
- Finally, create a stack via Heat.  See example template at the bottom of this document.

When you are done, send the URL for your installation to the instructor. 

**Assignment due date:** 24 hours before the Week 3 live session

**To turn in:** Post the URL for your installation below.
**Grade:** Credit/No Credit

###Additional notes:
[Instructions for Installing DevStack on Dedicated Hardware](http://devstack.org/guides/single-machine.html) 
[stack.sh information](http://devstack.org/stack.sh.html) 
[DevStack GitHub](https://github.com/openstack-dev/devstack)

You can list your security groups and create them using the command line if you like:

    nova --os-username=admin --os-password=stack --os-tenant-name=admin --os-auth-url=http://198.11.199.177:5000/v2.0/ secgroup-list 
    nova --os-username=admin --os-password=stack --os-tenant-name=admin --os-auth-url=http://198.11.199.177:5000/v2.0/ secgroup-create name description

To create a simple heat template, you could use something like this:

    heat_template_version: 2013-05-23
    description: Simple template to deploy two compute instances
    resources:
      instance_a:
        type: OS::Nova::Server
        properties:
          key_name: p305
          image: fedora-20.x86_64
          flavor: m1.small
      instance_b:
        type: OS::Nova::Server
        properties:
          key_name: p305
          image: fedora-20.x86_64
          flavor: m1.small
