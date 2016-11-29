#Search Lab Instructions


This tutorial describes the installation and use of Nutch 1.x (current release is 1.9).

##Requirements

Provision a VSI:

    slcli vs create --datacenter=sjc01 --domain=data.com  --hostname=nutchtest --os=UBUNTU_LATEST_64 --key="YOUR KEY NAME" --cpu=2 --memory=4096 --billing=hourly --disk=100


##Install Nutch

###Setup Nutch from a binary distribution

* Download a binary package (apache-nutch-1.10-bin.zip) from [here](http://ftp.wayne.edu/apache/nutch/1.12/apache-nutch-1.12-bin.zip).
* Unzip your binary Nutch package. There should be a folder apache-nutch-1.12
* From now on, we are going to use `${NUTCH_RUNTIME_HOME}` to refer to the current directory (apache-nutch-1.10/).

        cd
        wget http://ftp.wayne.edu/apache/nutch/1.12/apache-nutch-1.12-bin.zip
        unzip apache-nutch-1.12-bin.zip
        cd apache-nutch-1.12
        export NUTCH_RUNTIME_HOME=~/apache-nutch-1.12/
        apt update && apt install  openjdk-8-jre


* Setup `JAVA_HOME`

        export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

##Verify your Nutch installation

Run `bin/nutch` - You can confirm a correct installation if you see something similar to the following:

    Usage: nutch COMMAND where command is one of:
    readdb            read / dump crawl db
    mergedb           merge crawldb-s, with optional filtering
    readlinkdb        read / dump link db
    inject            inject new urls into the database
    generate          generate new segments to fetch from crawl db
    freegen           generate new segments to fetch from text files
    fetch             fetch a segment's pages
    ...

Some troubleshooting tips:

* Run the following command if you are seeing "Permission denied":

        chmod +x bin/nutch

Note that the __nutchtest__ above should be replaced with your machine name.

##Crawl your first website

Nutch requires two configuration changes before a website can be crawled:

1. Customize your crawl properties, where at a minimum, you provide a name for your crawler for external servers to recognize
1. Set a seed list of URLs to crawl

###Customize your crawl properties

* Default crawl properties can be viewed and edited within `conf/nutch-default.xml` - where most of these can be used without modification
* The file `conf/nutch-site.xml` serves as a place to add your own custom crawl properties that overwrite `conf/nutch-default.xml`. The only required modification for this file is to override the value field of the `http.agent.name` i.e. add your agent name in the value field of the `http.agent.name` property in `conf/nutch-site.xml`, for example:

        <property>
         <name>http.agent.name</name>
         <value>My Nutch Spider</value>
        </property>

###Create a URL seed list

* A URL seed list includes a list of websites, one-per-line, which nutch will look to crawl
* The file `conf/regex-urlfilter.txt` will provide Regular Expressions that allow Nutch to filter and narrow the types of web resources to crawl and download

###Create a URL seed list

    mkdir -p urls
    cd urls

Create the file `seed.txt` under `urls/` with the following content (one URL per line for each site you want Nutch to crawl).

    http://nutch.apache.org/

Configure Regular Expression Filters

Edit the file `conf/regex-urlfilter.txt` and replace

    # accept anything else
    +.

with a regular expression matching the domain you wish to crawl. For example, if you wished to limit the crawl to the nutch.apache.org domain, the line should read:


    +^http://([a-z0-9]*\.)*nutch.apache.org/

This will include any URL in the domain nutch.apache.org.

__NOTE:__ Leaving only general regex rules in `regex-urlfilter.txt` will cause Nutch to crawl all domains linked to from URLs specified in your seed file.

##Using Individual Commands for Whole-Web Crawling

Whole-web crawling is designed to handle very large crawls which may take weeks to complete, running on multiple machines. This also permits more control over the crawl process, and incremental crawling. It is important to note that whole Web crawling does not necessarily mean crawling the entire World Wide Web. We can limit a whole Web crawl to just a list of the URLs we want to crawl. This is done by using a filter just like the one we used when we did the crawl command (above).

###Step-by-Step: Concepts

Nutch data is composed of:

1. The crawl database, or crawldb. This contains information about every URL known to Nutch, including whether it was fetched, and, if so, when.
1. The link database, or linkdb. This contains the list of known links to each URL, including both the source URL and anchor text of the link.
1. A set of segments. Each segment is a set of URLs that are fetched as a unit. Segments are directories with the following subdirectories:
    * a crawl_generate names a set of URLs to be fetched
    * a crawl_fetch contains the status of fetching each URL
    * a content contains the raw content retrieved from each URL
    * a parse_text contains the parsed text of each URL
    * a parse_data contains outlinks and metadata parsed from each URL
    * a crawl_parse contains the outlink URLs, used to update the crawldb


###Step-by-Step: Seeding the crawldb with a list of URLs

####Bootstrapping from an initial seed list.

We will first create the seedlist in Nutch.


    bin/nutch inject crawl/crawldb urls

###Step-by-Step: Fetching

To fetch, we first generate a fetch list from the database:


    bin/nutch generate crawl/crawldb crawl/segments

This generates a fetch list for all of the pages due to be fetched. The fetch list is placed in a newly created segment directory. The segment directory is named by the time it's created. We save the name of this segment in the shell variable s1:


    s1=`ls -d crawl/segments/2* | tail -1`

    #Verify s1 is properly set
    echo $s1

Now we run the fetcher on this segment with:


    bin/nutch fetch $s1

Then we parse the entries:

    bin/nutch parse $s1

When this is complete, we update the database with the results of the fetch:

    bin/nutch updatedb crawl/crawldb $s1

Now the database contains both updated entries for all initial pages as well as new entries that correspond to newly discovered pages linked from the initial set.

Now we generate and fetch a new segment containing the top-scoring 1,000 pages:


    bin/nutch generate crawl/crawldb crawl/segments -topN 1000
    s2=`ls -d crawl/segments/2* | tail -1`

    #verify s2 is set properly
    echo $s2

    bin/nutch fetch $s2
    bin/nutch parse $s2
    bin/nutch updatedb crawl/crawldb $s2

Let's fetch one more round:


    bin/nutch generate crawl/crawldb crawl/segments -topN 1000
    s3=`ls -d crawl/segments/2* | tail -1`

    #verify s3 is set properly
    echo $s3

    bin/nutch fetch $s3
    bin/nutch parse $s3
    bin/nutch updatedb crawl/crawldb $s3

By this point we've fetched a few thousand pages. Let's invert links and index them!

###Step-by-Step: Invertlinks

Before indexing we first invert all of the links, so that we may index incoming anchor text with the pages.

    bin/nutch invertlinks crawl/linkdb -dir crawl/segments

We are now ready to search with Apache Solr.

### Optional: Using the crawl script

If you have followed the section above on how the crawling can be done step by step, you might be wondering how a bash script can be written to automate all the process described above.

Nutch developers have written one for you :), it's available at `bin/crawl`.


     Usage: crawl [-i|--index] [-D "key=value"] <Seed Dir> <Crawl Dir> <Num Rounds>
        -i|--index      Indexes crawl results into a configured indexer
        -D              A Java property to pass to Nutch calls
        Seed Dir        Directory in which to look for a seeds file
        Crawl Dir       Directory where the crawl/link/segments dirs are saved
        Num Rounds      The number of rounds to run this crawl for
     Example: bin/crawl -i -D solr.server.url=http://localhost:8983/solr/ urls/ TestCrawl/  2

The crawl script has lot of parameters set, and you can modify the parameters to your needs. It would be ideal to understand the parameters before setting up big crawls.

##Setup Solr for search

* Download binary solr 5.5.2 file from [here](http://archive.apache.org/dist/lucene/solr/5.5.2/solr-5.5.2.zip
* unzip to $HOME/apache-solr, we will now refer to this as `${APACHE_SOLR_HOME}`


        cd
        wget http://archive.apache.org/dist/lucene/solr/5.5.2/solr-5.5.2.zip
        unzip solr-5.5.2.zip
        export APACHE_SOLR_HOME=~/solr-5.5.2
        cd ${APACHE_SOLR_HOME}/example
        nohup java -jar start.jar &

##Verify Solr installation

After you started Solr admin console, you should be able to access the following URL (replace YOUR\_IP\_ADDRESS with your IP address):


    http://YOUR_IP_ADDRESS:8983/solr/#/

##Integrate Solr with Nutch

We have both Nutch and Solr installed and setup correctly. And Nutch already created crawl data from the seed URL(s). Below are the steps to delegate searching to Solr for links to be searchable:

* Backup the original Solr example `schema.xml`:

        mv ${APACHE_SOLR_HOME}/example/solr/collection1/conf/schema.xml ${APACHE_SOLR_HOME}/example/solr/collection1/conf/schema.xml.org

* Copy the Nutch specific schema.xml to replace it:

        cp ${NUTCH_RUNTIME_HOME}/conf/schema.xml ${APACHE_SOLR_HOME}/example/solr/collection1/conf/

* Open the Nutch schema.xml file for editing:

        vi ${APACHE_SOLR_HOME}/example/solr/collection1/conf/schema.xml

    * Comment out the following lines 54-55 in the file by changing this:

            <filter class="solr.EnglishPorterFilterFactory"
                    protected="protwords.txt"/>

     to this

             <!--   <filter class="solr.EnglishPorterFilterFactory"
                    protected="protwords.txt"/> -->


        * If you want to see the raw HTML indexed by Solr, change the content field definition (line 102) to true:

            `<field name="content" type="text" stored="true" indexed="true"/>`

    * Add the int and double types right after ` <fieldType name="string"...`:

            <fieldType name="int" class="solr.TrieIntField" precisionStep="0" omitNorms="true" positionIncrementGap="0"/>
            <fieldType name="tdouble" class="solr.TrieDoubleField" precisionStep="8" positionIncrementGap="0"/>

    * Comment out the location lines:

            <!-- <fieldType name="location" class="solr.LatLonType" subFieldSuffix="_coordinate"/> -->

and

            <!-- <copyField source="latLon" dest="location"/> -->


* Save the file and restart Solr under `${APACHE_SOLR_HOME}/example`:

        pkill -f 'java -jar start.jar'; nohup java -jar start.jar &

* run the Solr Index command from `${NUTCH_RUNTIME_HOME}`:

        cd $NUTCH_RUNTIME_HOME
        bin/nutch solrindex http://127.0.0.1:8983/solr/ crawl/crawldb -linkdb crawl/linkdb crawl/segments/*

__Note:__ If you are familiar with past version of the solrindex, the call signature for running it has changed. The linkdb is now optional, so you need to denote it with a "-linkdb" flag on the command line.

This will send all crawl data to Solr for indexing. For more information please see [bin/nutch solrindex](https://wiki.apache.org/nutch/bin/nutch%20solrindex)

If all has gone to plan, you are now ready to search with http://YOUR\_IP\_ADDRESS:8983/solr/#/collection1/query

