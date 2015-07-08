# Lab: Spark Streaming and Cassandra

## Preconditions

This lab assumes you have a Spark instance set up, that you can use `sbt` to build Scala projects and assemble a jar, and that you have twitter API credentials. If you need to set up a Spark instance (note that it needn't be a cluster, you can use the master only), consult [Apache Spark Introduction](../../../week6/hw/apache_spark_introduction).

If you need to get Twitter API access, create a twitter account and then create an application in [Twitter Application Management](https://apps.twitter.com/). You'll need the following credential values:

    consumerKey
    consumerSecret
    accessToken
    accessTokenSecret

## Build a Twitter Streaming App

Create a project directory (we'll use `/root/tweeteat` in this guide) and write these files:

### `/root/tweeteat/build.sbt`

    lazy val common = Seq(
      organization := "mids",
      version := "0.1.0",
      scalaVersion := "2.11.4",
      libraryDependencies ++= Seq(
        "org.apache.spark" %% "spark-streaming" % "1.3.1" % "provided",
        "org.apache.spark" %% "spark-streaming-twitter" % "1.3.1",
        "com.typesafe.scala-logging" %% "scala-logging" % "3.1.0",
        "com.typesafe" % "config" % "1.3.0"
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

      // batch interval determines how often Spark creates an RDD out of incoming data
      val ssc = new StreamingContext(new SparkConf().setAppName("mids tweeteat"), Seconds(batchInterval_s))

      val stream = TwitterUtils.createStream(ssc, None)

      // extract desired data from each status during sample period, store in new RDD
      val tweetData = stream.map(status => TweetData(status.getUser.getScreenName, status.getText.trim))

      tweetData.foreachRDD(rdd => {
        // data aggregated in the driver
        println(s"A sample of tweets I gathered over ${batchInterval_s}s: ${rdd.take(10).mkString(" ")} (total tweets fetched: ${rdd.count()})")
      })

      // start consuming stream
      ssc.start
      ssc.awaitTerminationOrTimeout(totalRuntime_s * 1000)
      ssc.stop(true, true)

      println(s"============  Exiting ================")
      System.exit(0)
    }

    case class TweetData(author: String, text: String)

**Note:** Ensure that you add your credential strings for the Twitter API to the system properity lines in the scala file above.

### Run the app

Package the tweeteat app into a jar file suitable for execution on Spark (note that this operation will take a little time to complete the first time you run it because it downloads package dependencies; subsequent builds will be faster):

    sbt clean assembly

You should now have a jar file packaged with Scala 2.11 in a subdir of the `target` directory. You can find it from the project directory with this command:

    find . -wholename "*2.11*.jar"

Start the Spark cluster and submit the application for execution:

    $SPARK_HOME/bin/spark-submit --master local[4] $(find . -wholename "*2.11*.jar")

You should see output like this:

    [root@spark1 tweeteat]# $SPARK_HOME/bin/spark-submit --master local[4] $(find . -wholename "*2.11*.jar")
    15/07/08 12:34:10 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
    A sample of tweets I gathered over 1s:  (total tweets fetched: 0)
    15/07/08 12:34:14 WARN BlockManager: Block input-0-1436376853800 replicated to only 0 peer(s) instead of 1 peers
    A sample of tweets I gathered over 1s:  (total tweets fetched: 0)
    15/07/08 12:34:14 WARN BlockManager: Block input-0-1436376854200 replicated to only 0 peer(s) instead of 1 peers
    A sample of tweets I gathered over 1s: TweetData(MadlyMindful,BOOK RECOMMENDATION! 'The Indie Spiritualist' by @XchrisGrossoX http://t.co/EITE7CtkRh http://t.co/3PyoNDbEdh) TweetData(looweetom,this is the best thing in the whOLE INTIRE WORLD https://t.co/FgZyGNGv5u) TweetData(1112_taim,RT @Ttahker: เมื่อน้องหมีอยากคุยกับน้องหมาด้วยภาษาของหมี #อุจุบุ #เอมน้ำ https://t.co/jRS3Av6bdo) TweetData(Rinnzilla,ทางเดียวที่จะผ่านปัญหา/ความเจ็บปวดไปได้ คือมองให้เห็น ให้เข้าใจ.. ไม่ใช่การกระโดดหนีออกจากมัน #ชีวิตคือการเปลี่ยนแปลง #แล้วมันจะผ่านไป แตงโม) TweetData(IbraOfficial_10,Arda Turan, 'Ballboy Barcelona' yang Kini Dilatih Enrique http://t.co/3L3ERZ9YVb) TweetData(JayyBrew,@ticketmaster is a joke!! Was on the site right when tickets went on sale & I missed Packers vs Broncos??!! Some bullshit! 😡) TweetData(JewellDelpin62,Season three premiered on September 10, 2012 and was watched by 12.) TweetData(amir_990,RT @Shmook2282: اللهم ان كثرت ذنوبنا ف اغفرها وان ظهرت عيوبنا ف استرها وان زادت همومنا ف أزلها وإن ضلت أنفسنا طريقها ف ردها إليك رداً جميل…)

## Set up Cassandra
