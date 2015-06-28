# Object Storage

## Part 0 - Prerequisites

To make sure you have the required software before beginning you can use the 'which' tool- it just searches the system PATH and returns the first executable(s) it finds:

	which curl jq tee

_jq_ and _curl_ should have been installed in previous assignments, and _tee_ comes on all but very minimal distributions. If you don't have something you might need then instead of paths for each of these you will see a message like:

	which: no curl in (/usr/bin:/bin:/usr/sbin:/sbin:/opt/java/bin)
    /usr/bin/jq
    /usr/bin/tee

### Troubleshooting Requests/Orders

We'll pipe all of our requests through _tee_ to save the raw output in case we need to examine it:

	curl -s https://api.softlayer.com/... | tee softlayer.$(date +%s).log | jq .id

If this request went well we will just get the record we selected with _jq_. If not we will get some sort of error and we'll probably want to see what the server sent back. We may not want to re-send the request to find out, so _tee_ in this pipeline will write files named in the form softlayer.NNNNNNNNNN.log to your current directory.  You can then inspect the output and if it's JSON you can format it for reading with _jq_:

    cat softlayer.1431254320.log
	jq . softlayer.1431254320.log

## Part 1 - Required Reading

Read the following article and become better acquainted with the Swift architecture:

https://www.swiftstack.com/openstack-swift/architecture/

Please read the whole article.

We will also refer to this tutorial on ordering and using object storage:

http://sldn.softlayer.com/blog/waelriac/Managing-SoftLayer-Object-Storage-Through-REST-APIs

## Part 2 - Order Object Storage

First you can check if you have already ordered object storage for a previous assignment, and if so retrieve the username(s):

    curl --user USERID:API_KEY https://api.softlayer.com/rest/v3.1/SoftLayer_Account/getHubNetworkStorage | tee softlayer.$(date +%s).log | jq '.[] | select(.vendorName == "Swift") | del (.properties)'  

You will see output similar to the following if you have:

    {
      "accountId": 111111,
      "capacityGb": 5000,
      "createDate": "2013-09-01T09:42:52-06:00",
      "guestId": null,
      "hardwareId": null,
      "hostId": null,
      "id": 2222222,
      "nasType": "HUB",
      "serviceProviderId": 1,
      "upgradableFlag": true,
      "username": "USERNAME-1",
      "serviceResourceBackendIpAddress": "https://dal05.objectstorage.service.networklayer.com/auth/v1.0/",
      "serviceResourceName": "OBJECT_STORAGE_DAL05",
      "vendorName": "Swift"
    }

If there is no output then you should continue to __Instructions__ and order object storage, otherwise you can skip it.

### Instructions

Here is an article on how to create and cancel a storage account and tie it to your SoftLayer account: 

http://sldn.softlayer.com/blog/waelriac/Managing-SoftLayer-Object-Storage-Through-REST-APIs

The first three sections of the article are about listing, creating, and canceling storage accounts. Storage accounts have to be created in SL portal or via SL API.

Please note that the value of ID field in JSON for creating accounts depends on type and geography of SL account. The author mentioned the user should use [https://USERID:API\_KEY@api.softlayer.com/rest/v3.1/SoftLayer\_Product\_Package/0/getItems]() to get the price item id for OBJECT_STORAGE_PAY_AS_YOU_GO item.  For example:
    
	curl -s --user USERID:API_KEY https://api.softlayer.com/rest/v3.1/SoftLayer_Product_Package/0/getItems | tee softlayer.$(date +%s).log | jq '.[] | select(.keyName == "OBJECT_STORAGE_PAY_AS_YOU_GO") | .prices[0].id'

An example for ordering would be the following command, where NNNNN is the object storage:

    curl --user USERID:API_KEY https://api.softlayer.com/rest/v3.1/SoftLayer_Product_Order/placeOrder -X POST -d '{"parameters" : [{"complexType": "SoftLayer_Container_Product_Order_Network_Storage_Hub", "quantity": 1, "packageId": 0, "prices": [{ "id": NNNNN}]}]}' | tee softlayer.$(date +%s).log | jq '{"orderId": .orderId, "status": .placedOrder.status, "location": .orderDetails.locationObject.name}'

When the order is complete you will see a storage account when we re-visit this API call:

    curl --user USERID:API_KEY https://api.softlayer.com/rest/v3.1/SoftLayer_Account/getHubNetworkStorage | tee softlayer.$(date +%s).log | jq '.[] | select(.vendorName == "Swift") | del (.properties)'  

The name of the created accounts are of the form SLUSER-IDNUM, for example "SL000000-1".

## Part 3 - Using Object Storage

The rest of the article (http://sldn.softlayer.com/blog/waelriac/Managing-SoftLayer-Object-Storage-Through-REST-APIs) covers the REST API for managing object storage: creating/listing/deleting containers, directories, and files.

You do not need to use the SLAPI to manage object storage accounts, You could use a generic swift client instead, e.g., to list containers in the account in the particular datacenter using the openstack swift utility:

	pip install python-swiftclient  
	swift -A https://SL_DATA_CENTER_ID.objectstorage.softlayer.net/auth/v1.0/ -U ACCOUNT-ID:USERID -K API_KEY list  

Where the SL_DATA_CENTER_ID is something like dal05 or sjc01, as returned in the call to getHubNetworkStorage, ACCOUNT-ID is the storage account you retrieved above and USERID is your portal username.  For example if the datacenter is sjc01, your storage username is SL000000-1 and you log into the portal with just SL000000 your command line would look similar to the following:

	swift -A https://sjc01.objectstorage.softlayer.net/auth/v1.0/ -U SL000000-1:SL000000 -K 000000111111abcdef... list  

### Examples

Here are some code examples—links to SoftLayer object storage clients in git repositories:

 * Python: https://github.com/softlayer/softlayer-object-storage-python  
 * PHP: https://github.com/softlayer/softlayer-object-storage-php  
 * Java: https://github.com/softlayer/softlayer-object-storage-java  
 * Ruby: https://github.com/softlayer/softlayer-object-storage-ruby  

## Part 4 - Assignment

After setting up your storage account, proceed to upload data using at least two of the methods we've discussed (a language specific tool listed above and a command line client, for example). The data can be anything; however, the data should be at least 1 GB in size. You may wish to look ahead into other homeworks - for example the Web Search in LMS - to decide on data you wish to upload.

After uploading the data (create), list the data, and delete an object.

Using time() or other measurement methods, run a series of uploads/downloads of your test data, and report on the upload/download average speed in Mb/sec. I suggest writing a simple script to accomplish this task, since you will need to do a number of variations of this below. Provide a copy of the script or command used to accomplish this.

__Assignment due date__: 24 hours before the Week 7 live session  
__To turn in__: Submit a link to your uploaded object in the assignment page https://learn.datascience.berkeley.edu/mod/assignment/view.php?id=5750 and include your answers to the following questions:  

 * What is the average READ speed in Mb/sec?  
 * What is the average WRITE speed in Mb/sec?  
 * Can you account for the discrepancies? Consider all of the possible reasons and explain.  
 * What happens to these speeds if you run two threads in parallel?  

__Grade__: Credit/No Credit  
