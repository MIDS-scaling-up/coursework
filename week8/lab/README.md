##Preparation
* Make sure that you have signed up for a free Cloudant account and able to log into it. 
* Make sure that you have a JSON plugin added to your browser so that you can see JSON documents, pretty printed.  For instance, if you are using Chrome, you can install JSONView
* Make sure that you have a shell -- either locally on your laptop or via a VM in the Cloud that has curl working on it.
* Ensure that you can use this command line curl to connect to your cloundant account, e.g.

`curl -X GET -H 'Content-Type: application/json' https://userid:pass@userid.cloudant.com`


##Basic lab
We'll follow the cloudant session below using our browser.  The sections below contain interactive elements.  They could be followed directly by clicking interactive "Show me!" buttons.  however, please paste the URLs into your browser to ensure that they work.  Also, use your command line curl to execute them.  Note that before these examples start to work, you'll need to replicate the sample databases into your environment.  This is part of the instructions.  Make sure you don't miss those!

[Main Lab Page] (https://cloudant.com/for-developers/)

Part 1: [Reading and writing] (https://cloudant.com/for-developers/crud/)

Part 2: [Primary Index] (https://cloudant.com/for-developers/all_docs/)

Part 3: [Secondary Indexes] (https://cloudant.com/for-developers/views/)

Part 4: [Search Indexing and Query] (https://cloudant.com/for-developers/search/)

##Advanced lab (see the optional part of the homework)
* [Download the Yelp dataset] (http://www.yelp.com/dataset_challenge)
* Uncompress it.  
* Create a new database in Cloudant, bulk upload a subset of the data (e.g. 50,000 lines) to that database.
* Make sure that you can see the uploaded documents both in the web GUI and via curl.  
* Create an index / view allowing you to query for businesses by name and by longitude / latitude
* Create a secondary index allowing you to list all users who reviewed a particular business.

To create a database "yelp" in Cloudant, you'd do something like:

`curl -v -i -X PUT -H 'Content-Type: application/json' https://userid:passwrd@user.cloudant.com/yelp`

To cut out 50000 lines from an input file, you do:  
`head -50000 yelp_academic_dataset_business.json > business.json`

This file is not yet in the json format that the bulk upload can accept -- we need to add in the beginning:

`{"docs": [`

and in the end:

`]}`

Or you can use the attached [converter.py] (converter.py) script.


`cat business.json | ./converter.py > business.json`

To bulk upload the properly formed business.json file, we do something like:

`curl -v -i -X POST -H 'Content-Type: application/json' -d @business.json https://userid:passwrd@userid.cloudant.com/databasename/_bulk_docs`

Now check that your documents made it over:

`curl -v -i -X GET -H 'Content-Type: application/json' https://userid:passwrd@userid.cloudant.com/yelp`

Here's the design doc that we'd need to create in order to be able to retrieve businesses by business id along with their reviews. This should be done via the GUI.

Under indices:

    function(doc) {  
	    var key= null;  
	    var value = null;  
	    if (doc.type==="business") {  
	    	key = [doc.business_id];  
	    	value = null;  
	    	emit(key, value);  
	    } else if (doc.type==="review") { 
	    	key = [doc.business_id,doc.review_id ];  
	    	value = {"_id":doc._id};  
		emit(key, value); 
	    }  
    }  


Under views:

    function(doc){
     if(doc.type==="business") {
    	index("default", doc._id);
    	if(doc.name){
    		index("name", doc.name, {"store": "yes"});
    	}
    	if(doc.business_id){
    		index("business_id", doc.business_id, {"store": "yes"});
    	}					
    	if (doc.latitude){
    		index("lat", doc.latitude, {"store": "yes"});
    	}
	    if (doc.longitude){
	    	index("lon", doc.longitude, {"store": "yes"});
	    }
     }
    }

And:

    function(doc){
    	if(doc.type==="review") {
    		index("default", doc._id);
    		if(doc.review_id){
    			index("review_id", doc.review_id, {"store": "yes"});
    		}
    		if(doc.business_id){
		    	index("business_id", doc.business_id, {"store": "yes"});
    	    }					
	    	if (doc.text){
	    		index("text", doc.text, {"store": "yes"});
	    	}
	    }
    }



Now you should be able to query the businesses, e.g.


`curl -v -i -X GET -H 'Content-Type: application/json' https://username:pass@username.cloudant.com/yelp/_design/thursday/_search/businesses?q=name:Eric`


Get one of the keys ... this is the business id -- e.g. fgjPheORTQCwwPOWiUE2SQ

To retrieve all of its reviews, you would do:

`curl -X GET "https://username:pass@username.cloudant.com/yelp/_design/thursday/_view/reviews?include_docs=true&limit=10&startkey=\[\"fgjPheORTQCwwPOWiUE2SQ\"\]&endkey=\[\"fgjPheORTQCwwPOWiUE2SQ\",\{\}\]&inclusiveend=true"`




