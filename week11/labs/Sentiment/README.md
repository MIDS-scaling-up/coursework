# Sentiment Analysis in Spark with AlchemyAPI

## Overview

One of the most common tasks for analytics is working with unstructured data like human written text.  In particular for streaming analytics a very common task is sentiment analysis.  In this lab we will see how to use **_AlchemyAPI_** in Scala to do basic entity extraction and sentiment analysis.  There are two core motivations for this lab:

1. Seeing AlchemyAPI in action
2. Seeing how to use AlchemyAPI in Scala

The reason for the second motivation is there is no library support for AlchemyAPI in Scala at this time, which makes things a little more complicated.


## Preconditions

You must have a Spark standalone machine setup including the MLLib library.  You will need Git on the master to pull down the source code for this lab.  

On the master only:

	$ yum install git
	
You will then need to clone the course GitHub repo:

	$ git clone https://github.com/MIDS-scaling-up/coursework.git
	
You will also need Twitter access as per the lab on [Spark Streaming](https://github.com/MIDS-scaling-up/coursework/tree/master/week9/labs/streaming_and_cassandra).  You will need an AlchemyAPI key (which you were asked to do before this lab started, but if you have not do it now at [http://www.alchemyapi.com/api/register.html](http://www.alchemyapi.com/api/register.html) ).
	

## Scenario: Sentiment Analysis

You have access to a Twitter data feed and your goal is to find out what things being talked about on Twitter are most well "liked". To do this you will need to extract the entities being discussed in each tweet and then get the sentiment associated with each entity.  Once you have this data you will need to aggregate it so that it shows entities over some time window ranked by average sentiment.

## RESTful API's

If you are already familiar with RESTful API's move to the next section.  A RESTful API is one where instead of making function calls to a library imported to your code, you use [HTTP verbs](http://www.restapitutorial.com/lessons/httpmethods.html) (POST, GET, PUT, DELETE) and specially crafted URL strings which act as nouns.  The basic idea is HTTP verb + resource URL noun = action on that resource.  The result of the action is then sent back as the HTTP response.  

In this lab we will use the GET request and a URL like http://access.alchemyapi.com/calls/text/TextGetRankedNamedEntities, where TextGetRankedNamedEntities is the actual API call and the body of a tweet is URL encoded and appended to it to ask AlchemyAPI to provide sentiment analysis on that tweet.  The response will be the output of the AlchemyAPI call.


## Part 1: AlchemyAPI

[AlchemyAPI](http://www.alchemyapi.com/) is a web-based service providing text and image analysis tools to any application with an internet connection and the ability to make HTTP requests.  There are many features available in the [API](http://www.alchemyapi.com/api), but for simplicity we will only look at two of the most popular for text analysis--[entity extraction](http://www.alchemyapi.com/api/entity-extraction) and [sentiment analysis](http://www.alchemyapi.com/api/sentiment-analysis).

For simplicity we will use the HTTP GET request to make calls to AlchemyAPI.  We have provided a simple function that does this for you.


## Part 2: Code Overview 

### Setup the Spark Streaming Context and Twitter Feed
We will use Spark Streaming and the Twitter streaming source to get our tweets.  For simplicity we will put the keys and secrets as hard coded values, but a more robust solution is to have these stored in a file that is read at run time.

	  val batchInterval_s = 1
	  val totalRuntime_s = 32
	  
	  val propPrefix = "twitter4j.oauth."
	  System.setProperty(s"${propPrefix}consumerKey", "x3jzYlQAzgOXzGIuJX4VvzeSw")
	  System.setProperty(s"${propPrefix}consumerSecret", "uYTH4OzbElgbDK81gERvdvIezuCefhcmyFFWyFihL41u3TDWwq")
	  System.setProperty(s"${propPrefix}accessToken", "467827626-BbJ9VrNyKT7rMY8iRYaAluirOorNNiX1wc9jHoKk")
	  System.setProperty(s"${propPrefix}accessTokenSecret", "CwTR8LIxqhtikpqdzaMx3JpNPF6L1nY9EIrBr9Dn6UKZc")
	  
	  // create SparkConf
	  val conf = new SparkConf().setAppName("mids tweeteat")
	  
	  // Create a streaming context
	  val ssc = new StreamingContext(conf, Seconds(batchInterval_s))
	  
	  // Open the Twitter stream
	  val stream = TwitterUtils.createStream(ssc, None)
	  
	  // Pull the tweet bodies into a Dstream
	  val rawTweets = stream.map(status => status.getText())
	  

### Process the tweets

To process the data in a DStream we will need to iterate over each RDD in the DStream.  Furthermore we will need to iterate over the tweets contained in the RDDs.  

		// Iterate over the RDDs in the DStream
		rawTweets.foreachRDD(rdd => {
		// data aggregated in the driver
    
    		println(" ")

			// Iterate over the tweets in the RDDs
			for(tweet <- rdd.collect().toArray) {
					// Code to process tweets goes here
			}

     		println(" ")

  		})					

A more robust solution here would be to store the tweets into a database like you did in the last lab, but for simplicity we will do all of the processing without using a database.


### AlchemyAPI Calls

As mentioned we will need to make an HTTP request to access AlchemyAPI.  While AlchemyAPI provides libraries to make this easy for several languages (Python, PHP, Ruby, Node.js, Java, C/C++, and others), there is not at this time a library for Scala.  

Because of this we will need a simple function to make an HTTP request formatted for AlchemyAPI.  We will use the Scala standard library's Source to make the actual HTTP request and we will use Java's URLEncoder class to encode the text of the tweet.

	 	def getAlchemyResults( tweet:String, call:String ): String = {
	 	
	 		// URL for AlchemyAPI
    		val alchemyurl = "http://access.alchemyapi.com/calls/text/"
    		
    		// Takes the alchemyurl and appends the specific call
    		val baseurl = alchemyurl + call
    		
    		// AlchemyAPI key
    		val apikey = "3c4420d68ce67f391180ebf15658b09864ec606a"
    		
    		// URL encode the tweet body 
    		val tweetEncoded = URLEncoder.encode( tweet, "UTF-8" )
    		
    		// Build the final URL string
    		val url2 = baseurl +"?apikey=" + apikey + "&text=" + tweetEncoded + "&showSourceText=1";
    		
    		// Make the HTTP request
    		val result2 = scala.io.Source.fromURL(url2).mkString

    		return result2

  		}


**EXERCISE:**
Look throught the AlchemyAPI API for the endpoints (the URLs) for calling entitiy extraction and sentiment analysis.  Make note of those URL's, you will need to pass them as arguments to the getAlchemyResults function.  

While you are looking through the AlchemyAPI API, look for other calls that might help us produce the results we want better.  Remember what we are interested in finding out is what things are people talking about on Twitter in the most favorable way.

### Processing the HTTP Request Results

The results of the AlchemyAPI call will be returned as XML in this case, but can be set to respond in other formats like JSON.

In order to aggregate our data we will need to parse the XML in some fashion.  For simplicity we will just use a couple of hand written functions that extract exactly what we need, but a more robust solution is the create an [XML parser in Scala](http://www.scala-lang.org/api/2.10.3/index.html#scala.xml.parsing.ConstructingParser)

		def parseAlchemyResponseEntity(alchemyResponse:String,typeResponse:String) : Array[String] = {
      
			var entitiesText = ""
			if ((alchemyResponse contains "<entities>") && (alchemyResponse contains "<entity>")){
				val entitiesBegin = alchemyResponse indexOf "<entities>"
				val entitiesEnd = alchemyResponse indexOf "</entities>"
				entitiesText = alchemyResponse.substring(entitiesBegin + "<entities>".length,entitiesEnd)
			}
			else
			{
				return new Array[String](0)
			}
      
      		val numEntities = "<entity>".r.findAllIn(entitiesText).length
      		var entityTextArray = new Array[String](numEntities)
      
      		var i = 0
      		for (i <- 0 to numEntities-1)
      		{
        		println(i)
        		println(entitiesText)
        		val tempEntityText = parseAlchemyResponseIndividual(entitiesText,typeResponse)
        		entityTextArray(i) = tempEntityText
        		val endOfCurrentEntity = entitiesText indexOf "</entity>"
        		entitiesText = entitiesText.substring(endOfCurrentEntity+"</entity>".length)
      		}

      		return entityTextArray
    	}

		def parseAlchemyResponseIndividual(alchemyResponse:String,typeResponse:String) : String = {
     
			if(alchemyResponse contains "<" + typeResponse + ">"){
			
				val scoreBegin = alchemyResponse indexOf "<" + typeResponse + ">"
				val scoreEnd = alchemyResponse indexOf "</" + typeResponse + ">"
				val isolatedString = alchemyResponse.substring(scoreBegin + typeResponse.length+2,scoreEnd)
				return isolatedString
     		}
    		else
    			return "None"
   		}
## Part 3: Aggregating the Results

Now that we have a stream of Twitter data we can send it to AlchemyAPI for entity extraction and sentiment analysis, we need to aggregate the results.  The final product we want is a list of the entities in order of those with the highest positive sentiment.  


**EXERCISE:** 
There are at least two ways this could be done.  We can work completely on the driver side and aggregate the results using plain old Scala, or we can find a way to construct a new DStream from the parsed data returned from AlchemyAPI.  Think about how we can use map, filter, and other transformations to get this done.  For today's lab you may find it easier to do this in plain old Scala, but you will want to think about how to get this done taking full advantage of Spark.  We provide a simple map data structure entityMap and the stub of a function aggregateWrapper to do this in plain old Scala.  Implement this function to aggregate the results.  

When you have this working, try modifying the code to use one of the other AlchemyAPI calls.  Think about things like grabbing hash tags, extracting keywords, and so on.  

## Addendum: Original Code

		import org.apache.spark.streaming.Seconds
		import org.apache.spark.streaming.StreamingContext
		import org.apache.spark.streaming.twitter.TwitterUtils
		import org.apache.spark.SparkConf
		import scala.collection.mutable.ArrayBuffer
		import java.net.HttpURLConnection
		import java.net.URL
		import java.net.URLEncoder

		/**
		 * @author anewman@us.ibm and jpredman@us.ibm
		 */
		 
		object TweetEat extends App {
		
			def getAlchemyResults( tweet:String, call:String ): String = {
    			//insert apikey here
    			val apikey = " "
    
    			val alchemyurl = "http://access.alchemyapi.com/calls/text/"
    			val baseurl = alchemyurl + call
    			val tweetEncoded = URLEncoder.encode( tweet, "UTF-8" )
    			val url2 = baseurl +"?apikey=" + apikey + "&text=" + tweetEncoded + "&showSourceText=1";
    			val result2 = scala.io.Source.fromURL(url2).mkString

    			return result2
    		}
    		
    		
    		//xml parser
    		def parseAlchemyResponseEntity(alchemyResponse:String,typeResponse:String) : Array[String] = {
    		
    			var entitiesText = ""
      			if ((alchemyResponse contains "<entities>") && (alchemyResponse contains "<entity>")){
        			val entitiesBegin = alchemyResponse indexOf "<entities>"
        			val entitiesEnd = alchemyResponse indexOf "</entities>"
        			entitiesText = alchemyResponse.substring(entitiesBegin + "<entities>".length,entitiesEnd)
      			}
      			else
      			{
        			return new Array[String](0)
      			}
      
      			val numEntities = "<entity>".r.findAllIn(entitiesText).length
      			var entityTextArray = new Array[String](numEntities)
      
      			var i = 0
      			for (i <- 0 to numEntities-1)
      			{
        			println(i)
        			println(entitiesText)
        			val tempEntityText = parseAlchemyResponseIndividual(entitiesText,typeResponse)
        			entityTextArray(i) = tempEntityText
        			val endOfCurrentEntity = entitiesText indexOf "</entity>"
        			entitiesText = entitiesText.substring(endOfCurrentEntity+"</entity>".length)
      			}

      			return entityTextArray
    		}
    		
    		
    		def parseAlchemyResponseIndividual(alchemyResponse:String,typeResponse:String) : String = {
     
     			if(alchemyResponse contains "<" + typeResponse + ">"){
       			val scoreBegin = alchemyResponse indexOf "<" + typeResponse + ">"
       			val scoreEnd = alchemyResponse indexOf "</" + typeResponse + ">"
       			val isolatedString = alchemyResponse.substring(scoreBegin + typeResponse.length+2,scoreEnd)
       			return isolatedString
     			}
     			else {
     				return "None"
     			}
     		}
     		
     		var entityMap = collection.mutable.Map[String, collection.mutable.Map[String,Double]]()
     		
     		//handle aggregation
     		//{ <entity> : { numObservations: <Double>, scoreTotal: <Double>, average:<Double>} }
     		def aggregateWrapper(entityArray:Array[String],sentimentScore:String) = 
     		{
     			//todo
     		}
     		
     		val batchInterval_s = 1
  			val totalRuntime_s = 32

  			val propPrefix = "twitter4j.oauth."
  			System.setProperty(s"${propPrefix}consumerKey", "x3jzYlQAzgOXzGIuJX4VvzeSw")
  			System.setProperty(s"${propPrefix}consumerSecret", "uYTH4OzbElgbDK81gERvdvIezuCefhcmyFFWyFihL41u3TDWwq")
  			System.setProperty(s"${propPrefix}accessToken", "467827626-BbJ9VrNyKT7rMY8iRYaAluirOorNNiX1wc9jHoKk")
  			System.setProperty(s"${propPrefix}accessTokenSecret", "CwTR8LIxqhtikpqdzaMx3JpNPF6L1nY9EIrBr9Dn6UKZc")

  			// create SparkConf
  			val conf = new SparkConf().setAppName("mids tweeteat")

  			// Create the StreamingContext and open the Twitter stream
  			val ssc = new StreamingContext(conf, Seconds(batchInterval_s))
  			val stream = TwitterUtils.createStream(ssc, None)

  			// Extract body of each tweet	
  			val rawTweets = stream.map(status => status.getText())

  			rawTweets.foreachRDD(rdd => {
  			
    			// data aggregated in the driver
    			println(" ")

    			for(tweet <- rdd.collect().toArray) {

        			val alchemyResponseSentiment = getAlchemyResults(tweet, "TextGetTextSentiment" ) 
        			val alchemyResponseEntity = getAlchemyResults(tweet, "TextGetRankedNamedEntities" )  
        			println( " " )
        			println(tweet);
        			println( " " )
        			println( alchemyResponseSentiment )
        			println( alchemyResponseEntity )
        			println( " " )
        
        			val sentimentScore = parseAlchemyResponseIndividual(alchemyResponseSentiment,"score")
        			val sentimentType = parseAlchemyResponseIndividual(alchemyResponseSentiment,"type")
        			val language = parseAlchemyResponseIndividual(alchemyResponseSentiment,"language")
        			val entities = parseAlchemyResponseEntity(alchemyResponseEntity,"text")
        
        			println("sentiment type: " + sentimentType)
        			println("sentiment score: " + sentimentScore) 
        			println("language: " + language)
        			println("entities: " + entities.mkString(", "))
        
        			aggregateWrapper(entities,sentimentScore)
        
        			entityMap.keys.foreach{ i =>  
        				print( "Key = " + i )
        				println(" Value = " + entityMap(i) )}
    				}

    				println(" ")
    			})
    		// start consuming stream
    		ssc.start
    		ssc.awaitTerminationOrTimeout(totalRuntime_s * 1000)
    		ssc.stop(true, true)
    	
    		println(s"============ Exiting ================")
    		System.exit(0)
    	}




