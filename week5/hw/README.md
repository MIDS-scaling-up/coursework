# Homework: Setting up Hadoop 1

## VM Provisioning

Set up 3 VM instances on Softlayer.

Please add your public key while provisioning the VMs (`slcli vs create ... --key KEYID`) so that you can login 
from your PC/Mac/laptop without a password.  You could use UBUNTU_LATEST_64 or REDHAT_LATEST_64 while 
provisioning (although ubuntu is a little cheaper).

Get **2 CPUs**, **4G of RAM**, **1G private / public NICS** and **two disks: 25G and 100G local** the idea is to use 
the 100G disk for HDFS data and the 25G disk for the OS and housekeeping.

## VM Configuration  

### Hosts file
 * Login into VMs (all 3 of them) and update `/etc/hosts/` for instance (add your own private IP addresses):

```
10.122.152.76 master  
10.122.152.77 slave1  
10.122.152.75 slave2  
```

### Passwordless SSH
 * Setup passwordless ssh from hadoop@master to hadoop@master, hadoop@slave1 and hadoop@slave2  
 * Add the public key (in `~/.ssh/id_rsa.pub`) to `/home/hadoop/.ssh/authorized_keys` on master, slave1 and slave2.  

## 100G Disk Formatting

 * You need to find out the name of your disk, e.g

```
fdisk -l |grep Disk |grep GB
OR
cat /proc/partitions
```

Assuming your disk is called `/dev/xvdc` as it is for me,

```
mkdir -m 777 /data
mkfs.ext4 /dev/xvdc
```

 * Add this line to `/etc/fstab`

```
...
/dev/xvdc /data                   ext4    defaults,noatime        0 0
```

 * Mount your disk

```
mount /data
```

## Hadoop Install

### Prerequisites 

 * Install JDK

**UBUNTU**

```
apt-get install default-jre
apt-get install default-jdk
```

**RHEL**

```
yum install java-1.6.0-openjdk*
```

 * Install nmon

**UBUNTU**

```
apt-get install nmon
```

**RHEL**

```
yum install nmon
```

### Hadoop Download

Download the files into `/usr/local` and extract it

```
cd /usr/local
wget http://apache.claz.org/hadoop/core/hadoop-1.2.1/hadoop-1.2.1.tar.gz
tar xzf hadoop-1.2.1.tar.gz
mv hadoop-1.2.1 hadoop
```

### Hadoop Install preparation

 * Create a user hadoop (all 3 nodes)

```
adduser hadoop
```

 * Make sure your key directories have correct permissions

```
chown -R hadoop.hadoop /data
chown -R hadoop.hadoop /usr/local/hadoop
```

 * From now on, you're working as user hadoop.

```
su – hadoop
```

 * Add to the end of .profile in hadoop's home directory:

```
...
export PATH=$PATH:/usr/local/hadoop/bin
```

 * Source these changes in to the open shell

```
source .profile
```

 * Create a key pair on the master node under the Hadoop user

```
hadoop@hadoopmaster ~] ssh-keygen –t rsa
Leave the passphrase blank. The public key and private key are saved in ~/.ssh/id_rsa.pub and
~/.ssh/id_rsa respectively.
```

### Edit Configuration Files 

 * Change `conf/master` and `conf/slave` (on the master node only)

In the `conf/master` file, list your master by name

```
master
```

 * In the `conf/slaves` file, list your slaves by name, one per line.```

```
master
slave1
slave2
```

__We need to edit the following configuration files in `/usr/local/hadoop/conf`.__

 * hadoop-env.sh

(Add the java home for your freshly installed java, e.g on ubuntu):

```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
```

 * core-site.xml

Add this configuration, make sure to use the name of the master node
in the value.

```
<configuration>
<property>
<name>fs.default.name</name>
<value>master:54310</value>
</property>
</configuration>
```

 * mapred-site.xml

Add this configuration, make sure to use the name of the master node
in the value.

```
<configuration>
<property>
<name>mapred.job.tracker</name>
<value>master:54311</value>
</property>
</configuration>
```

 * hdfs-site.xml

The `dfs.replication` value tells Hadoop how many copies of the data
it should make. With 3 nodes, we can set it to 3.

```
<configuration>
<property>
<name>dfs.replication</name>
<value>3</value>
</property>
<property>
<name>dfs.data.dir</name>
<value>/data</value>
</property>
</configuration>
```

 * Copy all your files to the other machines since you need this configuration on all the nodes:

```
scp –r /usr/local/hadoop/conf/* hadoop@hadoopslave1:/usr/local/hadoop/conf/
scp –r /usr/local/hadoop/conf/* hadoop@hadoopslave2:/usr/local/hadoop/conf
```

 * Format your NameNode the first time you set up your cluster. If you format a running Hadoop 
filesystem, you will lose all the data stored in HDFS.

```
/usr/local/hadoop/bin/hadoop namenode -format
```

## Starting the Cluster

 * After hadoop is installed and formatted, you can start your cluster with

```
/usr/local/hadoop/bin/start-all.sh
```

 * This will start all the daemons. You can also start them separately
with:

```
/usr/local/hadoop/bin/start-dfs.sh
/usr/local/hadoop/bin/start-mapred.sh
```

 * You can view information about your cluster at
   * http://hadoopmaster-ip:50070  
   * http://hadoopmaster-ip:50030  

## Stopping the cluster

```
/usr/local/hadoop/bin/stop-all.sh
```

This will stop all the daemons. You can also start them separately
with

```
/usr/local/hadoop/bin/stop-dfs.sh
/usr/local/hadoop/bin/stop-mapred.sh
```

Log files are located under `/usr/local/hadoop/logs`

You can check the java services running once your cluster is running using `jps`

## Run Terasort

 * The example below will generate a 10GB set:

_Note that the input to teragen is the number of 100 byte rows_

```
cd /usr/local/hadoop
hadoop jar hadoop-examples-1.2.1.jar teragen 100000000 /terasort/in
```

 * Now, let's do the sort

```
hadoop jar hadoop-examples-1.2.1.jar terasort /terasort/in /terasort/out
```

 * Validate that everything completed successfully:

```
hadoop jar hadoop-examples-1.2.1.jar teravalidate /terasort/out /terasort/val
```

 * Clean up, e.g.

```
hadoop dfs -rmr /terasort/*
```
