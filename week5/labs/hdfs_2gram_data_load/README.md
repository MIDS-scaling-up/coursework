# Lab: Load Google 2-gram dataset into HDFS

### Preconditions
This lab assumes you have a Hadoop v2 cluster set up that can store 26GB of compressed data across nodes. If you do not already have such a cluster, provision and set one up before beginning (see [Hadoop v2 Installation](../../hw/hadoop_yarn_sort/README.md)).

When using the Hadoop cluster, use the `hadoop` user. You can change user accounts and adopt the `hadoop` user's environment by executing:

    sudo su - hadoop

## Part 1: Configure Hadoop

We're going to use Hadoop mapreduce tasks to download Google's 2gram data files and write them to HDFS. Each file is approximately 1.6GB uncompressed. During unzipping, the task's container will store each uncompressed data file and so needs to be sized accordingly. Add this property to `$HADOOP_HOME/etc/hadoop/mapred-site.xml`:

    <property>
      <name>mapreduce.map.memory.mb</name>
      <value>1920</value>
    </property>
    <property>
      <name>mapreduce.reduce.memory.mb</name>
      <value>3072</value>
    </property>

Now copy the configuration to each member of the cluster and restart the cluster processes:

    for i in $(cat $HADOOP_HOME/etc/hadoop/slaves); do rsync -avz $HADOOP_HOME/etc/hadoop/ $i:$HADOOP_HOME/etc/hadoop/; done

    stop-dfs.sh && stop-yarn.sh && start-dfs.sh && start-yarn.sh

## Part 2: Fetch data scripts

In `/home/hadoop`, prepare `urls.txt` which we'll later use as input to a Hadoop map function:

    cat <<\EOF > mkinput.sh
    #!/bin/bash

    rm -f urls.txt

    for i in {0..9}; do echo http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-$i.csv.zip >> urls.txt; done
    EOF

Make the script executable and execute it:

    chmod +x ./mkinput.sh && $_

Prepare file-downloading script (the map function):

    cat <<\EOF > mapper.sh
    #!/bin/bash


    while read line;do
    wget $line -O - | gzip -d 2> /dev/null
    done
    EOF

Make the script executable:

    chmod +x mapper.sh

###  HDFS setup

Clean out the HDFS storage from previous work (**Caution**: this is destructive!):

    hadoop fs -rm -r /mumbler /terasort

Create destination directory and load `urls.txt` and the mapper executable into in HDFS:

    hadoop fs -mkdir /mumbler
    hadoop fs -cp file:///home/hadoop/mapper.sh hdfs:///mumbler
    hadoop fs -cp file:///home/hadoop/urls.txt hdfs:///mumbler

Verify that the files were written to HDFS:

    hadoop fs -ls /mumbler

## Part 3: Load data

Execute the map operation (note this will take a while, Google 2gram data files are downloaded in this stage; you might use `iftop` to watch download progress on one of the machines):

    hadoop jar $(ls $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar) \
    -Dmapreduce.job.reduces=0 \
    -files hdfs:///mumbler/mapper.sh \
    -input hdfs:///mumbler/urls.txt \
    -output hdfs:///mumbler/pass \
    -mapper mapper.sh \
    -inputformat org.apache.hadoop.mapred.lib.NLineInputFormat
