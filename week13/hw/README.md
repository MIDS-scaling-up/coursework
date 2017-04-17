## Genomic Assembly using BWA Spark

1.  Create or reuse an existing Spark cluster.  Just ensure that you have 3-4 nodes with 4 CPUs, 16 G RAM (32G is even better!) and 100G of disk each. The OS could be the latest 64-bit Ubuntu or CentOS, does not really matter.  If you recall, we installed Spark before, and you could follow these general instructions here: https://github.com/MIDS-scaling-up/coursework/tree/master/week6/hw/apache_spark_introduction
2.  Install hadoop in the same cluster as well.  Follow the set up instructions here: https://github.com/MIDS-scaling-up/coursework/tree/master/week13/lab Once you are finished, you should have both Spark and Hadoop installed, HDFS running, and Spark configured to use Yarn as the scheduler.  Key to this application is that Yarn has enough memory allocated to it, so make sure that yarn-site.xml  has yarn.scheduler.maximum-allocation-mb set to a high value (if you have 32G of RAM, set it to 20000 ) and do the same for yarn.nodemanager.resource.memory-mb.
3.  Now you can proceed with the installation of Spark BWA. You will need to make sure you have make, gcc, git, libz-devel installed (e.g. apt-get -y install gcc make git libz-devel if you are using Ubuntu).  Follow the instructions here:  https://github.com/citiususc/SparkBWquires
4. SparkBWA requires that the reference genome for your workload be installed on each node of your cluster. We will need to download the GATK resource bundle as described here: https://software.broadinstitute.org/gatk/download/bundle  I pulled down all the files under hg38, e.g.
```
# on the master node of your cluster
mkdir -m 777 /Data/HumanBase
cd /Data/HumanBase
ftp ftp.broadinstitute.org
user: gsapubftp-anonymous
prompt
binary
cd bundle
cd hg38
mget *

```
5.  We need to index the human genome. Note that the command below will take 1-2 hours. 
```
apt-get install -y bwa
bwa index Homo_sapiens_assembly38.fasta
```
Once this completes, we will need to propagate this directory to all other nodes, e.g.
```
scp -r /Data/HumanBase spark2:/
scp -r /Data/HumanBase spark3:/
# ...
```

## Validation [Running alignment]
Make sure that BWA Spark is correctly installed and that the command below runs to the end.  If you are successful, you will see a file called FullOutput.sam (4.67 GB) created in the /user/hadoop/OUTPUT_DIR directory of your HDFS.  Set the num-executors to the number of nodes in your cluster.  Set executor-cores to the number of cores in each VM in your cluster -- and if you see out of memory errors, go down.  The --index parameter should contain the base name of your reference genome files.
```
$SPARK_HOME/spark-submit --class com.github.sparkbwa.SparkBWA --master yarn --driver-memory 1500m --executor-memory 15g --executor-cores 2 --verbose --num-executors 4 SparkBWA-0.2.jar -m -r -p --index /Data/HumanBase/Homo_sapiens_assembly38.fasta -n 32  -w "-R @RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589" /ERR000589_1.filt.fastq /ERR000589_2.filt.fastq OUTPUT_DIR
```
To submit this homework, send the output from the above command or a link to your FullOutput.sam file in HDFS
