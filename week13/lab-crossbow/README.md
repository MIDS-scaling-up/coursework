## 1.0. Introduction and reference

This lab is to familiarize you with the process of NGS -- next generation sequencing -- whereby already sequenced genomic fragments are aligned using a 
reference genome and then SNPs are identified.  We will be using the [crossbow tool](http://bowtie-bio.sourceforge.net/crossbow/index.shtml) for this task


## 2.0. Preparing the cluster

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

It should pass as OK.  If not , you'll need to debug :)

## 3.0 Assemble Mouse Chromosome 17
This section follows [this guide](http://bowtie-bio.sourceforge.net/crossbow/manual.shtml#cb-example-mouse17-hadoop)

cd $CROSSBOW_HOME/reftools

This will prepare the reference genome for the chromosome  and the manifest file.  It will take ~ 10 min

./mm9_chr17_jar

Now push the ref genome into hdfs:

hadoop dfs -mkdir /crossbow-refs

hadoop dfs -put $CROSSBOW_HOME/reftools/mm9_chr17/mm9_chr17.jar /crossbow-refs/mm9_chr17.jar

Now push the manifest into hdfs:

hadoop dfs -mkdir /crossbow/example/mouse17

hadoop dfs -put $CROSSBOW_HOME/example/mouse17/full.manifest /crossbow/example/mouse17/full.manifest

We are now able to run it, e.g.
'''
$CROSSBOW_HOME/cb_hadoop \
    --preprocess \
    --input=hdfs:///crossbow/example/mouse17/full.manifest \
    --output=hdfs:///crossbow/example/mouse17/output_full \
    --reference=hdfs:///crossbow-refs/mm9_chr17.jar
'''	
This should take just under two hours.

You should see /crossbow/example/mouse17/output_full/17.gz  of 3.32MB in size  if all goes well.

