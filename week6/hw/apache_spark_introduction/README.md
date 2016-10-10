# Apache Spark Introduction

There are numerous ways to run Apache Spark, even multiple cluster options. In this guide you'll use the simplest clustered configuration, Spark in a standalone cluster. Other options include Spark on a YARN cluster (we used YARN in /week5/hw/hadoop_yarn_sort) and Spark on a Mesos cluster. If you're interested in learning about these other clustered options, please ask about them in class.

## Provision machines

Provision **three** Centos 7 VSes in SoftLayer with 2 CPUs, 4GB RAM and a 100GB local hard drive. Name them __spark1__, __spark2__, and __spark3__.

## Configure connectivity between machines

Configure __spark1__ such that it can SSH to __spark1__, __spark2__, and __spark3__ without passwords using SSH keys, and by name. To do this, you'll need to configure `/etc/hosts`, generate SSH keys using `ssh-keygen`, and write the content of the public key to each box to the file `/root/.ssh/authorized_keys` (`ssh-copy-id` helps with key distribution; if you need assistance with these parts of the process, consult earlier homework assignments).

## Install Java, SBT, and Spark on all nodes

Install packages:

    curl https://bintray.com/sbt/rpm/rpm | sudo tee /etc/yum.repos.d/bintray-sbt-rpm.repo
    yum install -y java-1.8.0-openjdk-headless sbt

Set the proper location of `JAVA_HOME` and test it:

    echo export JAVA_HOME=\"$(readlink -f $(which java) | grep -oP '.*(?=/bin)')\" >> /root/.bash_profile
    source /root/.bash_profile
    $JAVA_HOME/bin/java -version

Download and extract a recent, prebuilt version of Spark (link obtained from ):

    curl http://www.gtlib.gatech.edu/pub/apache/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz | tar -zx -C /usr/local --show-transformed --transform='s,/*[^/]*,spark,'

For convenience, set `$SPARK_HOME`:

    echo export SPARK_HOME=\"/usr/local/spark\" >> /root/.bash_profile
    source /root/.bash_profile

## Configure Spark

On __spark1__, create the new file `$SPARK_HOME/conf/slaves` and content:

    spark1
    spark2
    spark3

From here on out, all commands you execute should be done on __spark1__ only. You may log in to the other boxes to investigate job failures, but you can control the entire cluster from the master. If you plan to use the Spark UI, it's convenient to modify your workstation's `hosts` file so that Spark-generated URLs for investigating nodes resolve properly.

## Start Spark from master

Once you’ve set up the `conf/slaves` file, you can launch or stop your cluster with the following shell scripts, based on Hadoop’s deploy scripts, and available in `$SPARK_HOME/`:

- `sbin/start-master.sh` - Starts a master instance on the machine the script is executed on
- `sbin/start-slaves.sh` - Starts a slave instance on each machine specified in the conf/slaves file
- `sbin/start-all.sh` - Starts both a master and a number of slaves as described above
- `sbin/stop-master.sh` - Stops the master that was started via the bin/start-master.sh script
- `sbin/stop-slaves.sh` - Stops all slave instances on the machines specified in the conf/slaves file
- `sbin/stop-all.sh` - Stops both the master and the slaves as described above

Start the master first, then open browser and see `http://<master_ip>:8080/`:

    $SPARK_HOME/sbin/start-master.sh

    starting org.apache.spark.deploy.master.Master, logging to /root/spark/sbin/../logs/spark-root-org.apache.spark.deploy.master.Master-1-spark1.out

Then, run the `start-slaves` script, refresh the window and see the new workers (note that you can execute this from the master).

    $SPARK_HOME/sbin/start-slaves.sh

    spark1: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/spark/sbin/../logs/spark-root-org.apache.spark.deploy.worker.Worker-1-spark1.out
    spark3: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/spark/sbin/../logs/spark-root-org.apache.spark.deploy.worker.Worker-1-spark3.out
    spark2: starting org.apache.spark.deploy.worker.Worker, logging to /usr/local/spark/sbin/../logs/spark-root-org.apache.spark.deploy.worker.Worker-1-spark2.out

## Example 1: Calculating Pi

Begin by executing a Scala example on __spark1__. Note that this operation will not execute on the cluster, only on __spark1__.

    $SPARK_HOME/bin/run-example SparkPi

Look for task output like this:

    15/06/10 16:36:23 INFO TaskSchedulerImpl: Removed TaskSet 0.0, whose tasks have all completed, from pool
    15/06/10 16:36:23 INFO DAGScheduler: Stage 0 (reduce at SparkPi.scala:35) finished in 0.706 s
    15/06/10 16:36:23 INFO DAGScheduler: Job 0 finished: reduce at SparkPi.scala:35, took 0.954864 s
    Pi is roughly 3.1436

Try a Python example (note that Python code executed in Spark is executed in the Jython interpreter, not CPython, the Python runtime with which you are likely most familiar):

    $SPARK_HOME/bin/spark-submit $SPARK_HOME/examples/src/main/python/pi.py

## Example 2: Use the Spark shell

Start the spark shell from $SPARK_HOME (otherwise you won't be able to find the README.md file as below)

    $SPARK_HOME/bin/spark-shell

At the shell prompt, `scala>`, execute:

    val textFile = sc.textFile("README.md")

This reads the local text file "README.md" into a Resilient Distributed Dataset or RDD (cf. https://spark.apache.org/docs/latest/quick-start.html) and sets the immutable reference "textFile". You should see output like this:

    15/06/10 16:43:34 INFO SparkContext: Created broadcast 0 from textFile at <console>:21
    textFile: org.apache.spark.rdd.RDD[String] = README.md MapPartitionsRDD[1] at textFile at <console>:21

You can interact with an RDD object. Try calling the following methods from the Spark shell:

    textFile.count()

    textFile.first()

Finally, execute a Scala collection transformation method on the RDD and then interrogate the transformed RDD:

    val linesWithSpark = textFile.filter(line => line.contains("Spark"))

    linesWithSpark.count()

Exit the Spark shell with `CTRL-D`.

## Example 3: Submitting a Scala program to Spark

You can process data in an RDD by providing a function to execute on it. Spark will schedule execution of that function, collect results and process them as instructed. This is a common use case for Spark and often it is accomplished by submitting Scala programs to a Spark cluster. You'll write a small Scala program and submit it to the master. Note that we're going to package the simple program using Scala Build Tool(SBT), http://www.scala-sbt.org/0.13/tutorial/index.html. Note that the version of Spark we're using expects applications written for Scala 2.10 and is incompatible with Scala 2.11.

### Install SBT

You installed SBT in a previous step. Upon first execution, SBT will download a number of dependent packages. Execute `sbt` to start this process. If the program gives you shell prompt (`>`), you're all set. Type `CTRL-D` to exit the shell and continue creating a program to run in Spark.

Write the following content into `SimpleApp.scala`:

    /* SimpleApp.scala */
    import org.apache.spark.SparkContext
    import org.apache.spark.SparkContext._
    import org.apache.spark.SparkConf

    object SimpleApp {
      def main(args: Array[String]) {
        val file = "file:///usr/local/spark/README.md" // Should be some file on your system
          val conf = new SparkConf().setAppName("Simple Application")
          val sc = new SparkContext(conf)
          val data = sc.textFile(file, 2).cache()
          val numAs = data.filter(line => line.contains("a")).count()
          val numBs = data.filter(line => line.contains("b")).count()

          println("+++++++++++ Lines with a: %s, Lines with b: %s ++++++++++".format(numAs, numBs))
      }
    }

Create a simple SBT build file in the same directory as the source file you created earlier. Write the following content to `build.sbt` (note the version of the `spark-core` dependency: this should match the Spark version from your cluster):

    name := "Simple Project"
    version := "1.0"
    scalaVersion := "2.10.4"
    libraryDependencies += "org.apache.spark" %% "spark-core" % "1.6.1"
    resolvers += "Akka Repository" at "http://repo.akka.io/releases/"

Package your program into a jar file (a standard Java archive) for submission to the Spark cluster:

    sbt package

This step should have produced a jar file in a subdir of the `target` directory. Execute the following command to locate it:

    find target -iname "*.jar"

Once you've located the archive, submit the program to the Spark cluster for execution:

    $SPARK_HOME/bin/spark-submit --class "SimpleApp" \
    --master spark://spark1:7077 \
    $(find target -iname "*.jar")

You might check the web UI (http://{spark1_ip}:8080/) to see that the application execution completed.

(If you have trouble executing this program in your cluster, you might try debugging with the switch `--master local[4]` instead).

## Submission

Please submit a document that contains both the logs and command line output from execution of the commands you submitted to Spark.
