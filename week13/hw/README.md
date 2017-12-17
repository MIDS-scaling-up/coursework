## Genomic Assembly using BWA Spark

1.  Create or reuse an existing Spark cluster.  Just ensure that you have 3-4 nodes with 4 CPUs, 32G RAM and 100G of disk each. The OS could be the latest 64-bit Ubuntu or CentOS, does not really matter.  If you recall, we installed Spark before, and you could follow these general instructions here: https://github.com/MIDS-scaling-up/coursework/tree/master/week6/hw/apache_spark_introduction
2.  Install Hadoop with Yarn in the same cluster as well.  You don't need to create the hadoop userid or use multiple disks -- just one 100G disk is ok.  General instructions are here: https://github.com/MIDS-scaling-up/coursework/tree/master/week13/lab  
Do this on each node:
```
# download hadoop
curl http://apache.claz.org/hadoop/core/hadoop-2.7.4/hadoop-2.7.4.tar.gz | tar -zx -C /usr/local --show-transformed --transform='s,/*[^/]*,hadoop,'
# get the environment set up
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

# Create the data directory
# we don't have a separate disk to hold the data, so just use /root:
mkdir -m 777 /data
```
Edit the hadoop config files as we did in week 5:
```
cd $HADOOP_HOME/etc/hadoop
echo "export JAVA_HOME=\"$JAVA_HOME\"" > ./hadoop-env.sh
# core-site.xml:
# ensure that the name of your master node is correct below
<?xml version="1.0"?>
<configuration>
    <property>
      <name>fs.defaultFS</name>
      <value>hdfs://spark1/</value>
    </property>
</configuration>
# yarn-site.xml:
# ensure that the name of your master node is correct below
# If you are NOT using a 2 CPU/4G node configuration, you will need to add the corresponding properties as well.
# Key to this application is that Yarn has enough memory allocated to it, so make sure that yarn.scheduler.maximum-allocation-mb set to a high value (e.g. 20000 ) and same for yarn.nodemanager.resource.memory-mb
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
    <property>
       <name>yarn.resourcemanager.bind-host</name>
       <value>0.0.0.0</value>
     </property>
     <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>2</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
    </property>
    <property>
      <name>yarn.scheduler.maximum-allocation-mb</name>
      <value>20000</value>
    </property>
    <property>
      <name>yarn.nodemanager.resource.memory-mb</name>
      <value>20000</value>
    </property>    
</configuration>

# mapred-site.xml
<?xml version="1.0"?>
  <configuration>
    <property>
      <name>mapreduce.framework.name</name>
      <value>yarn</value>
    </property>
  </configuration>
  
# hdfs-site.xml
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
```
Now let's distribute the config files to the nodes:
```
rsync -a /usr/local/hadoop/etc/hadoop/* spark2:/usr/local/hadoop/etc/hadoop/
rsync -a /usr/local/hadoop/etc/hadoop/* spark3:/usr/local/hadoop/etc/hadoop/
```
Write the following content to the file slaves (note that you want to remove the values that are already there):
```
spark1
spark2
spark3
```
On the master node, format your namenode before the first time you set up your cluster. If you format a running Hadoop filesystem, you will lose all the data stored in HDFS.
```
hdfs namenode -format
```
On master node only, execute these startup scripts:
```
start-dfs.sh
start-yarn.sh
# check status
hdfs dfsadmin -report
yarn node -list
```
Once you are finished, you should have both Spark and Hadoop installed, HDFS running, and Spark configured to use Yarn as the scheduler. These are the web front-ends for monitoring:

* http://master-ip:50070/dfshealth.html
* http://master-ip:8088/cluster
* http://master-ip:19888/jobhistory (for Job History Server)

As a reminder, the original instructions that we followed in week 5 are here: https://github.com/MIDS-scaling-up/coursework/tree/master/week5/hw/hadoop_yarn_sort
 

3.  Now you can proceed with the installation of Spark BWA. You will need to make sure you have all the pre-requisites installed:
```
# if on Ubuntu:
apt-get -y install gcc make git zlib-devel maven 
# if on Centos:
yum install -y gcc make git zlib-devel maven 
```

You should be ready to install now simply as:
```
# assuming you are building this in /root
cd /root
git clone https://github.com/citiususc/SparkBWA.git
cd SparkBWA
mvn package
# Detailed instructions here:  https://github.com/citiususc/SparkBWA  
```
Note that this software is a bit unbaked, unfortunately, especially when it comes to error handling.  You may need to get used to reading output logs :(

Now, let us distribute our build to other nodes - not strictly required, but why not:
```
scp -r SparkBWA spark2:root/
scp -r SparkBWA spark3:root/
```

Make sure you get the raw reads from the 1000 Genomes Project and insert into HDFS. These will be the ones we will be aligning.
```
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12750/sequence_read/ERR000589_1.filt.fastq.gz
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12750/sequence_read/ERR000589_2.filt.fastq.gz
# uncompress
gzip -d ERR000589_1.filt.fastq.gz
gzip -d ERR000589_2.filt.fastq.gz
# push to HDFS
hdfs dfs -copyFromLocal ERR000589_1.filt.fastq /ERR000589_1.filt.fastq
hdfs dfs -copyFromLocal ERR000589_2.filt.fastq /ERR000589_2.filt.fastq
```
4. SparkBWA requires that the reference genome for your workload be installed on each node of your cluster as well. We will need to download the GATK resource bundle as described here: https://software.broadinstitute.org/gatk/download/bundle  I pulled down all the files under hg38, e.g.
```
# on the master node of your cluster
mkdir -pm 777 /Data/HumanBase
cd /Data/HumanBase
ftp ftp.broadinstitute.org
user: gsapubftp-anonymous
# enter these commands below to ensure non-interactive and binary modes
prompt
binary
cd bundle
cd hg38
mget *

```
5.  We need to index the human genome. Note that the command below will take 1-2 hours. 
```
# if on ubuntu
apt-get install -y bwa
# if on centos
yum install -y epel-release
yum install -y bwa
# now the indexing.. 
bwa index Homo_sapiens_assembly38.fasta.gz
```
Once this completes, we will need to propagate this directory to all other nodes, e.g.
```
ssh spark2 mkdir -m 777 /Data
ssh spark3 mkdir -m 777 /Data
rsync -av /Data/HumanBase spark2:/Data/
rsync -av /Data/HumanBase spark3:/Data/
# ...
```

## Validation [Running alignment]
Make sure that BWA Spark is correctly installed and that the command below runs to the end.  If you are successful, you will see a file called FullOutput.sam (4.67 GB) created in the /user/hadoop/OUTPUT_DIR directory of your HDFS.  Set the num-executors to the number of nodes in your cluster.  Set executor-cores to the number of cores in each VM in your cluster -- and if you see out of memory errors, go down.  The --index parameter should contain the base name of your reference genome files. Make sure the path to the SparkBWA jar file is correct in the line below. 
```
$SPARK_HOME/spark-submit --class com.github.sparkbwa.SparkBWA --master yarn --driver-memory 1500m --executor-memory 15g --executor-cores 2 --verbose --num-executors 4 /root/SparkBWA/target/SparkBWA-0.2.jar -m -r -p --index /Data/HumanBase/Homo_sapiens_assembly38.fasta.gz -n 32  -w "-R @RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589" /ERR000589_1.filt.fastq /ERR000589_2.filt.fastq OUTPUT_DIR
```
To submit this homework, send the output from the above command or a link to your FullOutput.sam file in HDFS
