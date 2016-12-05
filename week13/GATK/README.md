### Starting point for GATK / Spark

At the moment, there's https://github.com/broadinstitute/gatk  as the alpha / Spark-based release, but not all of the tools have been ported and documentation is lacking.

If you are cool with that and are anxious to get started, follow these steps:

* Get a docker container spun up with jdk 8:
```
docker run --name gatk -ti openjdk-jdk8 bash
```
* In the docker container, install some basic tools:
```
apt-get update && apt-get install -y git curl wget vim-tiny
```
* Install and compile GATK
```
git clone https://github.com/broadinstitute/gatk.git
cd gatk
./gradlew installAll
```
* Validate the installation
```
./gradlew test
```
* Get some samples from here: https://drive.google.com/drive/folders/0BwTg3aXzGxEDeXFfOEJSeHk3bnc?usp=sharing  This was written for the 
production (<4) version of GATK, but the folders container sample data.  So, if you install the aboce under /GATK-tutorial, you should be able to do this:
```
./gatk-launch PrintReadsSpark -I /root/GATK-tutorial_data/bams/NA12878_wgs_20.bam   -O foo.bam
```
