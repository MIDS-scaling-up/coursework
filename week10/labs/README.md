#Lab 1 --  fun with policies... 
### Deploy this into your brooklyn:
In your brooklyn UI, navigate to Applications and click the plus sign next to the word "Applications" on the upper left side of the screen. Then select the YAML tab on the resulting screen.

Copy and paste this definition into the text entry area.

```
name: appserver-w-policy
location: jclouds:softlayer:tor01
services:
- type: org.apache.brooklyn.entity.webapp.ControlledDynamicWebAppCluster
  initialSize: 1
  memberSpec:
    $brooklyn:entitySpec:
      type: org.apache.brooklyn.entity.webapp.jboss.JBoss7Server
      brooklyn.config:
        wars.root: http://search.maven.org/remotecontent?filepath=io/brooklyn/example/brooklyn-example-hello-world-sql-webapp/0.6.0/brooklyn-example-hello-world-sql-webapp-0.6.0.war
        http.port: 8080+
        java.sysprops: 
          brooklyn.example.db.url: $brooklyn:formatString("jdbc:%s%s?user=%s\\&password=%s",
              component("db").attributeWhenReady("datastore.url"), "visitors", "brooklyn", "br00k11n")
  brooklyn.policies:
  - policyType: org.apache.brooklyn.policy.autoscaling.AutoScalerPolicy
    brooklyn.config:
      metric: $brooklyn:sensor("org.apache.brooklyn.entity.webapp.DynamicWebAppCluster", "webapp.reqs.perSec.windowed.perNode")
      metricLowerBound: 10
      metricUpperBound: 100
      minPoolSize: 1
      maxPoolSize: 5
- type: org.apache.brooklyn.entity.database.mysql.MySqlNode
  id: db
  name: DB HelloWorld Visitors
  brooklyn.config:
    datastore.creation.script.url: https://raw.githubusercontent.com/apache/brooklyn-library/02abbab09ab514524bb9a9edbd0a525447d15c99/examples/simple-web-cluster/src/main/resources/visitors-creation-script.sql
```

* Wait for this blueprint to come up  
* Click on the Controlled Dynamic Web AppCluster, Effectors tab  
* Invoke the resize policy and use a value of two  
* Observe reprovisioning
* After a couple minutes with no traffic, the pool will automatically resize to 1



#Lab 2:
We'll deploy and play around with an elastic Spark cluster.
https://github.com/brooklyncentral/brooklyn-spark

This assumes that you've done the homework first...

* On your brooklyn VM....  
* ensure that ~/.brooklyn/brooklyn.properties is set up as described in the homework


### Add Spark to the Catalog

From the Brooklyn UI, go to the Catalog tab and click the plus sign next to the word Catalog on the upper left portion of the page. Select YAML, then copy and paste the [catalog.bom] (https://github.com/brooklyncentral/brooklyn-spark/blob/master/catalog.bom) to the text edit field. Submit the form.

Select the Applications tab and click the plus sign next to the word Applications on the upper left side of the page. Select "Spark Cluster" from the catalog and click "Next". Select the location and name the cluster, then click "Finish".

Go to the applications tab and observe your Spark provisioning in real time.
Once its up , click on the master node and Summary tab and click the link to connect to the Spark UI (it will look like http://MASTER\_NODE\_IP:8080).

Ssh to the master node (you can see the ssh address from the Brooklyn UI at Applications -> Your Application -> Master Node -> Sensors -> host.sshAddress and use the ssh key you identified in your brooklyn properties file). Then cd to the spark directory:

    cd brooklyn-managed-processes/apps/yQiuvpwb/entities/VanillaSoftwareProcess_iEf3l3J0/spark-1.6.0-bin-hadoop2.6/
   

**Note that yQiuvpwb and VanillaSoftwareProcess_iEf3l3J0 are dynamically generated and will be different on your install.**

From this directory, run the following command (make sure you use the public IP of your master node):

    MASTER=spark://MASTER_NODE_IP:7077 ./bin/run-example SparkPi 100

**Note that MASTER\_NODE\_IP:7077 is found on the Spark UI in the first line. It is most likely the private (10.) IP address.**

You can monitor progress in the Spark UI and on the command line.

##To clear out your servers, select the application and click "Stop" on the Effectors tab. This will break down the app and cancel all servers in SoftLayer
