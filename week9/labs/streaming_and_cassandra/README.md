# Lab: Spark Streaming and Cassandra

## Preconditions

This lab assumes you have a Spark instance set up, that you can use `sbt` to build Scala projects and assemble a jar, and that you have twitter API credentials. If you need to set up a Spark instance (note that it needn't be a cluster, you can use the master only), consult [Apache Spark Introduction](../../../week6/hw/apache_spark_introduction).

If you need to get Twitter API access, create a twitter account and then create an application in [Twitter Application Management](https://apps.twitter.com/). You'll need the following credential values:

    consumerKey
    consumerSecret
    accessToken
    accessTokenSecret

## Part 1: Build a Spark Streaming App to Consume Tweets

Create a project directory (we'll use `/root/tweeteat` in this guide) and write these files:

### `/root/tweeteat/build.sbt`

    name := "Simple Project"
    version := "1.0"
    scalaVersion := "2.11.11"
    libraryDependencies += "org.apache.spark" %% "spark-core" % "2.1.0"
    libraryDependencies += "org.apache.spark" % "spark-streaming_2.11" % "2.1.0"
    libraryDependencies += "org.apache.spark" % "spark-sql_2.11" % "2.1.0"
    libraryDependencies += "org.apache.bahir" %% "spark-streaming-twitter" % "2.1.0"
    libraryDependencies += "com.datastax.spark" %% "spark-cassandra-connector" % "2.0.3"
    resolvers += "Akka Repository" at "http://repo.akka.io/releases/"

**Note:** The library dependencies for Spark listed in this file need to have versions that match the version of Spark you're running on your server. Change the version numbers here if necessary.

### `/root/tweeteat/tweeteat.scala`

    import org.apache.spark.streaming.Seconds
    import org.apache.spark.SparkConf
    import org.apache.spark.streaming.twitter._

    import com.datastax.spark.connector.streaming._
    import com.datastax.spark.connector.SomeColumns

    import org.apache.spark._
    import org.apache.spark.streaming._
    import org.apache.spark.streaming.StreamingContext._


    object TweatEat  extends App {
        val batchInterval_s = 1
        val totalRuntime_s = 32
        //add your creds below

        System.setProperty("twitter4j.oauth.consumerKey", "")
        System.setProperty("twitter4j.oauth.consumerSecret", "")
        System.setProperty("twitter4j.oauth.accessToken", "")
        System.setProperty("twitter4j.oauth.accessTokenSecret", "")
        // create SparkConf
        val conf = new SparkConf().setAppName("mids tweeteat");

        // batch interval determines how often Spark creates an RDD out of incoming data

        val ssc = new StreamingContext(conf, Seconds(2))

        val stream = TwitterUtils.createStream(ssc, None)

        // extract desired data from each status during sample period as class "TweetData", store collection of those in new RDD
        val tweetData = stream.map(status => TweetData(status.getId, status.getUser.getScreenName, status.getText.trim))
         tweetData.foreachRDD(rdd => {
        // data aggregated in the driver
         println(s"A sample of tweets I gathered over ${batchInterval_s}s: ${rdd.take(10).mkString(" ")} (total tweets fetched: ${rdd.count()})")
        })
        
        // start consuming stream
        ssc.start
        ssc.awaitTerminationOrTimeout(totalRuntime_s * 1000)
        ssc.stop(true, true)

        println(s"============ Exiting ================")
        System.exit(0)
    }

    case class TweetData(id: Long, author: String, tweet: String)



**Note:** Ensure that you add your credential strings for the Twitter API to the system properity lines in the scala file above.

### Run the app

Package the tweeteat app into a jar file suitable for execution on Spark (note that this operation will take a little time to complete the first time you run it because it downloads package dependencies; subsequent builds will be faster):

    sbt clean package

You should now have a jar file packaged a subdir of the `target` directory. You can find it from the project directory with this command:

    find . -iname "*.jar"

Start the Spark cluster and submit the application for execution:

    $SPARK_HOME/bin/spark-submit --master spark://spark1:7077  --packages org.apache.bahir:spark-streaming-twitter_2.11:2.1.0,com.datastax.spark:spark-cassandra-connector_2.11:2.0.3  --class TweatEat $(find target -iname "*.jar") 

Please note the packages used.  If your versions different, you'll need to update.
You should see output like this:

    [root@spark1 tweeteat]# $SPARK_HOME/bin/spark-submit $SPARK_HOME/bin/spark-submit --master spark://spark1:7077  --packages org.apache.bahir:spark-streaming-twitter_2.11:2.1.0,com.datastax.spark:spark-cassandra-connector_2.11:2.0.3  --class TweatEat $(find target -iname "*.jar")
    /* snip */
    18/07/10 03:06:44 INFO DAGScheduler: ResultStage 5 (count at tweeteat.scala:35) finished in 0.045 s
    18/07/10 03:06:44 INFO DAGScheduler: Job 5 finished: count at tweeteat.scala:35, took 0.056466 s
    A sample of tweets I gathered over 1s: TweetData(1016519047800766465,PetermanAva,Me: I’m gonna get up early this morning and be a good person and meditate!!!
    *alarm goes off at 5am*
    Me: https://t.co/EX9z7ZBQ28) TweetData(1016519047784075265,tbet26,@AirCoopsie Dear me...someone bring in the rain               https://t.co/AOgjkdnjVM) TweetData(1016519051969945601,yuka94vip,こおゆうときにさ、男性スタッフがちゃんと守ってくれるべきじゃないの？
    客にぺこぺこしちゃってさー。
    だっさ。

    間違ってることははっきり言わないと
    つけあがるだけやん。

    だからややこしい客多いねん。) TweetData(1016519051986681861,Mrchmadnes,@ChrisLu44 @Mezzo13531 Obama is intelligent and likes  learning.) TweetData(1016519051994992642,ashslay_haaa,RT @LiveLikeDavis: Hater : Sza hasn’t dropped any new music , you still listen to CRTL ?
    TweetData(1016519051978395654,tay_sagittarius,RT @RockettLynette: A 9-5 was never corny ... being broke is) (total tweets fetched: 41)
    18/07/10 03:06:44 INFO JobScheduler: Finished job streaming job 1531192004000 ms.0 from job set of time 1531192004000 ms


## Part 2: Cassandra Setup

Cassandra is a distributed NoSQL database that runs on Java. It scales well and provides fault tolerance. It's also easy to set up and easy to use with Spark.

### Single-node database setup
Execute the following commands to set up a Cassandra instance.

Write the following content to the file `/etc/yum.repos.d/datastax.repo`:

    [datastax]
    name = DataStax Repo for Apache Cassandra
    baseurl = http://rpm.datastax.com/community
    enabled = 1
    gpgcheck = 0

Now install the Cassandra database:

    yum -y install dsc20

Now start Cassandra:

    systemctl daemon-reload && systemctl start cassandra

You should now be able to access the `cqlsh` shell on your Cassandra instance:

    cqlsh

Use CTRL-D to exit the shell.

Note that if you want to run Cassandra in a non-local (server) mode, you will need to edit /etc/cassandra/cassandra.yaml and specify there the IP address on which Cassandra should be listening (see the rpc_address variable). Unless you also configure Cassandra security, use the internal IP of the Cassandra node.

### Create Cassandra Keyspace, Table

Enter the `cqlsh` shell and execute the following instructions:

    create keyspace streaming  with replication = {'class':'SimpleStrategy', 'replication_factor':1};
    create table streaming.tweetdata (id bigint PRIMARY KEY, author text, tweet text);

## Part 3: Storing Tweet Stream Data in Cassandra

### Edit the Tweet-consuming App

Edit `tweeteat.scala` to write incoming DStream data to your Cassandra test cluster. First, you must set this property on the `SparkConf` object that gets passed to the `StreamingContext` constructor. You can do this by adding this method call to `SparkConf` object (assuming you're connecting to Cassandra locally)
    .set("spark.cassandra.connection.host", "127.0.0.1")

You'll also need to add the following imports:

    import com.datastax.spark.connector.streaming._
    import com.datastax.spark.connector.SomeColumns


Since your new application is going to write streaming data directly to Cassandra, you needn't consume the stream with the `foreachRDD` method. Remove that call.

Please note the previous line, failure to remove the foreachRDD call may lead to errors.

Finally, add a call to the `saveToCassandra` method on your transformed input stream. The line of code should look something like this:

    stream.map(status => TweetData(status.getId, status.getUser.getScreenName, status.getText.trim)).saveToCassandra("streaming", "tweetdata", SomeColumns("id", "author", "tweet"))

There are a few noteworthy elements in this line. First, since we're not going to use the stream in further code, we remove the variable assignment. Second, the `saveToCassandra` call specifies the `keyspace`, `table`, and columns to write to in your Cassandra instance. Cassandra will translate the `TweetData` type (`case class TweetData(id: Long, author: String, tweet: String)`) to those column names. For more information on use of the Cassandra connector, see https://github.com/datastax/spark-cassandra-connector/blob/master/doc/5_saving.md.

### Run the Modified App

Repackage your application and execute it again in Spark. You should notice that the tweet output from the first execution is missing and that log statements in the output report writes to the Cassandra instance.  Note, we have already included the Cassandra packages in both our build.sbt and in our job submission.  Note also that if your Cassandra IP is 127.0.0.1, you need to --master localhost [4] (4 here stands for the number of CPUs in the VM) otherwise other members of the cluster won't be able to connect.

If you get an error similar to 

```
 Core connections for LOCAL hosts must be less than max (2 > 1)
```
you will need to update your `SparkConf` object with the following property, replacing 2 by the max you need:


    .set("spark.cassandra.connection.connections_per_executor_max","2")


### Browse the Data in Cassandra

After you've executed the application in Spark, you can browse stored tweet data. Enter the `cqlsh` shell and execute this query:

    select * from streaming.tweetdata;

You should see output like this:

        id                 | author          | tweet
    --------------------+-----------------+-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
     618865939736600576 |       rndmscene |                                                                                                                         @Veltins_Bier @s04 habe mir alle drei aktuelle bestellt werde mich entscheiden wohl zwischen weiß und schwarz !
     618865952302727168 | carehomeremoval |                                                                                                                              How many followers do you get everyday? I got 1 in the last day. Growing daily with http://t.co/sTW7KQSd8O
     618865956488671232 |      Lou_te_amo |                                                                                            RT @NiallOfficial: That's gotta be the longest day ever ! flight delayed for nearly 5 hours, then the long journey! Damn I'm tired as shitt…
     618865943935098881 |       whogarrix |                                                                                                                                                                               RT @AllyBrooke: I DON'T KNOW ABOUT YOU, BUT I'M FEELIN 22
     618865960708120576 |        aleetiir |                                                                                  شقيق "فتاة ساجر" المنضمة لـ #داعش ": هربت بفعل فاعل \n\nhttp://t.co/Cc7xelXfH4\n\n#السعودية #سوريا #العراق\n#داعش\n#الرياض\n#جدة\n#مكة\n#القطيف\n\n131
     618865939723874304 |       EmilyyOrr |                                                                                                                                                                                       @abrownieG123 @Kiss_MYAsssss it's kind of true!!!

## Further Study

The `spark-cassandra-connector` is highly configurable and includes additional features like reading from an RDD from Cassandra. Investigate the following topics and try to apply them to your application:

- [Saving Data to Cassandra](https://github.com/datastax/spark-cassandra-connector/blob/master/doc/5_saving.md)

- [Server-side data selection, filtering, and grouping in Cassandra](https://github.com/datastax/spark-cassandra-connector/blob/master/doc/3_selection.md)
