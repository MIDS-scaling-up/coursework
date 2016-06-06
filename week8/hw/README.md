Exercise 1 (multiple choice)
============================

Instructions
------------

Classify each of the following NoSQL databases as either (a) key-value store,
(b) column store/column family, (c) document store, (d) graph database, or (e)
other.

* Riak  
* Elasticsearch  
* Hibari  
* Cassandra  
* Voldemort  
* Aerospike  
* Couchbase  
* HBase  
* Cloudant  
* Accumulo  
* LevelDB  
* Amazon SimpleDB  
* Hypertable  
* FlockDB  
* Apache CouchDB  
* Ininite Graph (by Objectivity)  
* RethinkDB  
* DynamoDB  
* MongoDB  
* MemcacheDB  
* MarkLogic Server  
* Neo4J  
* Titan  
* RocksDB  
* Scalaris  
* FoundationDB  
* BerkeleyDB  
* RavenDB  
* Graphbase  
* Redis  
* GenieDB  
* Datomic  
* Azure Table Storage  

#Exercise 2: Quorum and Dynamo Inspired Systems

[Resource] (http://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf)

###Instructions 
1. Name at least three systems that implement quorum protocols. 
1. Define the following: 
  * ‘W’ 
  * ‘R’ 
  * ‘N’ 
  * ‘Q’ 
1. Why is ‘N’ generally chosen to be an odd
integer? 
1. What condition relating ‘W’, ‘R’, and ‘N’ must be satisfied to "yield a quorum like system"? 
1. In the paper "Probabilistically Bounded Staleness,"
Berkeley researchers derive an analytic framework for the probability of reading a "stale" version of an object in a Dynamo-like system that implements quorum.
Using [this tool] (http://pbs.cs.berkeley.edu/\#demo) (lambda=0.1 for all latencies, tolerable staleness=1 version, 15,000 iterations/point), answer the following questions: 

  1. With what probability are you reading "fresh" data for n=3, w=2, r=2? 
  1. Does it depend on time? If so, why? If so, why not? 
  1. Compare the scenarios for (w,r,n) = (2,1,3) and (1,2,3). 
  1. Write down and explain the differences (if any) for the time dependence of P(consistent). 
  1. Is the (2,1,3) state symmetric with (1,2,3)? 
  1. Compare both P(consistent) and the median and 99.9% latencies. 
  1. Provide an intuitive explanation for your results. 
  1. Do either of these states favor consistency or availability? If so, why? 
  1. Perform a similar comparison for the (3,1,3) and (1,3,3) states. Do either of these states favor consistency or availability? If so, why? 
  1. In your opinion, assuming an n=3
system, what do you think is a reasonable choice for write heavy, read heavy, and read\~=write workloads? 

#Exercise 3: Partitioning Strategies 
In the following you will investigate the core differences in partitioning schemes implemented by
various SQL and NoSQL stores. You will make use of this linked [words.txt] (words.txt) file, which contains 235,886 words taken from the OS X 10.9.5 file 
>‘/usr/share/dict/words’ 

**Submit both answers and executable code as referenced
below.**


###Instructions 
**Range Partitioning**  

1. Build a simple Python class or structure that implements a range-partition map. Your map should consist of 26 "shards," where shard\_0 contains words starting with ‘a’, shard\_1 contains words
starting with ‘b’, etc. 

1. Generate a plot or table listing the number of words
stored in each shard. Is the mapping of objects to shards uniform? 

1. Suppose that each shard now lives on a separate database server. Under what workloads (e.g.,
specific queries) would range partitioning be a good/bad choice? 

**Consistent Hashing** 

1. Building on your previous example, implement a hashing approach. Use [this Python file] (http://googleappengine.googlecode.com/svn/trunk/python/google/appengine/api/files/crc32c.py)
as your hash function. 

1. Again, create 26 "shards" but with equidistant boundaries linear on the crc32 interval [0, pow(2,32)], and assign objects to shards based on ‘crc32(word)’. 

1. Generate a plot or table listing the number of words stored in each shard. 

1. Is the mapping of objects to shards uniform? 

1. Suppose that each shard now lives on a separate database server. Under what workloads (e.g., specific queries) would consistent hash partitioning be a good/bad choice? 

1. Suppose that you need to grow your "cluster" by adding 10 additional nodes to the distributed hashing "ring" you built in Exercise 2. By any means you choose, count the total number of objects that would migrate from one shard to a new shard if you were to divide the interval [0,pow(2,32)] into 36 equidistant shards instead of the preexisting 26 shards. 
2. Augment the algorithm to be consistent hashing now.  Instead of equidistant shards, name each node, hash that name and use the number as the shard boundary.  For each node, define a certain number of virtual nodes that represent it on the ring.

1. For a consistent-hashing ring, what is your expectation for the average number of keys that need to be remapped under a table resize if you have ‘K’ keys and ‘n’ shards? How is that value different for standard hash tables? 

1. Name at least one popular NoSQL project that uses range partitioning. 

1. Name at least three popular NoSQL projects that use consistent hashing. 

##Assignment due date: 24 hours before the Week 8 live session. 
**To turn in:** 
 
1. Upload one document with your responses to all four exercises.  
1. Upload your code from Exercise 3

#Further Exploration (Optional)

##Wrangling Relational Data 

In this exercise you will build an interactive application using Cloudant as the data source. Your task is to build a customer-facing dashboard for
business owners to analyze all interactions of Yelp users with their businesses. 

You will simulate user activity (check-ins, tips, reviews) by building a simulator that uploads those types of documents at a predefined rate. Submit a
description of your application, code, and a video of your simulation as it runs. 

You may wish to view the second half of the following two videos for
examples of working with relational, time-series data in Cloudant:

* [Video 1] (https://cloudant.com/handling-relational-data-with-cloudant-webinar-playback/)
* [Video 2] (https://cloudant.com/working-with-time-series-data-in-cloudant/)

###Instructions 
You can choose to build your application as a pure in-browser app (html + js + cloudant), a Mobile app (iOS/Android + Cloudant), or a command-line app (python + Cloudant). You will be using public data from the [Yelp data challenge] (http://www.yelp.com/dataset\_challenge). 

All data are provided with the HW assignment. The full data set is described at the above link. A portion of the data set is already stored in Cloudant for you to replicate into your personal account. This subset contains all business and user documents. 

Details on replication are given in the appendix below. Extend and execute the provided python script to concurrently upload tips, reviews, and check-ins at a rate of \~50 documents per second. This simulates real user activity. 

Your dashboard application should allow businesses to measure their overall activity/ratings/check-ins/tips vs. time. 

It should allow them to identify and target influential users in their vicinity. It should also allow them to understand their performance (user activity, buzz, etc.) compared to other business in their markets. Bonus points for devising a clever heuristic that
combines various estimators (rating, check-ins, tips by influential users, etc.) of overall business performance. 

It is recommended that you create a database
with a small number of documents (10 k each) from each representative type of Yelp document. Use this small database and the Cloudant dashboard to methodically compose and debug the materialized views that drive your application queries.
