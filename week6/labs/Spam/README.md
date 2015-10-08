# Machine Learning with Spark and MLLib

## Overview

In most big data analytics processes we develop a model to do the analysis as a separate step before using the model in an in-production application.  There are four steps to develop the model:

1. Data preprocessing
2. Learning algorithm training
3. Learning algorithm testing
4. Model persistence

In this lab we will see a simple version of each of these steps executed in Spark.

The main advantage of using Spark's **_MLLib package_** is that it's machine learning algorithms are all **_parallelized already_**.  You do not have to write map and reduce functions to make them work in parallel.

## Preconditions

You must have a Spark cluster setup including the MLLib library (see [Apache Spark Introduction](../../hw/apache_spark_introduction) if you need to set up a Spark cluster).  You will also need Python 2.7 with Numpy 1.7 on each machine.  You will need Git on the master. It is assumed that you have had prior exposure to machine learning algorithms (this lab will not cover the details of how these algorithms work).

To install Numpy and Git use yum:

	$ yum install -y numpy

On the master only:

	$ yum install -y git

You will then need to clone the course GitHub repo:

	$ git clone https://github.com/MIDS-scaling-up/coursework.git

After cloning you need to copy the data directory, hamster.py, and spamFilter.py to the root directory

	$ cp -r coursework/week6/labs/Spam/data ~/
	$ cp coursework/week6/labs/Spam/*.py ~/

## Scenario: Spam Filter

You have been given a dump of emails (actual emails, this is not dummy data) which you will use to create a spam filter.  Each email is a separate plain text file.  The emails are divided into a set of spam and a set of non-spam (called ham).  You will use these files to generate the training and testing data sets.

The spam data are available here https://spamassassin.apache.org/publiccorpus/20050311_spam_2.tar.bz2

The ham data are available here https://spamassassin.apache.org/publiccorpus/20030228_easy_ham_2.tar.bz2

**EXERCISE:** Run the spamFilter.py script available in the GitHub project.  You should see an error rate for the spam filter in the output.

First run hamster.py and then copy the data to the worker nodes.  This needs to be done because we do not have a distributed file system or a database setup:

	$ python hamster.py
	$ scp -r data/ root@spark2:/root
	$ scp -r data/ root@spark3:/root

To run Python scripts in Spark use:

	$SPARK_HOME/bin/spark-submit --master spark://spark1:7077 spamFilter.py

Now lets walk through the code in spamFilter.py and see what its doing.

## Part 1: The Spark Context

This driver program has your program's main method and is executed on the Spark Master.  The **_SparkContext_** is the object representing the driver program's connection to the rest of the cluster.  In our applications we will need to create a Spark Context like this:

	from pyspark import SparkContext

	sc = SparkContext( appName="Spam Filter")

There are several optional arguments that can be given to the constructor of the Spark Context.  There are also several helper methods that can be called on the Spark Context.  Read about them [here](https://spark.apache.org/docs/1.0.2/api/python/pyspark.context.SparkContext-class.html) in the pyspark reference.


## Part 2: Data Preprocessing

The training and test data need to be in a format that can be easily used to generate feature vectors for training the learning algorithm.

### Consolidating Emails to a Single Data Source ([Data Munging](http://en.wikipedia.org/wiki/Data_wrangling))

The textFile method will make an RDD from a text file.  It will by default treat each line of the text file as one data point.  So we need to transform each email such that it will appear as a single line of text (no returns / line feeds) and combine all the emails of a given class (spam or ham) into a single input file for that class.  Since we will use this process twice we will define it as a separate function and run it in a separate script, as we did above (hamster.py).

	def makeDataFileFromEmails( dir_path, out_file_path ):
		"""
		Iterate over files converting them to a single line
		then write the set of files to a single output file
		"""

		with open( out_file_path, 'w' ) as out_file:

			# Iterate over the files in directory 'path'
			for file_name in os.listdir( dir_path ):

				# Open each file for reading
				with open( dir_path + file_name ) as in_file:

					# Reformat emails as a single line of text
					text = in_file.read().replace( '\n',' ' ).replace( '\r', ' ' )
					text = text + "\n"
					# Write each email out to a single file
					out_file.write( text )

With larger data sets we would want to load the data into a database and then have Spark interact with the database.  SparkSQL is a good way to interact with databases in Spark, which you can read about [here](https://spark.apache.org/docs/1.1.0/sql-programming-guide.html#other-sql-interfaces).  NoSQL databases can be interfaced with through configuration of the RDD using the conf property.  [Here](https://github.com/apache/spark/blob/master/examples/src/main/python/cassandra_inputformat.py) is an example.

### Loading Data in Spark

Now that we have the emails consolidated to two single data sources (spam and ham),
we can load the data into Spark RDDs.    Once our data is in an RDD we can work on it.

The simplest way to create an RDD is by loading data in from a text file:

	# Read the spam data file created above into an RDD
	spam = sc.textFile( "spam.txt" )

	# Read the ham data file created above into an RDD
	ham = sc.textFile( "ham.txt" )

If you wished to create an RDD per-file from a collection of files on disk, you would use this function:

	myRDD = sc.wholeTextFiles( some_directory )
[wholeTextFiles reference](https://spark.apache.org/docs/1.0.2/api/python/pyspark.context.SparkContext-class.html#wholeTextFiles)

It's also possible to create RDDs out of in-RAM data structures. For this purpose, use:

	myRDD = sc.parallelize( some_data_structure )
[parallelize reference](https://spark.apache.org/docs/1.0.2/api/python/pyspark.context.SparkContext-class.html#parallelize)

**Be careful** as you change how you load the data into an RDD it may also require changes to how you process the RDD later.

### Feature Generation Techniques in MLLib

Now that our raw data is in an RDD we must generate features from the data to use for the learning algorithm.  In this case the raw data is not easily broken into features.  The simplest thing to do is vectorize the text using an MLLib class specifically for this, [HashingTF](https://spark.apache.org/docs/1.2.0/api/scala/index.html#org.apache.spark.mllib.feature.HashingTF).

	# Create a HashingTF instance to map email text to vectors of 10,000 features.
	tf = HashingTF(numFeatures = 10000)

	# Each email is split into words, and each word is mapped to one feature.
	spamFeatures = spam.map(lambda email: tf.transform(email.split(" ")))
	hamFeatures = ham.map(lambda email: tf.transform(email.split(" ")))

**EXERCISE:** There are more sophisticated ways that we could generate features from the unstructured data.  One of the most common is the [TF-IDF](http://en.wikipedia.org/wiki/Tf%E2%80%93idf) algorithm.  Use the Spark MLLib [documentation](https://spark.apache.org/docs/latest/mllib-feature-extraction.html) to see how to implement TF-IDF and try it in our application.

Note:  there are several other feature extraction, selection, and generation techniques available in MLLib, you should familiarize yourself with all of them.

### Labeling Data Points

We now need to pair our data points with labels (spam or ham) encoded at 1 for spam and 0 for ham.  MLLib provides a class [LabeledPoint](https://spark.apache.org/docs/1.2.0/api/scala/index.html#org.apache.spark.mllib.regression.LabeledPoint) that we can use to do this.  We then construct a new RDD of labeled points from the spam and ham RDDs we created above.

	# Create LabeledPoint datasets for positive (spam) and negative (ham) data points.
	positiveExamples = spamFeatures.map(lambda features: LabeledPoint(1, features))
	negativeExamples = hamFeatures.map(lambda features: LabeledPoint(0, features))

### Build Training and Testing Datasets

Now that our data points are labeled we can combine the spam and ham datasets so that we can then re-split them into training and testing datasets that contain both types.  Spark provide a [randomSplit](https://spark.apache.org/docs/latest/api/python/pyspark.html?highlight=randomsplit#pyspark.RDD.randomSplit) function to split datasets into randomly selected groups of the original RDDs.

	# Combine positive and negative datasets into one RDD
	data = positiveExamples.union(negativeExamples)

	# Split the data into two RDDs. 70% for training and 30% test data sets
	( trainingData, testData ) = data.randomSplit( [0.7, 0.3] )

## Part 3: Training the Learning Algorithm

From a programming perspective this is the simplest step.  However, in data mining one of the most difficult issues is picking a good learning algorithm for the problem you are trying to solve.  Here we use logistic regression.

	# Train the model with the SGD Logistic Regression algorithm.
	model = LogisticRegressionWithSGD.train(trainingData)

## Part 4: Testing the Learning Algorithm

Now we test the model first by making a new RDD of tuples containing the actual label and the predicted label.  Remember that testData is an RDD of LabeledPoint objects, we can use a lambda function to create these tuples by extracting the label for each email and then the then using the model to predict on the features extracted from the labeled point.  The RDDs map function applies this lambda function to each element on the testData RDD.

	labels_and_predictions = testData.map( lambda email: (email.label, model.predict( email.features) ) )

Next we need to count up the number of times the model made an incorrect prediction and divide it by the total number of test data points.  We use the RDD's filter transformation to select only the elements where the actual value does not eqaul the predicted value and the count() action to sum up those occurrences.  Then use the count action to sum up the total number of test data point.

	error_rate = labels_and_predictions.filter( lambda (val, pred): val != pred ).count() / float(testData.count() )

	print( "Error Rate: " + str( error_rate ) )

There are additional metrics available in MLLib if you are using Scala or Java, [work is being done](https://github.com/apache/spark/blob/master/python/pyspark/mllib/evaluation.py) to make these metrics available in PySpark as well.

**EXERCISE:** There are other learning algorithms provided by MLLib that we could use.  Look through the MLLib documentation for support vector machines (SVMs) [here](http://spark.apache.org/docs/1.0.1/api/python/pyspark.mllib.classification.SVMWithSGD-class.html) and change the code to use an SVM instead of logistic regression.  Compare the error rates of the two different algorithms.

## Part 5: Model Persistence

Now that we have trained a model with an acceptable error rate, we need to save the model for use in a production system.  The simplest thing to do is serialize the model object using Python's pickle module.

	# Serialize the model for presistance
	pickle.dump( model, open( "spamFilter.pkl", "wb" ))

Some [work has been done](https://issues.apache.org/jira/browse/SPARK-1406) to add support in MLLib for [PMML](http://en.wikipedia.org/wiki/Predictive_Model_Markup_Language), which is a serialization format specifically for statistical and machine learning models.

## Addendum: Original Code

Note the import statements at the beginning and the call to stop on the SparkContext object at the end.

	from pyspark.mllib.regression import LabeledPoint
	from pyspark.mllib.feature import HashingTF
	from pyspark.mllib.classification import LogisticRegressionWithSGD
	from pyspark import SparkContext
	import os
	import pickle


	def main():
		"""
		Driver program for a spam filter using Spark and MLLib
		"""

		# Create the Spark Context for parallel processing
		sc = SparkContext( appName="Spam Filter")

		# Load the spam and ham data files into RDDs
		spam = sc.textFile( "data/spam.txt" )
		ham = sc.textFile( "data/ham.txt" )

		# Create a HashingTF instance to map email text to vectors of 10,000 features.
		tf = HashingTF(numFeatures = 10000)

		# Each email is split into words, and each word is mapped to one feature.
		spamFeatures = spam.map(lambda email: tf.transform(email.split(" ")))
		hamFeatures = ham.map(lambda email: tf.transform(email.split(" ")))

		# Create LabeledPoint datasets for positive (spam) and negative (ham) data points.
		positiveExamples = spamFeatures.map(lambda features: LabeledPoint(1, features))
		negativeExamples = hamFeatures.map(lambda features: LabeledPoint(0, features))

		# Combine positive and negative datasets into one
		data = positiveExamples.union(negativeExamples)

		# Split the data into 70% for training and 30% test data sets
		( trainingData, testData ) = data.randomSplit( [0.7, 0.3] )

		# Cache the training data to optmize the Logistic Regression
		trainingData.cache()

		# Train the model with Logistic Regression using the SGD algorithm.
		model = LogisticRegressionWithSGD.train(trainingData)

		# Create tuples of actual and predicted values
		labels_and_predictions = testData.map( lambda email: (email.label, model.predict( email.features) ) )

		# Calculate the error rate as number wrong / total number
		error_rate = labels_and_predictions.filter( lambda (val, pred): val != pred ).count() / float(testData.count() )

		# End the Spark Context
		sc.stop()

		# Print out the error rate
		print( "*********** SPAM FILTER RESULTS **********" )
		print( "\n" )
		print( "Error Rate: " + str( error_rate ) )
		print( "\n" )

		# Serialize the model for presistance
		pickle.dump( model, open( "spamFilter.pkl", "wb" ) )

	if __name__ == "__main__":
		main()

