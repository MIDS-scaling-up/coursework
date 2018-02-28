# Homework: Hadoop Distributed Sort with YARN and HDFS

## VM Provisioning

Set up 3 VM instances on Softlayer: __master__, __slave1__, __slave2__.

Please add your public key while provisioning the VMs (`slcli vs create ... --key KEYID`) so that you can login from your client without a password.

Please note, Hadoop 2.7.4 updated how resources are enforced. The default configuration requires at least 8 CPUs/cores and 8G of RAM per node.  You may choose to deploy with the increased ammount of resources or make some additional configuration updates that will be called out.

Get **2 CPUs**, **4G of RAM**, **1G private / public NICS** and **two disks: 25G and 100G local** the idea is to use
the 100G disk for HDFS data and the 25G disk for the OS and housekeeping.

Please note, Hadoop 2.7.4 updated how resources are enforced. The default configuration requires at least 8 CPUs/cores and 8G of RAM per node.  You may choose to deploy with the increased ammount of resources or make some additional configuration updates that will be called out.

For the master, you might do something like this:

    slcli vs create --datacenter=sjc01 --hostname=master --domain=mids.com --billing=hourly --key=<mykey> --cpu=2 --memory=4096 --disk=25 --disk=100 --network=1000 --os=CENTOS_LATEST_64

## VM Configuration

Note: Instructions in this section are to be performed on each node unless otherwise stated.

### Hosts file
* Log into VMs (all 3 of them) and update `/etc/hosts/` with each system's public IP addresses (note that it's preferred to use private IPs for this communication instead, but that complicates use of Hadoop's UIs. For this assignment, public IPs will do. Here's my hosts file:

        127.0.0.1 localhost.localdomain localhost
        50.22.13.216 master.hadoop.mids.lulz.bz master
        50.22.13.194 slave1.hadoop.mids.lulz.bz slave1
        50.22.13.217 slave2.hadoop.mids.lulz.bz slave2

Note that the admin UIs for Hadoop create hyperlinks using hostnames and not IPs; if you want to use all features of the UIs, add the public IPs of the systems to your workstation's `hosts` file too.

### 100G Disk Formatting
* You need to find out the name of your disk, e.g

        fdisk -l |grep Disk |grep GB
        - OR -
        cat /proc/partitions

Assuming your disk is called `/dev/xvdc` as it is for me,

    mkdir /data
    mkfs.ext4 /dev/xvdc

* Add this line to `/etc/fstab` (with the appropriate disk path):

        /dev/xvdc /data                   ext4    defaults,noatime        0 0

* Mount your disk and set the appropriate perms:

        mount /data
        chmod 1777 /data

## System setup

Note: Instructions in this section are to be performed on each node unless otherwise stated.

Install packages (installing the entire JDK rather than the JRE is necessary to get `jps` and other tools):

    yum install -y rsync net-tools java-1.8.0-openjdk-devel ftp://fr2.rpmfind.net/linux/Mandriva/devel/cooker/x86_64/media/contrib/release/nmon-14g-1-mdv2012.0.x86_64.rpm

### User setup preparation

* Create a user hadoop

        adduser hadoop

* Set a password for the `hadoop` user (you'll need this in the `ssh-copy-id` step in a moment):

        passwd hadoop

### Hadoop Download

Download hadoop v2 to `/usr/local` and extract it:

    curl http://apache.claz.org/hadoop/core/hadoop-2.7.4/hadoop-2.7.4.tar.gz | tar -zx -C /usr/local --show-transformed --transform='s,/*[^/]*,hadoop,'

Make sure your key directories have correct permissions

    chown -R hadoop.hadoop /data
    chown -R hadoop.hadoop /usr/local/hadoop

#### Switch to hadoop user

From now on, you're working as user __hadoop__. If you logout of your system and log back in again, you'll need to re-run this step.

    su - hadoop

### Configure passwordless SSH between systems

Create a keypair on __master__ and copy it to the other systems (when prompted by `ssh-keygen`, use defaults):

    ssh-keygen
    for i in master slave1 slave2; do ssh-copy-id $i; done

Still on the __master__, accept all keys by SSHing to each box and typing "yes" and, once you're logged into the remote box, typing `CTRL-d`:

    for i in 0.0.0.0 master slave1 slave2; do ssh $i; done

If the above command logged you in on each box without being prompted for a password, you've succeeded and you can move on. If not, investigate problems with your SSH passwordless configuration.

__You should do this step to avoid problems starting the cluster, and to add the slave nodes to the known hosts__.

### Configure Hadoop environment, storage, and cluster

On each system, update the hadoop user's environment and check it:

    echo "export JAVA_HOME=\"$(readlink -f $(which javac) | grep -oP '.*(?=/bin)')\"" >> ~/.bash_profile

    cat <<\EOF >> ~/.bash_profile
    export HADOOP_HOME=/usr/local/hadoop
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export YARN_HOME=$HADOOP_HOME
    export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
    EOF

    source ~/.bash_profile
    $JAVA_HOME/bin/java -version

## Hadoop configuration

Edit these configuration files on the __master__ only initially; an instruction to copy these files to the slave systems is provided later.

### Edit Configuration Files

* Go to the hadoop home directory `/usr/local/hadoop/etc/hadoop`

        cd $HADOOP_HOME/etc/hadoop

* Create JAVA_HOME variable in `hadoop_env.sh`:

        echo "export JAVA_HOME=\"$JAVA_HOME\"" > ./hadoop-env.sh

* Write this content to `core-site.xml`:

        <?xml version="1.0"?>
        <configuration>
          <property>
            <name>fs.defaultFS</name>
            <value>hdfs://master/</value>
          </property>
        </configuration>

* Write this content to `yarn-site.xml`:

        <?xml version="1.0"?>
        <configuration>
          <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>master</value>
          </property>
          <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
          </property>
        </configuration>
Note: if you want to use private IPs for your cluster, add this property also:

          <property>
           <name>yarn.resourcemanager.bind-host</name>
           <value>0.0.0.0</value>
          </property>

If you are using the 2 CPU/4G node configuration, you will need to add the following properties as well:

         <property>
            <name>yarn.nodemanager.resource.cpu-vcores</name>
            <value>2</value>
        </property>
        <property>
            <name>yarn.nodemanager.resource.memory-mb</name>
            <value>4096</value>
        </property>
          
* Write the following content to `mapred-site.xml`.

        <?xml version="1.0"?>
        <configuration>
          <property>
            <name>mapreduce.framework.name</name>
            <value>yarn</value>
          </property>
        </configuration>

* Write the following content to `hdfs-site.xml`.

        <?xml version="1.0"?>
        <configuration>
          <property>
              <name>dfs.datanode.data.dir</name>
              <value>file:///data/datanode</value>
          </property>

          <property>
              <name>dfs.namenode.name.dir</name>
              <value>file:///data/namenode</value>
          </property>

          <property>
              <name>dfs.namenode.checkpoint.dir</name>
              <value>file:///data/namesecondary</value>
          </property>
        </configuration>

* Copy all your files to the other machines since you need this configuration on all the nodes:

        rsync -a /usr/local/hadoop/etc/hadoop/* hadoop@slave1:/usr/local/hadoop/etc/hadoop/
        rsync -a /usr/local/hadoop/etc/hadoop/* hadoop@slave2:/usr/local/hadoop/etc/hadoop/

* Write the following content to the file `slaves` (note that you want to remove the values that are already there):

        master
        slave1
        slave2

## Create an HDFS filesystem

 * On the _master_ node, format your namenode before the first time you set up your cluster. __If you format a running Hadoop filesystem, you will lose all the data stored in HDFS.__

        hdfs namenode -format

## Starting The Cluster

* On _master_ node only, execute these startup scripts:

        start-dfs.sh
        start-yarn.sh

* Check the status of HDFS:

        hdfs dfsadmin -report

* Check YARN status:

        yarn node -list

* Start the Job History Server:

        mr-jobhistory-daemon.sh start historyserver

* To check your cluster, browse to:
   * http://master-ip:50070/dfshealth.html
   * http://master-ip:8088/cluster
   * http://master-ip:19888/jobhistory (for Job History Server)

(Note that not all links in these control UIs will work from your workstation; some

Log files are located under `$HADOOP_HOME/logs`.

You can check the java services running once your cluster is running using `jps`.

## Run Terasort

On _master_, execute the terasort job.

* The example below will generate a 10GB set and ingest it into the distributed filesystem:

_Note that the input to teragen is the number of 100 byte rows_

    cd /usr/local/hadoop/share/hadoop/mapreduce
    hadoop jar $(ls hadoop-mapreduce-examples-2*.jar) teragen 100000000 /terasort/in

* Now, let's do the sort:

        hadoop jar $(ls hadoop-mapreduce-examples-2*.jar) terasort /terasort/in /terasort/out

* Validate that everything completed successfully:

        hadoop jar $(ls hadoop-mapreduce-examples-2*.jar) teravalidate /terasort/out /terasort/val

* Clean up, e.g.:

        hdfs dfs -rm -r /terasort/\*
        
## To Turn In:
* A document with the output of the Terasort run.

## Optional: Build Hadoop native libs

Hadoop has native lib replacements for some Java libs. Your system may print warnings like these to the console if your system is not using the native libs:

    15/09/27 16:24:51 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable

You can safely ignore these warnings. However, if you're interested in building Hadoop native libs on your system and configuring Hadoop to use them, follow the directions below.

* If you're using the `hadoop` user account, exit it such that you're executing commands as `root`.

* Install build tools:

        yum install -y epel-release git && yum install -y protobuf-compiler cmake gcc gcc-c++ zlib-devel openssl-devel
        curl http://apache.cs.utah.edu/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz | tar xz -C /usr/local --show-transformed --transform='s,/*[^/]*,maven,'

* Become the `hadoop` user again and update the environment:

        sudo su - hadoop
        echo "export MAVEN_HOME=\"/usr/local/maven\"" >> ~/.bash_profile
        echo "export PATH=\"\$MAVEN_HOME/bin:\$PATH\"" >> ~/.bash_profile
        source ~/.bash_profile

If the foregoing commands have succeeded, `git --version` and `mvn -version` should report version information.

* Download the source code for the Hadoop version you have installed as `~hadoop/hadoop`. You might try the following Bash/grep insanity (note the output of `hadoop version` as of this writing contains the silly output string `Subversion https://git-wip-us.apache.org/repos/asf/hadoop.git -r 15ecc87ccf4a0228f35af08fc56de536e6ce657a`, which contains useful information but is misleading).

        HADOOP_CO=($(hadoop version | grep -oP '(?(?<=Subversion )[^ ]+|(?<=-r )(.+))')); \
        git clone ${HADOOP_CO[0]} && cd hadoop && git checkout ${HADOOP_CO[1]}

* Build Hadoop with the native option (note: this takes several minutes to complete, you might fetch some coffee or a snack while it compiles):

        mvn package -Pdist,native -DskipTests

* Copy the newly-built native libs to your Hadoop installation directory on each system running Hadoop:

        for i in master slave1 slave2; do rsync -avz --stats --progress ./hadoop-dist/target/hadoop-*/lib/native/* $i:$HADOOP_HOME/lib/native/; done

* If running, restart Hadoop:

        stop-dfs.sh && stop-yarn.sh && start-dfs.sh && start-yarn.sh

## Troubleshooting

* To debug connectivity problems, try connecting over SSH as the hadoop user from the master node to the others, each in turn.

* To inspect open ports and services running on them, execute `netstat -ntlp`.
