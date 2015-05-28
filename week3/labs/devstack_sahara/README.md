# Lab: Hadoop over OpenStack DevStack using Sahara

## Part 1: Provision and Configure VSes

### Provision VSes
Use `slcli` to provision a VS with the latest version of 64bit Ubuntu, 2 or more cores, 8gb RAM, 1gbps internal and external nics and 100gb local hard drive.

#### VS Creation example:
    slcli vs create --datacenter=sjc01 --hostname=lab3 --domain=openstack.sftlyr.ws --billing=hourly --key=somekey --cpu=4 --memory=8192 --network=1000 --disk=100 --os=UBUNTU_LATEST_64 --san

Once you can login to the box, execute:

    cat /proc/cpuinfo | grep 'model name'

If you find the reported model is "Intel(R) Xeon(R) CPU E5-2650 v2", reprovision the VS. The DevStack installation version uses a libvirt version that is too old to identify this processor.

### Order additional IPs

After the box has been assigned a public IP address, order 4 more static public IPs using the SL portal, https://control.softlayer.com/. Select the machine from the "Devices" menu and follow the link "order IPs".  You'll need to choose an endpoint address, choose the primary public IP of the system you provisioned.

Once the subnet order is complete, you'll receive an email message from SoftLayer specifying the range. Retain this information for configuration later.

### Configure and start DevStack

SSH to the machine and configure the __stack__ user:

    adduser stack
    echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

Clone DevStack Repository, switch to "Juno" build:

    apt-get install -y git
    su - stack
    script /dev/null
    git clone https://git.openstack.org/openstack-dev/devstack
    cd devstack
    git checkout stable/juno

Create the file `local.conf` and add the following content. Note that you must replace lines with values enclosed in `{}` with those appropriate to your system:

    [[local|localrc]]
    FLOATING_RANGE={first of your additional ips}/30
    ADMIN_PASSWORD=stack
    MYSQL_PASSWORD=stack
    RABBIT_PASSWORD=stack
    SERVICE_PASSWORD=stack
    SERVICE_TOKEN=stack
    HOST_IP={public IP address of your VM}
    enable_service sahara

Start DevStack and flush the iptables rules in the filter chain (note: this operation will take some time to complete):

    ./stack.sh
    sudo iptables -F INPUT

### Configure and Launch a Cluster

Connect to the dashboard (Horizon) by browsing to `http://{public_ip}/` and authenticating with user _admin_ and password specified in the config.

Browse to the __Images__ section of the __Compute__ tab in the __Project__ area in the web UI. Create an image using the URL http://sahara-files.mirantis.com/sahara-icehouse-vanilla-1.2.1-ubuntu-13.10.qcow2. Select the type _qcow2_. Name it whatever you'd like.

Register the image in the __Image Registry__ section of the __Data Processing__ tab in the __Project__ area. Use `ubuntu` for the +_User Name_ and tag it as `vanilla, 1.2.1` (make sure to click "Add plugin tags" once the right values are selected).

In the __Node Group Templates__ section, create a new node group with _Plugin Name_ `Vanilla Apache Hadoop` and _Hadoop Version_ `1.2.1`. When prompted, choose a valid hostname for the _Template Name_. Choose `m1.medium` for the _Openstack Flavor_, `Ephemeral Drive` for _Storage location_, and `public` for _Floating IP_ pool. Ensure you include the following _processes_ `namenode`, `datanode`, `oozie`, `tasktracker` and `jobtracker`.

Create a corresponding cluster template in the __Cluster Templates__ section. Note that you needn't select any anti-affinity options in the __Details__ tab. To add your node group to the cluster template, click the __Node Groups__ tab, select your node group, and click the "__+__" button.

Launch your cluster. Don't forget to give it your keypair (create one if necessary). Be patient, the cluster will take some time to start. You can watch cluster setup log output by browsing to __Instances__ in the __Compute__ section. If your cluster status changes to _Error_, attach to the `screen` session on the DevStack VS to investigate output logs.

When complete, your cluster's jobtracker should be available at the URL `http://{your_floating_ip}:50030/jobtracker.jsp`.

Check the newly created security group for your cluster. Add the "ICMP -1" rule to enable ping.

### Use the Cluster

Copy the hadoop examples jar from your Cluster Instance to your local machine. It should be in `/usr/share/hadoop/hadoop-examples-1.2.1.jar` on your Hadoop instance.

Now, go the job binary area and create a job binary.  Upload this file, set "storage type = internal database".

Create a new job of type Java Action, add the above jar file / binary in the libs area—make sure you __add__ the binary under the library by clicking __choose__.

Run the job on your existing cluster.  Under "Configure", use `org.apache.hadoop.examples.ExampleDriver` as the `main` class.  Give it three Arguments on separate fields: "pi", "10", "10". Go the job tracker page, ensure that your job is running.
