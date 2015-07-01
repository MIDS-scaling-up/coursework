# Streaming Tweet Processing

## Spark Streaming Introduction

In addition to providing mechanisms for working with RDDs from static sources like flat files, Apache Spark provides a processing model to work with stream input data. A **DStream** is a Spark abstraction for incoming stream data and can be operated on with many of the functions used to manipulate RDDs. In fact, a DStream object contains a series of data from the input stream split up into RDDs containing some set of data from the stream for a particular duration. A Spark user can register functions to operate on RDDs in the stream as they become available, or on multiple, consecutive RDDs by combining them.

For more information, please consult the [https://spark.apache.org/docs/latest/streaming-programming-guide.html](Spark Streaming Programming Guide).

## Part 1: Set up a 3-node Spark Cluster

Provision 3 VSes to comprise a Spark cluster. You may set up the cluster manually following the instructions from the previous assignment, [../week6/hw/apache_spark_introduction](Apache Spark Introduction).

## Part 2: Build a Twitter popular topic and user reporting system

Design and build a system for collecting data about 'popular' topics and users related to tweets about them. __Popular topics__ for us are determined by the frequency of occurrence of hashtags in tweets. Record popular topics and both the users who author tweets on those topics as well as users who are mentioned by authors considered popular. For example, if averageJoe tweets "#jayZ performing tonight at Madison Square Garden!! @solange" and '#jayZ' is determined to be a popular topic, we care that the users __averageJoe__ and __solange__ are related to a tweet on the topic of '#jayZ'.

The output of your program should be lists of topics that were determined to be popular during the program's execution, as well as lists of people, per-topic, who were related to those topics. Think of this output as useful to marketers who want to target people to sell products to: the ones who surround conversations about particular events, products, and brands are more likely to purchase them than a random user.

Your implementation should continually process incoming Twitter stream data for the duration of at least **30 minutes** and output a summary of data collected. During processing, your program should collect and aggregate tweets over a user-configurable sampling duration up to at least a few minutes. The number of top most popular topics, __n__, to aggregate **at each sampling interval** must be configurable as well. From tweets gathered during sampling periods you should determine:

- The top __n__ most frequently-occurring hash tags among all tweets during the sampling period (tweets containing these tags pick out 'popular' topics)
- The account names of users who authored tweets on popular topics in the period
- The account names of users who were mentioned in popular tweets *or* by popular people

### Grading and Submission

This is a graded assignment. Please submit credentials to access your cluster and execute the program. The output can be formatted as you see fit, but must contain lists of popular topics and related people. You must identify __authors__ of topics (the trendsetters!) and people merely mentioned in tweets about them.

When submitting credentials to your Spark system, please provide a short description of a particularly interesting decision or two you made about the processing interval, features about collection, or other features of your collection system that make for particularly useful output data.
