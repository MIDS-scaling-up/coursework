lazy val common = Seq(
  organization := "week11.mids",
  version := "0.1.0",
  scalaVersion := "2.10.6",
  scalacOptions ++= Seq(
    "-unchecked",
    "-feature"
  ),
  libraryDependencies ++= Seq(
    "org.apache.spark" %% "spark-streaming" % "1.5.0" % "provided",
    "org.apache.spark" %% "spark-streaming-twitter" % "1.5.0"
  ),
  mergeStrategy in assembly <<= (mergeStrategy in assembly) { (old) =>
     {
      case PathList("META-INF", xs @ _*) => MergeStrategy.discard
      case x => MergeStrategy.first
     }
  }
)

lazy val alchemy_tweets = (project in file(".")).
  settings(common: _*).
  settings(
    name := "tweeteat",
    mainClass in (Compile, run) := Some("tweateat.TweetEat"))
