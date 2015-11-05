#Orchestrate with Brooklyn
You'll need a VM with 2 CPUs and 4G of RAM to serve as the brooklyn server, e.g. this is how Dima did it.  Note that the key needs to exist in SoftLayer for this to work (p305 in this case)

    slcli vs create --datacenter=sjc01 --domain=dima.com  --hostname=brooklyn --os=UBUNTU_LATEST_64 --key=p305 --cpu=2 --memory=4096 --hourly --wait=64000


In general, a good starting point for Brooklyn is here:
https://brooklyn.incubator.apache.org/v/latest/start/blueprints.html

###Connect to your VM and install the latest brooklyn


    ###Create a key pair on the brooklyn node.
    cd .ssh
    ssh-keygen –t rsa
    # Leave the passphrase blank.

    The public key and private key are saved in ~/.ssh/id_rsa.pub and
    ~/.ssh/id_rsa respectively.

    # Add the public key (in ~/.ssh/id_rsa.pub) to /root/.ssh/authorized_keys on the node.

    # Validate that this works by doing this
    ssh localhost
    # it should be able to log you in without a password.

### Now install Brooklyn

    #Change to your home directory
    cd

    #Download the Brooklyn source code tarball
    wget http://apache.mesi.com.ar/incubator/brooklyn/0.7.0-M2-incubating/apache-brooklyn-0.7.0-M2-incubating.tar.gz

    #unpack the tarball
    tar zxvf apache-brooklyn-0.7.0-M2-incubating.tar.gz

    #chane working directory to the unpacked code
    cd apache-brooklyn-0.7.0-M2-incubating

    #install Maven
    apt-get install maven

    #build brooklyn
    mvn clean install -DskipTests

### Configure SoftLayer Location
Brooklyn uses a properties file (~/.brooklyn/brooklyn.properties) to define things like Cloud Endpoints (SoftLayer in our case) and portal security.

    mkdir /root/.brooklyn
edit /root/.brooklyn/brooklyn.properties  and add the following lines:

    brooklyn.location.jclouds.softlayer.identity=YOUR_SOFTLAYER_USERNAME
    brooklyn.location.jclouds.softlayer.credential=YOUR_SOFTLAYER_API_KEY
    # brooklyn.localhost.private-key-file = path to your private key, set up if using localhost to test
    brooklyn.webconsole.security.https.required=true
    brooklyn.webconsole.security.users=admin

    brooklyn.location.jclouds.softlayer.imageId=UBUNTU_14_64

    # change this password
    brooklyn.webconsole.security.user.admin.password=devcl0ud
    brooklyn.datadir=~/.brooklyn/
    # known good image, available in all regions
    # brooklyn.location.jclouds.softlayer.imageId=13945
    # locations
    brooklyn.location.named.Softlayer\ Seattle=jclouds:softlayer:sea01
    brooklyn.location.named.Softlayer\ Washington=jclouds:softlayer:wdc01
    brooklyn.location.named.Softlayer\ Dallas\ 1=jclouds:softlayer:dal01
    brooklyn.location.named.Softlayer\ Dallas\ 5=jclouds:softlayer:dal05
    brooklyn.location.named.Softlayer\ Dallas\ 6=jclouds:softlayer:dal06
    brooklyn.location.named.Softlayer\ San\ Jose\ 1=jclouds:softlayer:sjc01
    brooklyn.location.named.Softlayer\ Singapore\ 1=jclouds:softlayer:sng01
    brooklyn.location.named.Softlayer\ Amsterdam\ 1=jclouds:softlayer:ams01
    brooklyn.location.named.Softlayer\ London\ 2=jclouds:softlayer:lon02
    brooklyn.location.named.Softlayer\ Hong\ Kong\ 2=jclouds:softlayer:hkg02


Change the permissions on the new properties file

    chmod 600 /root/.brooklyn/brooklyn.properties


###Start it:

    cd /root/apache-brooklyn-0.7.0-M2-incubating/usage/dist/target/brooklyn-dist
    bin/brooklyn launch -b <your external ip>


###Now connect to the web console
Point your browser to https://yourvmip:8081 and log in with the creds you specififed in the brooklyn.properties file

###Deploy a sample blueprint.
Go to the applications tab, click on the + icon, then on the yaml tab and paste the following blueprint:

    name: My Web Cluster

    location: jclouds:softlayer:ams01

    services:

    - type: brooklyn.entity.webapp.ControlledDynamicWebAppCluster
      name: My Web
      brooklyn.config:
        wars.root: http://search.maven.org/remotecontent?filepath=io/brooklyn/example/brooklyn-example-hello-world-sql-webapp/0.6.0/brooklyn-example-hello-world-sql-webapp-0.6.0.war
        java.sysprops:
          brooklyn.example.db.url: >
            $brooklyn:formatString("jdbc:%s%s?user=%s\\&password=%s", component("db").attributeWhenReady("datastore.url"), "visitors", "brooklyn", "br00k11n")

    - type: brooklyn.entity.database.mysql.MySqlNode
      id: db
      name: My DB
      brooklyn.config:
        creationScriptUrl: https://bit.ly/brooklyn-visitors-creation-script

This will take a few minutes to provision.  Once the blueprint is up, you should be able to click on the My Web entity on the left and it'll display URL for the newly provisioned application on the right , e.g.
http://169.53.137.237:8000/

##This homework is not graded. It is complete/incomplete only.
###Submit the URL for your brooklyn admin UI as well as the ID and Password to access it.
