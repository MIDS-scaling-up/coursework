# Lab: Load Google 2-gram dataset into HDFS

### Preconditions
This lab assumes you have a Hadoop cluster set up that can store 26GB of compressed data across nodes. If you do not, provision and set up a Hadoop cluster before beginning.

## Part 1: Fetch data scripts

In `/home/hadoop`, prepare `urls.txt` which we'll later use as input to a Hadoop map function:

    cat <<\EOF > mkinput.sh
    #!/bin/bash

    rm -f urls.txt

    for i in {0..15}; do echo http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-$i.csv.zip >> urls.txt; done
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

Create destination directory and load `urls.txt` in HDFS:

    hadoop dfs -mkdir /mumbler
    hadoop dfs -cp file:///home/hadoop/urls.txt hdfs:///mumbler

Verify that the file is there:

    hadoop dfs -ls /mumbler

## Part 2: Load data

Execute the map operation (note this will take a while). Note that this assumes you're using Hadoop v1; if you're using Hadoop v2, substitute the following jar path: `/usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-2.6.0.jar`:

    hadoop jar /usr/local/hadoop/contrib/streaming/hadoop-streaming-1.2.1.jar -D mapred.reduce.tasks=0 \
    -input /mumbler/urls.txt -output /mumbler/pass -mapper mapper.sh -file /home/hadoop/mapper.sh \
    -inputformat org.apache.hadoop.mapred.lib.NLineInputFormat
