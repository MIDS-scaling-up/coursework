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

    lazy val common = Seq(
      organization := "mids",
      version := "0.1.0",
      scalaVersion := "2.10.5",
      libraryDependencies ++= Seq(
        "org.apache.spark" %% "spark-streaming" % "1.3.1" % "provided",
        "org.apache.spark" %% "spark-streaming-twitter" % "1.3.1",
        "com.datastax.spark" %% "spark-cassandra-connector" % "1.3.0-M2"
      ),
      mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
         {
          case PathList("META-INF", xs @ _*) => MergeStrategy.discard
          case x => MergeStrategy.first
         }
      }
    )

    lazy val tweeteat = (project in file(".")).
      settings(common: _*).
      settings(
        name := "tweeteat",
        mainClass in (Compile, run) := Some("TweetEat"))

**Note:** The library dependencies for Spark listed in this file need to have versions that match the version of Spark you're running on your server. Change the version numbers here if necessary.

### `/root/tweeteat/project/plugins.sbt`

    addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.13.0")

### `/root/tweeteat/tweeteat.scala`

    import org.apache.spark.streaming.Seconds
    import org.apache.spark.streaming.StreamingContext
    import org.apache.spark.streaming.twitter.TwitterUtils
    import org.apache.spark.SparkConf

    /**
     * @author mdye
     */
    object TweetEat extends App {
      val batchInterval_s = 1
      val totalRuntime_s = 32

      val propPrefix = "twitter4j.oauth."
      System.setProperty(s"${propPrefix}consumerKey", "")
      System.setProperty(s"${propPrefix}consumerSecret", "")
      System.setProperty(s"${propPrefix}accessToken", "")
      System.setProperty(s"${propPrefix}accessTokenSecret", "")

      // create SparkConf
      val conf = new SparkConf().setAppName("mids tweeteat")

      // batch interval determines how often Spark creates an RDD out of incoming data
      val ssc = new StreamingContext(conf, Seconds(batchInterval_s))

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

    sbt clean assembly

You should now have a jar file packaged with Scala 2.10 in a subdir of the `target` directory. You can find it from the project directory with this command:

    find . -wholename "*2.10*.jar"

Start the Spark cluster and submit the application for execution:

    $SPARK_HOME/bin/spark-submit --master local[4] $(find . -wholename "*2.10*.jar")

You should see output like this:

    [root@spark1 tweeteat]# $SPARK_HOME/bin/spark-submit --master local[4] $(find . -wholename "*2.10*.jar")
    15/07/08 12:34:10 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    A sample of tweets I gathered over 1s:  (total tweets fetched: 0)
    15/07/08 12:34:14 WARN BlockManager: Block input-0-1436376853800 replicated to only 0 peer(s) instead of 1 peers
    A sample of tweets I gathered over 1s:  (total tweets fetched: 0)
    15/07/08 12:34:14 WARN BlockManager: Block input-0-1436376854200 replicated to only 0 peer(s) instead of 1 peers
    A sample of tweets I gathered over 1s: TweetData(MadlyMindful,BOOK RECOMMENDATION! 'The Indie Spiritualist' by @XchrisGrossoX http://t.co/EITE7CtkRh http://t.co/3PyoNDbEdh) TweetData(looweetom,this is the best thing in the whOLE INTIRE WORLD https://t.co/FgZyGNGv5u) TweetData(1112_taim,RT @Ttahker: เมื่อน้องหมีอยากคุยกับน้องหมาด้วยภาษาของหมี #อุจุบุ #เอมน้ำ https://t.co/jRS3Av6bdo) TweetData(Rinnzilla,ทางเดียวที่จะผ่านปัญหา/ความเจ็บปวดไปได้ คือมองให้เห็น ให้เข้าใจ.. ไม่ใช่การกระโดดหนีออกจากมัน #ชีวิตคือการเปลี่ยนแปลง #แล้วมันจะผ่านไป แตงโม) TweetData(IbraOfficial_10,Arda Turan, 'Ballboy Barcelona' yang Kini Dilatih Enrique http://t.co/3L3ERZ9YVb) TweetData(JayyBrew,@ticketmaster is a joke!! Was on the site right when tickets went on sale & I missed Packers vs Broncos??!! Some bullshit! 😡) TweetData(JewellDelpin62,Season three premiered on September 10, 2012 and was watched by 12.) TweetData(amir_990,RT @Shmook2282: اللهم ان كثرت ذنوبنا ف اغفرها وان ظهرت عيوبنا ف استرها وان زادت همومنا ف أزلها وإن ضلت أنفسنا طريقها ف ردها إليك رداً جميل…)

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

    yum -y install dsc20

Now start Cassandra:

    systemctl start cassandra

You should now be able to access the `cqlsh` shell on your Cassandra instance:

    cqlsh

Use CTRL-D to exit the shell.

### Create Cassandra Keyspace, Table

Enter the `cqlsh` shell and execute the following instructions:

    create keyspace streaming  with replication = {'class':'SimpleStrategy', 'replication_factor':1};
    create table streaming.tweetdata (id bigint PRIMARY KEY, author text, tweet text);

## Part 3: Storing Tweet Stream Data in Cassandra

### Edit the Tweet-consuming App

Edit `tweeteat.scala` to write incoming DStream data to your Cassandra test cluster. First, you must set this property on the `SparkConf` object that gets passed to the `StreamingContext` constructor. You can do this by adding this method call to `SparkConf` object:

    .set("spark.cassandra.connection.host", "127.0.0.1")

You'll also need to add the following imports:

    import com.datastax.spark.connector.streaming._
    import com.datastax.spark.connector.SomeColumns

Since your new application is going to write streaming data directly to Cassandra, you needn't consume the stream with the `foreachRDD` method. Remove that call.

Finally, add a call to the `saveToCassandra` method on your transformed input stream. The line of code should look something like this:

    stream.map(status => TweetData(status.getId, status.getUser.getScreenName, status.getText.trim)).saveToCassandra("streaming", "tweetdata", SomeColumns("id", "author", "tweet"))

There are a few noteworthy elements in this line. First, since we're not going to use the stream in further code, we remove the variable assignment. Second, the `saveToCassandra` call specifies the `keyspace`, `table`, and columns to write to in your Cassandra instance. Cassandra will translate the `TweetData` type (`case class TweetData(id: Long, author: String, tweet: String)`) to those column names. For more information on use of the Cassandra connector, see https://github.com/datastax/spark-cassandra-connector/blob/master/doc/5_saving.md.

### Run the Modified App

Repackage your application and execute it again in Spark. You should notice that the tweet output from the first execution is missing and that log statements in the output report writes to the Cassandra instance.

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
