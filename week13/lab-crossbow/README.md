# 1.0. Introduction and reference

This lab is to familiarize you with the process of NGS -- next generation sequencing -- whereby already sequenced genomic fragments are aligned using a 
reference genome and then SNPs are identified.  We will be using the [crossbow tool](http://bowtie-bio.sourceforge.net/crossbow/index.shtml) for this task



# 2.0. Preparing the cluster


## 2.1. HDFS

Pick a machine where you have the SoftLayer CLI installed.  Clone the simple cluster repo:


git clone https://github.com/bmwshop/simplecluster


The file to edit is "globals".  Here, you could change the number of nodes in the cluster and their size, etc.
Set the CLUSTER_TYPE to "crossbow".  By default, the tool will provision one master and four slave nodes.  Kick off cluster provisioning, e.g.


./make_cluster.sh


After a while, the cluster will come up. Now you can connect:


cat master.txt 


This will give you the internal and external ip of your cluster, e.g.  10.53.71.247 50.23.76.251 master

Try http://clusterexternalip:50030  to connect to your job tracker


Try http://clusterexternalip:50070 to connect to the DFS


To connect to the master node as use hadoop, do


./sshmaster.sh


To be sure, let's validate crossbow:


cd crossbow && ./cb_local --test

It should pass as OK.  If not , you'll need to go back..

[c] Get the mouse chromosome 17 example working, as described here:
http://bowtie-bio.sourceforge.net/crossbow/manual.shtml#cb-example-mouse17-hadoop

# do the prep.. this will take a while.. 
cd $CROSSBOW_HOME/reftools
# this will prepare the reference genome for the chromosome  and the manifest.. 
# this will take ~ 10 min
./mm9_chr17_jar

# push the ref genome into hdfs
hadoop dfs -mkdir /crossbow-refs
hadoop dfs -put $CROSSBOW_HOME/reftools/mm9_chr17/mm9_chr17.jar /crossbow-refs/mm9_chr17.jar

# push the manifest into hdfs
hadoop dfs -mkdir /crossbow/example/mouse17
hadoop dfs -put $CROSSBOW_HOME/example/mouse17/full.manifest /crossbow/example/mouse17/full.manifest

# now you should be able to run it, e.g.
$CROSSBOW_HOME/cb_hadoop \
    --preprocess \
    --input=hdfs:///crossbow/example/mouse17/full.manifest \
    --output=hdfs:///crossbow/example/mouse17/output_full \
    --reference=hdfs:///crossbow-refs/mm9_chr17.jar
	
# this should take just under two hours.
# you should see /crossbow/example/mouse17/output_full/17.gz  of 3.32MB in size  if all goes well.



The main files to update are: masters, slaves, core-site.xml, hdfs-site.xml, hadoop-env.sh

Start HDFS and format the HDFS disk.

## 2.2. YARN

At the same location of the HADOP configuration files, you need to update the files: yarn-site.xml and yarn-env.sh. In the yarn-env.sh, specify the JAVA_HOME. 

In the yarn-site.xml, add some configurations as follows (feel free to try some other values depend on your machine config). The following assumes you have a machine with 4 CPUs and 16GB memory:

    <configuration>
      <!-- Site specific YARN configuration properties -->
      <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>16000</value>
      </property>
      <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>2048</value>
      </property>
      <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>3</value>
      </property>
    </configuration>

In the mapred-site.xml, specify YARN at the scheduler

    <configuration>
      <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
      </property>
    </configuration>

Distribute the configuration files to all nodes, then start YARN daemon with the $HADOOP_HOME/sbin/start-all.sh
    

## 2.3. Configure Spark to use HDFS and YARN

Now we want to tell Spark to use Hadoop. For that, make a copy

    cp -p $SPARK_HOME/conf/spark-env.sh.template $SPARK_HOME/conf/spark-env.sh

Set these variables:
    
    SPARK_WORKER_MEMORY=16G
    HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop    
    SPARK_MASTER_IP=<Your master node IP>

Then restart Spark.
 
## 2.4. Run the ADAM transformation using HDFS and YARN

First you need to put the input sample file into HDFS.

    hdfs dfs -mkdir vcf
    hdfs dfs -put ~/genedata/all.y.vcf vcf/all.y.vcf

Then run your Spark job

    time adam-submit --master yarn --executor-memory 4G --driver-cores 1 --executor-cores 1 --num-executors 2 vcf2adam vcf/all.y.vcf vcf/all.y.adam


## 2.5. Submission

Please submit a document that contains both the logs and command line output from execution of the commands you submitted to Spark.
