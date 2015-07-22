# Elasticsearch
Elasticsearch is a scalable, full-text search engine with real-time analytics and search features. It provides a RESTful API for indexing and querying. It's document-oriented/based and can store documents as JSON. This makes it powerful, simple and flexible.

It is built on top of Apache Lucene; by default, ituses port `9200` `+1` per node.

## Provision your VM

    slcli vs create --datacenter=sjc01 --domain=brad.com --hostname=elasticsearch --os=CENTOS_LATEST_64 --key=IBM_local-2 --cpu=2 --memory=4096 --billing=hourly --disk=100 --key=<your key name>

## Download
https://www.elastic.co/downloads/elasticsearch

Install prerequisites:

    yum install -y epel-release && yum install -y java-1.8.0-openjdk-headless net-tools jq

Set the proper location of `JAVA_HOME` and test it:

    echo export JAVA_HOME=\"$(readlink -f $(which java) | grep -oP '.*(?=/bin)')\" >> /root/.bash_profile
    source /root/.bash_profile
    $JAVA_HOME/bin/java -version

Download the Elasticsearch tarball (from https://www.elastic.co/downloads/elasticsearch):

    curl -OL https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.0.tar.gz

To extract the tarball:

    tar xzf elasticsearch-1.7.0.tar.gz

## Getting started with Elasticsearch

Run the elasticsearch-file inside the ./bin/ folder:

    cd elasticsearch-1.7.0
    nohup ./bin/elasticsearch &

This will start a master node on port `9200`. You can check that the service is listening with the command `netstat -tnlp`. If you need to investigate a problem, check the output written to the file `nohup.out`. Browse to your public address to see the search engine in action. `curl` works as well:

    curl -X GET http://localhost:9200

You should see output like this:

    {
      "status" : 200,
      "name" : "Polaris",
      "cluster_name" : "elasticsearch",
      "version" : {
        "number" : "1.7.0",
        "build_hash" : "929b9739cae115e73c346cb5f9a6f24ba735a743",
        "build_timestamp" : "2015-07-16T14:31:07Z",
        "build_snapshot" : false,
        "lucene_version" : "4.10.4"
      },
      "tagline" : "You Know, for Search"
    }

Then to do a simple search, you can use the "_search" request built into ElasticSearch, like this:

    curl -X GET http://localhost:9200/_search?q=test

For prettier output, run the `curl` command and pipe the output to `jq`:

    curl -X GET http://localhost:9200/_search?q=test | jq -r '.'

Note the total number of documents matching the query (hits -> total) in the response. For more information on the format of the response, see https://www.elastic.co/guide/en/elasticsearch/reference/current/_the_search_api.html.

To index new documents you can use the HTTP POST method. For more information on indexing records with the API, consult https://www.elastic.co/guide/en/elasticsearch/reference/current/.

Try inserting a new document this way:

    curl -X POST 'http://localhost:9200/artist/bieber' -d '{
            "talent" : 5,
            "best_song.release_year": 2010,
            "best_song.title": "Eenie Meenie"
    }'

... and then a few more:

    curl -X POST 'http://localhost:9200/artist/plant' -d '{
            "talent": 90,
            "best_song.release_year": 1970,
            "best_song.title": "Bron-Y-Aur Stomp"
    }'

...

    curl -X POST 'http://localhost:9200/artist/bluhm' -d '{
            "talent": 91,
            "best_song.release_year": 2013,
            "best_song.title": "Little too Late"
    }'

Elasticsearch will respond with a success message in JSON if the document was indexed. Documents can be retrieved withsearch requests:

    curl -X GET http://localhost:9200/artist/_search

You can also specify a query and output options:

    curl -X GET 'http://localhost:9200/artist/_search?q=talent:\[90+TO+100\]&pretty'

Note how queries issued without specified field names are handled:

    curl -X GET 'http://localhost:9200/artist/_search?q=Stomp&pretty'

## Index Interesting Data
Elasticsearch is good at indexing large volumes of similarly-formatted text documents and providing an easy query mechanism for humans to retrieve them. Your task is to index a collection of documents. The source of the data and indexing tools you use are up to you. Try to select a data set that is not too small and that produces interesting search results. Finally, **be careful not to index sensitive data!!** Your search engine will be public so make sure the data you make available through it can be published.

If you're having trouble selecting a dataset, consider these:

- IMDB movie scripts
- A Wikipedia dump
- Books from Project Gutenberg

### Tips for Inserting Documents

- Use a Bash script to get a list of all files, then use `curl` to insert them (one by one) into Elasticsearch
- [Use stream2es] (https://github.com/elastic/stream2es#wikipedia)
- [Use the bulk insert method of Elasticsearch] (https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
- [Use Hadoop] (http://thedatachef.blogspot.com/2011/01/bulk-indexing-with-elasticsearch-and.html)
- [Use the Python API] (http://qnundrum.com/question/1388508)
- [Use Nutch to crawl a website] (http://www.aossama.com/search-engine-with-apache-nutch-mongodb-and-elasticsearch/)

### Going the Distance
Want to get fancy? Deploy a graphical frontend for easier interaction with your instance: https://github.com/jettro/elasticsearch-gui.

## To Turn In
Submit the REST URLs for **five** interesting queries we can execute on your Elasticsearch instance.
