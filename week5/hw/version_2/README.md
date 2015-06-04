# Homework: Setting up Hadoop 2

## VM Provisioning

Set up 3 VM instances on Softlayer- master, slave1, slave2.

Please add your public key while provisioning the VMs (`slcli vs create ... --key KEYID`) so that you can login 
from your PC/Mac/laptop without a password.  You could use UBUNTU_LATEST_64 or REDHAT_LATEST_64 while 
provisioning (although ubuntu is a little cheaper).

Get **2 CPUs**, **4G of RAM**, **1G private / public NICS** and **two disks: 25G and 100G local** the idea is to use 
the 100G disk for HDFS data and the 25G disk for the OS and housekeeping.

## VM Configuration  - for each node unless otherwise stated

### Hosts file
 * Login into VMs (all 3 of them) and update `/etc/hosts/` for instance (add your own private IP addresses):

```
10.122.152.76 master  
10.122.152.77 slave1  
10.122.152.75 slave2  
```

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

 * Add this line to `/etc/fstab` (with the appropriate disk path):

```
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
apt-get install -y default-jre default-jdk
```

**RHEL**

```
yum install -y java-1.6.0-openjdk*
```

 * Install nmon

**UBUNTU**

```
apt-get install -y nmon
```

**RHEL**

```
yum install -y nmon
```

### Hadoop Download

Download the files into `/usr/local` and extract it

```
cd /usr/local
wget http://apache.claz.org/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz
tar xzf hadoop-2.6.0.tar.gz
mv hadoop-2.6.0 hadoop
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

#### Passwordless SSH 

 * Add the public key (in `~root/.ssh/id_rsa.pub`) to `~hadoop/.ssh/authorized_keys` on master

```
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys 
```

 * Copy the key pair and authorized hosts from the root user to the Hadoop user

```
mv ~hadoop/.ssh{,-old}
cp -a ~/.ssh ~hadoop/.ssh
chown -R hadoop ~hadoop/.ssh
```

 * Setup passwordless ssh from hadoop@master to hadoop@master, hadoop@slave1 and hadoop@slave2 by copying the files in `~hadoop/.ssh` between them.  __From your workstation, substituting MASTER-IP, etc with your VM IPs__

First accept all keys

```
for IP in MASTER-IP SLAVE1-IP SLAVE2-IP; do ssh-keyscan -H $IP >> ~/.ssh/known_hosts; done
```

Then copy the files around, preserving permissions

```
ssh root@MASTER-IP 'tar -czvp /home/hadoop/.ssh' | ssh root@SLAVE1-IP 'cd /; tar -xzvp'
ssh root@SLAVE1-IP 'tar -czvp /home/hadoop/.ssh' | ssh root@SLAVE2-IP 'cd /; tar -xzvp'
```

 * Test your work by trying to ssh __from user hadoop, on master__ to __master (itself)__, slave1 and slave2.  You should issue commands and see output like this:

__The administrative scripts use ssh to start the namenode(s), tasktrackers and datanodes on each, including master__

```
root@master:~# su - hadoop
hadoop@master:~$ ssh master
The authenticity of host 'master (10.76.68.69)' can't be established.
ECDSA key fingerprint is 98:da:1e:45:cf:d4:6f:51:b4:c3:ee:fe:d8:1c:ee:ad.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'master,10.76.68.69' (ECDSA) to the list of known hosts.
...
hadoop@master:~$ logout
Connection to slave1 closed.
hadoop@master:~$
```

```
root@master:~# su - hadoop
hadoop@master:~$ ssh slave1
The authenticity of host 'slave1 (10.76.68.81)' can't be established.
ECDSA key fingerprint is 98:da:1e:45:cf:d4:6f:51:b4:c3:ee:fe:d8:1c:ee:ad.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'slave1,10.76.68.81' (ECDSA) to the list of known hosts.
...
hadoop@slave1:~$ logout
Connection to slave1 closed.
hadoop@master:~$
```

```
hadoop@master:~$ ssh slave2
The authenticity of host 'slave2 (10.76.68.106)' can't be established.
ECDSA key fingerprint is 17:b3:54:cc:b8:ef:82:9c:e3:cd:43:91:1c:15:c7:e6.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added 'slave2,10.76.68.106' (ECDSA) to the list of known hosts.
...
hadoop@slave2:~$ logout
Connection to slave2 closed.
hadoop@master:~$
```

__You should do this step to avoid problems starting the cluster, and to add the slave nodes to the known hosts__ 

### Switch to hadoop user

 * From now on, you're working as user hadoop.

```
su – hadoop
```

 * Add this line to the end of `.profile` in hadoop's home directory:

```
export PATH=$PATH:/usr/local/hadoop/bin
```

 * Source these changes in to the open shell

```
source .profile
```

### Edit Configuration Files 

 * Go to the hadoop home directory `/usr/local/hadoop/etc/hadoop`

```
cd /usr/local/hadoop/etc/hadoop
```

 * Change `./masters` and `./slaves` files (on the master node only)

In the `./masters` file, list your master by name

```
master
```

 * In the `./slaves` file, list your slaves by name, one per line.```

```
master
slave1
slave2
```

__We need to edit the following configuration files in `/usr/local/hadoop/etc/hadoop`.__

 * `hadoop-env.sh`

(Add the java home for your freshly installed java, e.g on ubuntu):

```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
```

 * `yarn-env.sh`

(Add the java home here too)

```
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
```

 * `core-site.xml`

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

 * `mapred-site.xml`

```
<configuration>
<property>
<name>mapreduce.framework.name</name>
<value>yarn</value>
</property>
</configuration>
```


 * `hdfs-site.xml`

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

 * `yarn-site.xml`

```
<configuration>
<property>
<name>yarn.nodemanager.aux-services</name>
<value>mapreduce_shuffle</value>
</property>
<property>
<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</
name>
<value>org.apache.hadoop.mapred.ShuffleHandler</value>
</property>
<property>
<name>yarn.resourcemanager.resource-tracker.address</name>
<value>master:8025</value>
</property>
<property>
<name>yarn.resourcemanager.scheduler.address</name>
<value>master:8030</value>
</property>
<property>
<name>yarn.resourcemanager.address</name>
<value>master:8050</value>
</property>
</configuration>
```

 * Copy all your files to the other machines since you need this configuration on all the nodes:

```
scp –r /usr/local/hadoop/etc/hadoop/* hadoop@slave1:/usr/local/hadoop/etc/hadoop/
scp –r /usr/local/hadoop/etc/hadoop/* hadoop@slave2:/usr/local/hadoop/etc/hadoop/
```

 * Format your namenode before the first time you set up your cluster. __If you format a running Hadoop filesystem, you will lose all the data stored in HDFS.__

```
hadoop namenode -format
```

## Starting The Cluster

 * For master node, start everything. 

```
/usr/local/hadoop/sbin/hadoop-daemon.sh --config /usr/local/hadoop/etc/hadoop --script hdfs start namenode
/usr/local/hadoop/sbin/yarn-daemon.sh --config /usr/local/hadoop/etc/hadoop/ start resourcemanager
/usr/local/hadoop/sbin/yarn-daemon.sh start proxyserver --config /usr/local/hadoop/etc/hadoop/
/usr/local/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver --config /usr/local/hadoop/etc/hadoop
```

 * For slave nodes, only start DataNode and NodeManager.

```
/usr/local/hadoop/sbin/yarn-daemon.sh --config /usr/local/hadoop/etc/hadoop/ start nodemanager
/usr/local/hadoop/sbin/hadoop-daemon.sh --config /usr/local/hadoop/etc/hadoop --script hdfs start datanode
```

 * To check your cluster, go to:
   * http://master-ip:50070/dfshealth.jsp
   * http://master-ip:8088/cluster
   * http://master-ip:19888/jobhistory (for Job History Server)

Log files are located under `/usr/local/hadoop/logs`

You can check the java services running once your cluster is running using `jps`

## Run Terasort

 * The example below will generate a 10GB set:

_Note that the input to teragen is the number of 100 byte rows_

```
cd /usr/local/hadoop/share/hadoop/mapreduce
hadoop jar hadoop-mapreduce-examples-2.6.0.jar teragen 100000000 /terasort/in
```

 * Now, let's do the sort

```
hadoop jar hadoop-mapreduce-examples-2.6.0.jar terasort /terasort/in /terasort/out
```

 * Validate that everything completed successfully:

```
hadoop jar hadoop-mapreduce-examples-2.6.0.jar teravalidate /terasort/out /terasort/val
```

 * Clean up, e.g.

```
hdfs dfs -rmr /terasort/\*
```
