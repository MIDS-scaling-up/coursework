## 1.0. Introduction and reference

This lab is to familiarize you with the process of NGS -- next generation sequencing -- whereby already sequenced genomic fragments are aligned using a 
reference genome and then SNPs are identified.  We will be using the [crossbow tool](http://bowtie-bio.sourceforge.net/crossbow/index.shtml) for this lab


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

    $CROSSBOW_HOME/cb_hadoop \
    --preprocess \
    --input=hdfs:///crossbow/example/mouse17/full.manifest \
    --output=hdfs:///crossbow/example/mouse17/output_full \
    --reference=hdfs:///crossbow-refs/mm9_chr17.jar

This should take just under two hours.

You should see /crossbow/example/mouse17/output_full/17.gz  of 3.32MB in size  in HDFS if all goes well.
     hadoop dfs -get /crossbow/example/mouse17/output_full/17.gz .
Each individual record is in the [SOAPsnp](http://soap.genomics.org.cn/soapsnp.html) output format. SOAPsnp's format consists of 1 SNP per line with several tab-separated fields per SNP. The fields are:

    Chromosome ID
    1-based offset into chromosome
    Reference genotype
    Subject genotype
    Quality score of subject genotype
    Best base
    Average quality score of best base
    Count of uniquely aligned reads corroborating the best base
    Count of all aligned reads corroborating the best base
    Second best base
    Average quality score of second best base
    Count of uniquely aligned reads corroborating second best base
    Count of all aligned reads corroborating second best base
    Overall sequencing depth at the site
    Sequencing depth of just the paired alignments at the site
    Rank sum test P-value
    Average copy number of nearby region
    Whether the site is a known SNP from the file specified with -s
    
Note that field 15 was added in Crossbow and is not output by unmodified SOAPsnp. For further details, see the [SOAPsnp](http://soap.genomics.org.cn/soapsnp.html) manual.

## 2.0. Assembling a full human genome
This is a significant compute task (~500 core-hours) , so it'll take forever unless your cluster is up to par.  The cluster also needs to have at least 1 TB of space for temporary files.  We prepared two scripts for you that make is look easy.  The first one downloads the reference genome and the manifest and inserts it into HDFS.  IT only takes a few minutes to run:
    ./hg19-prep.sh
    
Once that's completed, all we need to do is kick off the processing and sit back / enjoy the show.  
    ./hg19-run.sh
