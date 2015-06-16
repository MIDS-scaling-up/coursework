from pyspark.mllib.regression import LabeledPoint
from pyspark.mllib.feature import HashingTF
from pyspark.mllib.classification import LogisticRegressionWithSGD
from pyspark import SparkContext
import os
import pickle


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


def main():
	"""
	Driver program for a spam filter using Spark and MLLib
	"""

	# Consolidate the individual email files into a single spam file
	# and a single ham file
	makeDataFileFromEmails( "data/spam_2/", "data/spam.txt")
	makeDataFileFromEmails( "data/easy_ham_2/", "data/ham.txt" )

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
	print( "*********** SPAM FILTER RESULTS **********" )
	print( "\n" )
	print( "Error Rate: " + str( error_rate ) )
	print( "\n" )

	# Serialize the model for presistance
	pickle.dump( model, open( "spamFilter.pkl", "wb" ) )

	sc.stop()

if __name__ == "__main__":
	main()

