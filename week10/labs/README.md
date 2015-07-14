#Lab 1 --  fun with policies... 
### Deploy this into your brooklyn:
    name: appserver-w-policy-all
    location: jclouds:softlayer:ams01


    services:
    - type: brooklyn.entity.webapp.ControlledDynamicWebAppCluster
      initialSize: 1
      memberSpec:
        $brooklyn:entitySpec:
          type: brooklyn.entity.webapp.jboss.JBoss7Server
          brooklyn.config:
            wars.root: http://search.maven.org/remotecontent?filepath=io/brooklyn/example/brooklyn-example-hello-world-sql-webapp/0.6.0/brooklyn-example-hello-world-sql-webapp-0.6.0.war
            http.port: 8080+
            java.sysprops: 
              brooklyn.example.db.url: $brooklyn:formatString("jdbc:%s%s?user=%s\\&password=%s",
                  component("db").attributeWhenReady("datastore.url"), "visitors", "brooklyn", "br00k11n")
      brooklyn.enrichers:
      - type: brooklyn.policy.ha.ServiceFailureDetector
      brooklyn.policies:
      - type: brooklyn.policy.ha.ServiceReplacer
        brooklyn.config:
          failureSensorToMonitor: $brooklyn:sensor("brooklyn.policy.ha.HASensors", "ha.entityFailed")  
      - policyType: brooklyn.policy.autoscaling.AutoScalerPolicy
        brooklyn.config:
          metric: $brooklyn:sensor("brooklyn.entity.webapp.DynamicWebAppCluster", "webapp.reqs.perSec.windowed.perNode")
          metricLowerBound: 10
          metricUpperBound: 100
          minPoolSize: 1
          maxPoolSize: 5
    - type: brooklyn.entity.database.mysql.MySqlNode
      id: db
      name: DB HelloWorld Visitors
      brooklyn.config:
        datastore.creation.script.url: https://github.com/brooklyncentral/brooklyn/raw/master/usage/launcher/src/test/resources/visitors-creation-script.sql

* Wait for this blueprint to come up  
* Click on the Controlled Dynamic Web AppCluster, policies tab  
* The autoscaler policy - minpool size -- change to two  
* Observe reprosinioning



#Lab 2:
We'll deploy and play around with an elastic Spark cluster.
https://github.com/brooklyncentral/brooklyn-spark

This assumes that you've done the homework first...

* On your brooklyn VM....  
* ensure that ~/.brooklyn/brooklyn.properties is set up as described in the homework


### Configure the VM
    #Install the JDK
    apt-get install -y default-jdk git

    # pull the spark blueprint code bundled with a release of brooklyn
    cd
    git clone https://github.com/brooklyncentral/brooklyn-spark.git
    cd brooklyn-spark

###Configure pom.xml; add the following to it just before \</project\>

    
    <repositories>
        <!-- enable snapshots from sonatype -->
        <repository>
          <id>sonatype-nexus-snapshots</id>
          <name>Sonatype Nexus Snapshots</name>
          <url>https://oss.sonatype.org/content/repositories/snapshots</url>
          <releases>
            <enabled>false</enabled>
          </releases>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
        <!-- enable snapshots from apache -->
        <repository>
          <id>apache-nexus-snapshots</id>
          <name>Apache Nexus Snapshots</name>
          <url>https://repository.apache.org/content/repositories/snapshots</url>
          <releases>
            <enabled>false</enabled>
          </releases>
          <snapshots>
            <enabled>true</enabled>
          </snapshots>
        </repository>
      </repositories>

###Run a build

    # build
    mvn clean install -DskipTests

### After it cleanly builds...


    cd target/brooklyn-spark-dist/brooklyn-spark 
    ./start.sh launch -l jclouds:softlayer:ams01 --spark
 
###This will start brooklyn on https://youripaddress:8443/

e.g.
https://198.11.207.91:8443

Go to the applications tab and observe your Spark provisioning in real time.
Once its up , click on the master node and sensor tab and get its ip address.  Connect to the Spark UI like this
http://masternodeip:8080

