## Genomic Assembly using BWA Spark

1.  Create or reuse an existing Spark cluster.  Just ensure that you have 3-4 nodes with 4 CPUs, 16 G RAM and 100G of disk each. The OS could be the latest 64-bit Ubuntu or CentOS, does not reall matter.  If you recall, we installed Spark before, and you could follow these general instructions here: https://github.com/MIDS-scaling-up/coursework/tree/master/week6/hw/apache_spark_introduction
2.  Install hadoop in the same cluster as well.  Follow the set up instructions here: https://github.com/MIDS-scaling-up/coursework/tree/master/week13/lab Once you are finished, you should have both Spark and Hadoop installed, HDFS running, and Spark configured to use Yarn as the scheduler.
3.  Now you can proceed with the installation of Spark BWA. You will need to make sure you have make, gcc, git installed (e.g. apt-get -y install gcc make git if you are using Ubuntu) https://github.com/citiususc/SparkBWA

## Validation
Make sure that BWA Spark is correctly installed and that the command below does not error out.
```
spark_dir/bin/spark-submit --class com.github.sparkbwa.SparkBWA --master yarn-cluster
--driver-memory 1500m --executor-memory 10g --executor-cores 1 --verbose
--num-executors 32 SparkBWA-0.2.jar -m -r -p --index /Data/HumanBase/hg38 -n 32 
-w "-R @RG\tID:foo\tLB:bar\tPL:illumina\tPU:illumina\tSM:ERR000589"
ERR000589_1.filt.fastq ERR000589_2.filt.fastq Output_ERR000589
```
