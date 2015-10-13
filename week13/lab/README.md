# 1.0. Introduction and reference

This lab is to extend the cluster capability you have from the howework in week 13 and be able to execute your job with the data source from HDFS and with a YARN scheduler.

In this lab, you will find the instructions to deploy HDFS and YARN (the references to what you should already know).



# 2.0. Preparation of the HDFS and YARN


## 2.1. HDFS

Follow the instructions from the HW Week 5 to [deploy Hadoop.]
(https://github.com/MIDS-scaling-up/coursework/tree/master/week5/hw/hadoop_yarn_sort)
Make sure that you are using the same version of Hadoop as the Spark that you are loading, e.g.  http://apache.claz.org/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz

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
