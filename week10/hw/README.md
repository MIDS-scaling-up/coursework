#Orchestrate with Brooklyn
You'll need a VM with 2 CPUs and 4G of RAM to serve as the brooklyn server, e.g. this is how Dima did it.  Note that the key needs to exist in SoftLayer for this to work (YOUR_KEY in this case)

    slcli vs create --datacenter=sjc01 --domain=dima.com  --hostname=brooklyn --os=UBUNTU_LATEST_64 --key=YOUR_KEY --cpu=2 --memory=4096 --billing=hourly --wait=64000


In general, a good starting point for Brooklyn is here:
https://brooklyn.incubator.apache.org/v/latest/start/blueprints.html

###Connect to your VM and install the latest brooklyn


    # Install Java
    apt-get install openjdk-7-jre-headless

    #Add a new user and change to that user
    adduser brooklyn
    su - brooklyn
    
    ###Create a key pair on the brooklyn node.
    ssh-keygen
    
    # Leave the passphrase blank.
    # The public key and private key are saved in ~/.ssh/id_rsa.pub 
    # and ~/.ssh/id_rsa respectively.

    # Add the public key (in ~/.ssh/id_rsa.pub) to /root/.ssh/authorized_keys on the node.
    
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys

    # Validate that this works by doing this ssh
    # it should be able to log you in without a password.
    ssh localhost

    
    
### Now install Brooklyn

    #Change to your home directory
    cd

    #Download the Brooklyn source code tarball
    wget "https://repository.apache.org/service/local/artifact/maven/redirect?r=snapshots&g=org.apache.brooklyn&a=brooklyn-dist&v=0.9.0-SNAPSHOT&c=dist&e=tar.gz"
    
    mv redirect\?r\=snapshots\&g\=org.apache.brooklyn\&a\=brooklyn-dist\&v\=0.9.0-SNAPSHOT\&c\=dist\&e\=tar.gz brooklyn-dist-0.9.0.tar.gz

    #unpack the tarball
    tar zxf brooklyn-dist-0.9.0.tar.gz

    #change working directory to the unpacked code
    cd brooklyn-dist-0.9.0-SNAPSHOT

    
### Configure SoftLayer Location
Brooklyn uses a properties file (~/.brooklyn/brooklyn.properties) to define things like Cloud Endpoints (SoftLayer in our case) and portal security.

    mkdir ~/.brooklyn
edit ~/.brooklyn/brooklyn.properties  and add the following lines:

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
    # ssh private key
    brooklyn.location.jclouds.privateKeyFile=~/.ssh/id_rsa
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
    brooklyn.location.jclouds.privateKeyFile=~/.ssh/id_rsa



Change the permissions on the new properties file

    chmod 600 /root/.brooklyn/brooklyn.properties


###Start it:

    cd ~/cd brooklyn-dist-0.9.0-SNAPSHOT/
    bin/brooklyn launch -b <your external ip>


###Now connect to the web console
Point your browser to https://your_vm_ip:8443 and log in with the creds you specififed in the brooklyn.properties file (default is admin/devcl0ud).

###Deploy a sample blueprint.
The UI will show a deployment window. Click on the YAML tab, then paste the following blueprint:

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
