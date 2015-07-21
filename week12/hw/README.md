#Configure ELK stack
The ELK stack is ElasticSearch, Logstash and Kibana. Together they provide a fully working real-time data analytics tool. 

You parse your data with Logstash directly into the ElasticSearch node. ElasticSearch will then handle the data, and Kibana will vizualise the data for you.

##Provision your VM

    slcli vs create --datacenter=sjc01 --domain=brad.com  --hostname=elkstack --os=UBUNTU_LATEST_64 --key="YOUR KEY NAME" --cpu=2 --memory=4096 --billing=hourly --disk-100 --wait=64000

##ElasticSearch
ElasticSearch is a search engine with focus on real-time and analysis of the data it holds, and is based on the RESTful architecture. It comes with compatibility with standard full text search functionality, but also with much more powerful query options. ElasticSearch is document-oriented/based and you can store everything you want as JSON. This makes it powerful, simple and flexible.

It is built on top of Apache Lucene, and is by default running on port 9200 +1 per node.

##Download
This URL provides resources to the newest versions: 
http://www.elasticsearch.org/overview/elkdownloads/

Install prerequisites:

    apt-get install -y curl apache2 openjdk-7-jre 

To download the ElasticSearch tar: 

    $ curl -OL https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.tar.gz

To extract the tarball: 

    $ tar xzf elasticsearch-1.1.0.tar.gz 


##Getting started with ElasticSearch

Run the elasticsearch-file inside the ./bin/ folder:

    $ cd elasticsearch-1.1.0
    $ nohup ./bin/elasticsearch &

This will start a master node on port 9200. Go to your public address to see the search engine in action. curl works well:

    $ curl -X GET http://localhost:9200
    {
      "status" : 200,
      "name" : "Master Khan",
      "version" : {
        "number" : "1.1.0",
        "build_hash" : "2181e113dea80b4a9e31e58e9686658a2d46e363",
        "build_timestamp" : "2014-03-25T15:59:51Z",
        "build_snapshot" : false,
        "lucene_version" : "4.7"
      },
      "tagline" : "You Know, for Search"
    }

To insert stuff you can use PUT, as it is a part of the REST architecture.

Then to do a simple search, you can use the "_search" request build into ElasticSearch, like this: 

    $ curl -X GET http://localhost:9200/_search?q=test

To create a record you could run:

    $ curl -X POST 'http://localhost:9200/person/1' -d '{
        "info" : {
            "height" : 2,
            "width" : 20
        }
    }'

Which then will give you a success message in JSON in return if it was created. This can the be retrieved with a search request:

    curl -X GET http://localhost:9200/person/_search

or  

    curl -X GET http://localhost:9200/person/_search?q=2

##Insert some data
Find some documents to download and index.  Select a document repository, preferably something that DOES NOT contain personal information and that you would be fine to see results come up in a search publicly.

Suggestions:

- imdb scripts
- wikipedia dump
- books from gutenberg
- links to all cat photos from geocities

Want to get fancy? Use Nutch to crawl a website.

###Tips for inserting documents

- Use a bash script to get a list of all files, then use curl to insert them (one by one) into ElasticSearch
- [Use stream2es] (https://github.com/elastic/stream2es#wikipedia)
- [Use the bulk insert method of ElasticSearch] (https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
- [Use hadoop to make the process more powerful] (http://thedatachef.blogspot.com/2011/01/bulk-indexing-with-elasticsearch-and.html)
- [Use the Python API] (http://qnundrum.com/question/1388508)
- [Use Nutch to crawl a website] (http://www.aossama.com/search-engine-with-apache-nutch-mongodb-and-elasticsearch/)



##To turn in
Submit the REST URLs for five interesting ElasticSearch queries