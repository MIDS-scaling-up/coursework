# Streaming Tweet Processing

## Spark Streaming Introduction

In addition to providing mechanisms for working with RDDs from static sources like flat files, Apache Spark provides a processing model to work with stream input data. A **DStream** is a Spark abstraction for incoming stream data and can be operated on with many of the functions used to manipulate RDDs. In fact, a DStream object contains a series of data from the input stream split up into RDDs containing some set of data from the stream for a particular duration. A Spark user can register functions to operate on RDDs in the stream as they become available, or on multiple, consecutive RDDs by combining them.

For more information, please consult the [Spark Streaming Programming Guide](https://spark.apache.org/docs/latest/streaming-programming-guide.html).

## Part 1: Set up a 3-node Spark Cluster

Provision 3 VSes to comprise a Spark cluster. You may set up the cluster manually following the instructions from the previous assignment, [Apache Spark Introduction](../../week6/hw/apache_spark_introduction).

## Part 2: Set up Apache Tachyon RAM-based clustered storage layer

One of the benefits of Apache Spark's architecture is its use of RAM rather than disk storage to move calculated data between phases of execution. This feature yields improved performance for many programs. But the need to persist data from intermediate calculations is not totally obviated by Spark's paradigm: many long-running programs use results from calculations made in previous sampling periods in subsequent ones. Note that this is a need of a different sort than the distributed application framework's need: in this scenario, it is a matter of application requirements to make use of previous calculations in a program.

Spark can make use of many persistence solutions for both intermediate calculations and long-term storage. Often, Spark users will use HDFS or a lower-level disk-backed storage solution for this task. But this can create performance bottlenecks not unlike those that determined Apache Spark's RAM-based architecture for its own storage needs. One compelling in-RAM distributed storage solution is Apache Tachyon, a system that is often used as a high-performance caching layer for file-based storage.

In this assignment, you may use Tachyon to aggregate results between sampling periods for a program that runs for approximately 30 minutes. **Note**: You are **not required** to use Tachyon in this assignment, but you may find it useful.

### Tachyon installation

On each system, perform the following steps.

* Install Tachyon:

        curl -L https://github.com/amplab/tachyon/releases/download/v0.7.1/tachyon-0.7.1-bin.tar.gz | tar -zx -C /usr/local --show-transformed --transform='s,/*[^/]*,tachyon,'

* List workers in the Tachyon configuration file:

        cat > /usr/local/tachyon/conf/workers <<EOF
        spark1
        spark2
        spark3
        EOF

* Create `/usr/local/tachyon/conf/tachyon-env.sh` and set the master's IP (note that mine is 50.25.112.2, yours will be different):

        cp /usr/local/tachyon/conf/tachyon-env.sh.template /usr/local/tachyon/conf/tachyon-env.sh
        sed -i 's#export TACHYON_MASTER_ADDRESS=localhost#export TACHYON_MASTER_ADDRESS=50.25.112.2#g' /usr/local/tachyon/conf/tachyon-env.sh

* Create the checkpoint directory:

        mkdir -p /usr/local/tachyon/underFSStorage/tmp/tachyon/data

Execute the following steps only on __spark1__.

* Initialize and start Tachyon:

        cd /usr/local/tachyon
        ./bin/tachyon format
        ./bin/tachyon-start.sh all Mount

* Ensure all worker nodes have reported to the master by examining the UI output at http://{tachyon master ip}:19999/workers

* Run Tachyon's tests to ensure you've correctly set up the system:

        ./bin/tachyon runTests

If the system reports that all tests have passed, you may proceed. One of the benefits of Tachyon is its convenient and familiar API: it provides Java `File` objects for interaction which means using it from Spark amounts to reading and writing from file streams just like you would if you were to write directly the filesystem.

## Part 2: Build a Twitter popular topic and user reporting system

Design and build a system for collecting data about 'popular' hashtags and users related to tweets containing them. The popularity of hashtags is determined by the frequency of occurrence of those hashtags in tweets over a sampling period. Record popular hashtags and **both** the users who authored tweets containing them as well as other users mentioned in them. For example, if @solange tweets "@jayZ is performing #theblackalbum tonight at Madison Square Garden!! @beyonce will be there!", 'theblackalbum' is a popular topic, and all of the users related to the tweet—'beyonce', 'solange', and 'jayZ'—should be recorded.

The output of your program should be lists of hashtags that were determined to be popular during the program's execution, as well as lists of users, per-hashtag, who were related to them. Think of this output as useful to marketers who want to target people to sell products to: the ones who surround conversations about particular events, products, and brands are more likely to purchase them than a random user.

Your implementation should continually process incoming Twitter stream data for the duration of at least **30 minutes** and output a summary of data collected. During processing, your program should collect and aggregate tweets over a user-configurable sampling duration up to at least a few minutes. The number of top most popular hashtags, _n_, to aggregate **at each sampling interval** must be configurable as well. From tweets gathered during sampling periods you should determine:

- The top _n_ most frequently-occurring hashtags among all tweets during the sampling period
- The account names of users who authored tweets with popular hashtags in the period
- The account names of users who were mentioned in popular tweets

### Getting Started

Spark is written in Scala, a language that compiles to Java bytecode and runs on the Java Virtual Machine. It provides support for executing code written in languages other than Scala (like Jython, or Python on the JVM), but some features aren't implemented in such languages. You're welcome to implement this assignment in whichever of Spark's supported languages you wish. If you're not opposed to learning some Scala, I'd suggest you give it a try: it's a powerful language that fits well with Spark's paradigm.

#### Official Twitter Example

There is an official Spark Streaming Twitter example you can learn from. It's available at https://github.com/apache/spark/blob/master/examples/src/main/scala/org/apache/spark/examples/streaming/TwitterPopularTags.scala.

#### Twitter4J Library

The tweet abstractions your Spark program will receive are generated by a library called Twitter4J. The documentation is available at http://twitter4j.org/en. Of particular interest to you are these classes:

* http://twitter4j.org/javadoc/twitter4j/Status.html
* http://twitter4j.org/javadoc/twitter4j/User.html

If you'd like to understand how a Twitter4J `Status` object ends up in your Spark program, you might consult: https://github.com/apache/spark/blob/f85aa06464a10f5d1563302fd76465dded475a12/external/twitter/src/main/scala/org/apache/spark/streaming/twitter/TwitterInputDStream.scala.

#### Building with SBT

The Scala Build Tool (SBT) can be used to build a bytecode package (JAR file) for execution in a Spark cluster. You bundled such a JAR and executed it on a Spark cluster in the previous assignment, [Apache Spark Introduction](../../week6/hw/apache_spark_introduction). You can follow pattern similiar to the one established there for building a project and executing it. For convenience, you might start with the following project structure and files.

    ./twitter_popularity
    ├── build.sbt
    ├── project
    │   └── plugins.sbt
    └── twitter_popularity.scala

##### `build.sbt`

    lazy val common = Seq(
      organization := "week9.mids",
      version := "0.1.0",
      scalaVersion := "2.10.6",
      libraryDependencies ++= Seq(
        "org.apache.spark" %% "spark-streaming" % "1.5.0" % "provided",
        "org.apache.spark" %% "spark-streaming-twitter" % "1.5.0",
        "com.typesafe" % "config" % "1.3.0"
      ),
      mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
         {
          case PathList("META-INF", xs @ _*) => MergeStrategy.discard
          case x => MergeStrategy.first
         }
      }
    )

    lazy val twitter_popularity = (project in file(".")).
      settings(common: _*).
      settings(
        name := "twitter_popularity",
        mainClass in (Compile, run) := Some("twitter_popularity.Main"))

Note the specification of Spark library versions. Ensure that these version numbers match the version of Spark you have installed in your cluster or scary and terrible things may occur that prevent you from achieving Zen-like project execution bliss.

##### `project/plugins.sbt`

    addSbtPlugin("com.typesafe.sbteclipse" % "sbteclipse-plugin" % "3.0.0")
    addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.13.0")

##### `twitter_popularity.scala`

    object Main extends App {
      println(s"I got executed with ${args size} args, they are: ${args mkString ", "}")

      // your code goes here
    }

#### Building and Executing your code

From spark1 in the root of the project directory, execute the following where 'foof', 'goof' and 'spoof' are args to the Spark program:

    sbt clean assembly && $SPARK_HOME/bin/spark-submit \
      --master spark://spark1:7077 $(find target -iname "*assembly*.jar") \
      foof goof spoof

Note that the 'clean' build target is only necessary if you remove files or dependencies from a project; if you've merely changed or added files previously built, you can execute only the `package` target for a speedier build.

## Grading and Submission

This is a graded assignment. Please submit credentials to access your cluster and execute the program. The output can be formatted as you see fit, but must contain lists of popular hashtags and related people.

When submitting credentials to your Spark system, please provide a short description of a particularly interesting decision or two you made about the processing interval, features about collection, or other features of your collection system that make for particularly useful output data.
