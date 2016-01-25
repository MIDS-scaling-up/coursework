# Working with Cloud Resources

## Tools Used

* SoftLayer Python library and bundled CLI tool `slcli`, https://pypi.python.org/pypi/SoftLayer/4.0.2. See also https://softlayer-api-python-client.readthedocs.org/en/latest/cli/
* `pip`, a Python package management tool, https://pip.pypa.io/en/stable/

## VSes Cont'd.

Among other functions, the `slcli` command can order, deprovision (or ‘cancel’), list provisioned, and upgrade servers. Most often you’ll work with virtual servers in this class, but SoftLayer can also provision bare metal servers. Bare metal servers take longer to provision (often some 20 minutes per machine vs. 2 or 3 minutes for VS provisioning), but are higher-performing than virtual servers especially for I/O-heavy operations. Hourly-billed bare metal servers are available and you might find one useful for certain kinds of big data work. For more information, see http://www.softlayer.com/bare-metal-servers.

To learn more about using `slcli`, consult the documentation at https://softlayer-api-python-client.readthedocs.org/en/latest/cli/ or execute `slcli --help` to access inline help.

---
**Warning**: Many of the below commands order cloud resources and some options are expensive. The provided SoftLayer resource credits are limited; resolve early to provision systems lean. Avoid wasting resources by leaving systems idle and prefer to automate provisioning, performing work and swiftly deprovisioning systems.
---

### Using the SoftLayer API

The `slcli` tool is a convenient frontend for the SoftLayer API (http://sldn.softlayer.com/reference/services/SoftLayer_Account). The API is accessible programmatically via SOAP and bindings in particular languages as well as through a ReST interface. The tool `jq` (http://stedolan.github.io/jq/) can be used with `curl` to make convenient use of the ReST API (if you execute this command, make sure to replace the fields in `<>`'s with your own values):

    curl 'https://<username>:<key>@api.softlayer.com/rest/v3/SoftLayer_Account/VirtualGuests.json?objectMask=id;hostname;fullyQualifiedDomainName;primaryIpAddress;operatingSystem.passwords' | jq -r '.[] | select(.hostname == "<my_vms_hostname>") | {fullyQualifiedDomainName,id, root_password: .operatingSystem.passwords[] | select(.username == "root").password, primaryIpAddress}'

You should see results like these:

    {
      "fullyQualifiedDomainName": "ms.some.domain.tld",
      "id": 156169,
      "root_password": "Z90NxAS5v",
      "primaryIpAddress": "5.15.12.250"
    }

### Working with SSH Keys

SSH is a standardized secure remote shell access tool and OpenSSH is a popular implementation of it. You will use OpenSSH to administer SoftLayer systems in this class. Authentication with text passwords is possible with SSH but not recommended. Instead, prefer use of SSH keys. (To learn more about SSH, visit https://digitalocean.com/community/tutorials/understanding-the-ssh-encryption-and-connection-process).

SSH keys can be generated at will, are stored in ASCII text, and come in pairs. An OpenSSH __public__ key has a name like “id_rsa.pub” and content like this:

    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKZ/ykXspE4h8rXQircz/S/bE4LpOkhi+0PX4jZ0JKLsPl1A0jhrR7SLtUFcMVI+7m06fL66F78GxTSd0FjuqszAUPM92INKsp2UnUqtROO0eW3tJk5M/8v3NOLInh9MV/ftq9milaX15pXNZwLZ6jzbhU9TTJecAGoaOP5Yvwlva1po+HXe6rAWJGnpEpoOZu1ZMOJrG5i2H5sP0NJXU5552l3cMMbdhVXOuOWEx7Rejy9YqehWsqFlE7VU0OFos33IyZf25DX2sIJhHpcM3hnXFtKeNDM8Ius9uPd5M+Zhr2fGofnhkThEgjeS3wOlIqA9hb1SEdUK+F+RDP9q/5 some-key-comment

A corresponding __private__ OpenSSH key has a name like “id_rsa” and a header line like this:

    -----BEGIN RSA PRIVATE KEY-----

An SSH private key is a personal authentication credential and **should not be published or shared**. On the other hand, the public key in the keypair __should__ be distributed. In fact, it is by distributing the public key among endpoint servers that passwordless authentication with them is made possible.

For more information on public key cryptography and its history, visit http://arstechnica.com/security/2013/02/lock-robster-keeping-the-bad-guys-out-with-asymmetric-encryption/. For more detail on cryptopgraphy consult https://engineering.purdue.edu/kak/compsec/NewLectures/Lecture12.pdf.

#### Generating an SSH keypair and using it with SoftLayer
An SSH keypair can be generated on your Unix system and the public key in the pair can be stored in SoftLayer for use with its systems.

Generate an SSH keypair and please add a key passphrase:

    ssh-keygen -f ~/.ssh/id_rsa -b 2048 -t rsa -C 'meaningful comment'

Note that the file path we’ve chosen is the default for OpenSSH. If you already have SSH keys on your system you can choose another filename. It is wise to back up SSH keypairs, but please do not store them unencrypted in cloud storage accounts.

Associate the __public key__ with your SoftLayer account (you can pick any meaningful string you’d like for the SSH key __identifier__):

    slcli sshkey add -f ~/.ssh/id_rsa.pub --note 'added during HW 2' <identifier>

    SSH key added: d9:14:8b:41:2e:77:3c:fc:a6:04:c6:3b:d5:46:f9:87

Don’t forget the __identifer__ you used in the above command, you’ll need it later.

## Cloud Management with Salt

Salt is a remote execution toolkit with cloud provisioning and configuration management features. In this section, you’ll install SaltStack’s Salt Master and Salt Cloud components on a SoftLayer VS and get acquainted with their core features. For more information on SaltStack, consult http://docs.saltstack.com/en/latest/ref/.

### Set up Salt Cloud on a VS

Salt Cloud is a cloud provisioning program that we’ll use to automate provisioning new VSes.

#### Provision a new VS

Provision a new VS (you can choose your own datacenter and domain name if you wish; we recommend using a hostname with the ‘saltmaster’ prefix for Salt configuration management convenience). Note that you’re making use of the SSH key you generated earlier:

    slcli vs create -d hou02 --os CENTOS_LATEST --cpu 1 --memory 1024 --hostname saltmaster --domain someplace.net --key identifier

Use `slcli vs list` to check up on the provisioning VS. Provisioning is finished when you the ‘action’ field in the output has the value ‘-’.

#### SSH to the VS

Use `slcli vs list` and `slcli vs credentials <id>` or the SoftLayer management web UI (https://control.softlayer.com/) to discover both the public IP address and the root password of your VS. Login to the VS using SSH (note that you must replace the pink field with the IP you’ve discovered):

    ssh root@5.1.56.1

#### Install Salt programs

While logged into the VS, execute:

    curl -o /tmp/install_salt.sh -L https://bootstrap.saltstack.com && sh /tmp/install_salt.sh -Z -M git 2015.5

    yum install -y python-pip && pip install SoftLayer apache-libcloud

#### Configure Salt Cloud

    mkdir -p /etc/salt/{cloud.providers.d,cloud.profiles.d}

You next must populate some configuration files on the server. For each command below of the form `cat > /path`, you type the line provided and the shell will put the cursor at the beginning of a new line. Paste into the window the desired content of the configuration file, hit the **ENTER** key, and then type the sequence **CTRL-d** and the shell will give you a new prompt (this is easier than it sounds, I promise). Make sure you use space characters instead of tabs for these files as the YAML format requires it.

Alternately you can use an editor of your choice (vim, emacs, nano).

Write a cloud provider configuration file. Note that you must replace the values in `<>`'s. The value on the `master: …` line should be the public IP address of your VS.

    cat > /etc/salt/cloud.providers.d/softlayer.conf
    sl:
      minion:
        master: <6.2.6.1>
      user: <beyonce>
      apikey: <ZZZZZZZZZZZZZZZZZZZZZ>
      provider: softlayer
      script: bootstrap-salt
      script_args: -Z git 2015.5
      delete_sshkeys: True
      display_ssh_output: False
      wait_for_ip_timeout: 1800
      ssh_connect_timeout: 1200
      wait_for_fun_timeout: 1200

Verify that you’ve properly written the file to disk:

    cat /etc/salt/cloud.providers.d/softlayer.conf

    sl:
      minion:
        master: ...

Write a cloud profiles configuration file:

    cat > /etc/salt/cloud.profiles.d/softlayer.conf
    sl_centos7_small:
      provider: sl
      image: CENTOS_7_64
      cpu_number: 1
      ram: 1024
      disk_size: 25
      local_disk: True
      hourly_billing: True
      domain: <somewhere.net>
      location: dal06

### Provision a new VS with Salt Cloud

Execute:

    salt-cloud -p sl_centos7_small <mytestvs>

You should observe output like this:

    mytestvs:
        ----------
        accountId:
                278184
        createDate:
                2015-05-11T20:31:00-07:00
        domain:
                somewhere.net
        fullyQualifiedDomainName:
                mytestvs.somewhere.net, sc
        globalIdentifier:
                9daf76df-b468-4a7b-a1c2-0ab9d60a216a
        hostname:
                mytestvs
    ...

(Note that this command does a complete provisioning process and may take a few minutes to complete).

When it provisions a new VS, Salt Cloud can enlist the new VS in its management system. The VS under management is called a Salt “Minion”.


### Use Salt Master to remotely manage provisioned VS (minion)

#### View minions under Salt management

Execute:

    salt-key -L

Observe output like the following:

    Accepted Keys:
    mytestvs
    ...

#### Execute remote commands on VS

Retrieve a system’s configured public IP address:

Execute:

    salt 'mytestvs' network.interface_ip eth1

    mytestvs:
        158.85.137.185


Retrieve network statistics for all systems under management:

    salt '*' status.netstats

    mytestvs:
        ----------
        IpExt:
            ----------
            InBcastOctets:
                3628
            InBcastPkts:
    ...

Before canceling the two VSes you’ve been manipulating, try some more Salt remote execution commands. You can find a list of modules at http://docs.saltstack.com/en/latest/ref/modules/all/. Try to find the applicable execution modules and perform these tasks:

* Resolve a DNS name from the minion (hint: the output will be an IP address)
* Transmit a file from the master to the minion using salt commands
* Use salt to increase the minion OS’s maximum file descriptors limit, apply the changes, and confirm that the increased limit has been set by the OS (hint: the __ulimit__ command is used to check this value)

### Use Salt Cloud to deprovision the minion VS

Salt Cloud can deprovision VSes. This can sometimes be a valuable alternative to the slcli command because Salt’s pattern-matching can be used to delete groups of VMs by name. For now, simply delete the VS we’ve been manipulating:

    salt-cloud -dy mytestvs

    softlayer:
        ----------
        mytestvs:
            True

## Using the SoftLayer Object Store

SoftLayer Object Storage is a reliable key-value storage system. You can interact with either programmatically using a library or through the REST API using an HTTP client like a web browser or the command line tool cURL.

To use Object Storage, you must first order the service and create a container. Multiple containers can be associated with a given account and are a mechanism to separate data. Not unlike a storage device in a personal computing system, a container can store objects and (optionally) folders.

First, create a pay-as-you-go Object Storage account. Issue the command using the special pasting method described earlier for input beginning `{"parameters" : …` . The `jq` call will extract the necessary `id` of of the ordered item for use in following steps. (Note that the command may take a moment to complete execution).

    curl 'https://<username>:<api_key>@api.softlayer.com/rest/v3.1/SoftLayer_Product_Order/placeOrder' --data @- | jq -r '.placedOrder.items[] | select(.itemId == 4069) | {id}'

    {"parameters" : [
      {
        "complexType": "SoftLayer_Container_Product_Order_Network_Storage_Hub",
        "quantity": 1,
        "packageId": 0,
        "prices": [{ "id": 16984}]
       }
    ]}

Observe output like:

    {
      "id": 66901067
    }

Each Object Storage account has a storage username you’ll need to use to interact with the storage system. To retrieve yours, execute:

    curl 'https://<username>:<api_key>@api.softlayer.com/rest/v3.1/SoftLayer_Account/getHubNetworkStorage.json?objectMask=id;username;billingItem.id;billingItem.orderItemId' | jq -r '.[] | select(.billingItem.orderItemId == <66901067>) | {username}'

Retain the output value:

{
  "username": "GGAF-23584-48"
}

### Obtain a Temporary Authentication Token

To manipulate objects in Object Storage you’ll need an authentication token. This is a credential that is valid for approximately 1 day and is required in all HTTP calls to the API. Obtain this information with a call like the one below. Note that a specific datacenter is picked out: Object Store data is specific to a data center and not automatically replicated between them. Also note use of the `-i` option to `curl`, this will print HTTP response headers before the payload of the response.

    curl -i -H "X-Auth-User:<GGAF-23584-48>:<username>" -H "X-Auth-Key:<api_key>" https://<dal05>.objectstorage.softlayer.net/auth/v1.0

    HTTP/1.1 200 OK
    ...
    X-Auth-Token: AUTH_tk1152128357891357189351477
    X-Storage-Url: https://dal05.objectstorage.softlayer.net/v1/AUTH_71923841-27f2-4bfa-917d-0cb237987972
    ...

Retain the values of these two HTTP response headers for subsequent HTTP calls.

### Create a Container

Now that you have authentication information and a storage URL you can create a container (note the use of values from previous command's output):

    curl -i -X PUT -H "X-Auth-Token: AUTH_tk1152128357891357189351477" https://dal05.objectstorage.softlayer.net/v1/AUTH_71923841-27f2-4bfa-917d-0cb237987972/<myfiles>

### List Containers

    curl -i -H "X-Auth-Token: AUTH_tk1152128357891357189351477" https://dal05.objectstorage.softlayer.net/v1/AUTH_71923841-27f2-4bfa-917d-0cb237987972

Note that the primary difference between this command and the creation command is the HTTP method: an HTTP __PUT__ request was used to add a container, the HTTP __GET__ method is assumed if not provided to `curl` and for this method the SoftLayer API returns a list of containers (below the header output).

### Write a File To a Container

Curl can send binary data in an HTTP request and the Object Storage API will store that data in a container. To try it, execute a command like the following. Note the specification of the container and destination file name in the URL path:

    curl -i -X PUT -H "X-Auth-Token: AUTH_tk1152128357891357189351477" https://dal05.objectstorage.softlayer.net/v1/AUTH_71923841-27f2-4bfa-917d-0cb237987972/<myfiles/test_file.txt> --data-binary "<some test text>"

You can retrieve this file with another HTTP request:

    curl -H "X-Auth-Token: AUTH_tk1152128357891357189351477" https://dal05.objectstorage.softlayer.net/v1/AUTH_71923841-27f2-4bfa-917d-0cb237987972/myfiles/test_file.txt

Output:

    some test text

### Using Swift

The method we used to test the Object Store are not very convenient. There is a Python library named swift you can use to mitigate the tedium. Install the swift client with the command:

    sudo pip install python-swiftclient

Configure the client by setting environment like this:

    export ST_AUTH=https://<dal05>.objectstorage.softlayer.net/auth/v1.0
    export ST_USER=GGAF-23584-48:<username>
    export ST_KEY=<api_key>

You can list containers with `swift`:

    swift list

List files in a container:

    swift list myfiles

Download a file from a container:

    swift download myfiles test_file.txt

Upload a file from disk (named “another_test_file.txt”) to a new container named “more_files”:

    echo "more test content" > /tmp/another_test_file.txt

    swift upload more_files /tmp/another_test_file.txt


## Homework Submission

Please consult the Coursework area of LMS for details on homework submission (https://learn.datascience.berkeley.edu/course/view.php?id=64&group=185&page=coursework).
