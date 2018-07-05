# THIS HOMEWORK IS OPTIONAL
# THE hw-nn HOMEWORK IS THE OFFICIAL WEEK 10 HOMEWORK

# Orchestrate with Brooklyn
You'll need a VM with 2 CPUs and 4G of RAM to serve as the brooklyn server, e.g. this is how Dima did it.  Note that the key needs to exist in SoftLayer for this to work (YOUR_KEY in this case)

    slcli vs create --datacenter=sjc01 --domain=dima.com  --hostname=brooklyn --os=UBUNTU_LATEST_64 --key=YOUR_KEY --cpu=2 --memory=4096 --billing=hourly --wait=64000


In general, a good starting point for Brooklyn is here:
https://brooklyn.incubator.apache.org/v/latest/start/blueprints.html

### Connect to your VM and install the latest brooklyn


    # Install Java
    apt-get update
    apt-get install openjdk-8-jre-headless

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
    wget "http://mirror.reverse.net/pub/apache/brooklyn/apache-brooklyn-0.12.0/apache-brooklyn-0.12.0-bin.tar.gz"

    #unpack the tarball
    tar zxf apache-brooklyn-0.12.0-bin.tar.gz

    #change working directory to the unpacked code
    cd  apache-brooklyn-0.12.0-bin


### Start it:

    cd ~/apache-brooklyn-0.12.0-bin
    ./bin/start


### Now connect to the web console
Point your browser to http://your_vm_ip:8081 and log in with the default creds (default is admin/password).

### Create a location
In the GUI, click the `add location` button. 
This can also be found on the Catalog tab by pressing the `+` sign and selecting `Location`.

Select `Cloud` and click the `Next` button. 

 * For Location ID, use `sl-dal10`
 * For Location Name, use `Dallas 10`
 * Cloud Provider is `SoftLayer`
 * Cloud Region is `dal10`
 * Use your API ID and Key for the credential fields

### Deploy a sample blueprint.
The UI will show a deployment window. Click on the YAML Composer button, then click the Catalog button (at the top) and paste the following blueprint:

    name: My Web Cluster


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

Then click the `Add to Catalog` button.

You can launch the application by clicking the `add application` button on the homescreen or the `+` button on the Applications tab. Select `My Web Cluster` and click the `Next` button, then deploy to dal10.

This will take a few minutes to provision.  Once the blueprint is up, you should be able to click on the My Web entity on the left and it'll display URL for the newly provisioned application on the right , e.g.
http://169.53.137.237:8000/

## To clear out your servers, select the application and click "Stop" on the Effectors tab. This will break down the app and cancel all servers in SoftLayer

## This homework is not graded. It is complete/incomplete only.
### Submit the URL for your brooklyn admin UI as well as the ID and Password to access it.
