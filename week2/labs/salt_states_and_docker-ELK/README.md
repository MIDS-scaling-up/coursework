# Lab: Salt States and Docker deployment of the ELK stack

## Overview

SaltStack can be used to maintain the state of a running system. It can ensure that user accounts are present on a system, that packages are installed, and that services are running. In this lab you’ll use it to start Docker containers on a newly-provisioned system.

Container virtualization is a useful mechanism to isolate single-process runtime environments. Docker, a platform that uses Linux native container functionality, is a popular container virtualization system that encourages use of immutable, portable runtime environments called _Docker_ Images.

## New Tools Used

- SaltStack Salt state management system, http://docs.saltstack.com/en/latest/topics/tutorials/starting_states.html
- Docker LXC container virtualization platform, https://www.docker.com/
- Elasticsearch, Logstash, and Kibana, https://www.elastic.co/products

## Preconditions
You must have a Unix (Linux or OSX) shell, a SoftLayer account, and the SoftLayer tool installed and configured. If you successfully completed the “Cloud Computing 101” homework assignment then you have the tools to get started.

## Part 1: Provision and Configure VSes

### Provision VSes
Use `slcli` to **provision 3 VSes**: _saltmaster_, _logger_, and _dhost_ (docker host), **with CentOS 7**; ensure _logger_ has 2GB RAM.You’ll use the _saltmaster_ to manage both _logger_ and _dhost_. Provision the systems simultaneously to save time and prefer SSH keys to password authentication. You can store your public SSH key with SoftLayer by using the Portal or the SoftLayer CLI command `slcli sshkey add --in-file PATH LABEL` where _PATH_ is a path to an on-disk RSA public key file and _LABEL_ is the short name you'll use to identify the key.

#### VS Creation example:
    slcli vs create --datacenter=sjc01 --hostname=saltmaster --os CENTOS_LATEST_64 --domain=lab2.sftlyr.ws --billing=hourly --cpu=1 --memory=1024 --key=KEY_LABEL

### Install and Configure Salt
Once the systems are provisioned, install the Salt Master on _saltmaster_ and configure it to manage _dhost_ and _logger_ with Salt SSH. Salt SSH is an alternative transport to Salt’s default option, ZeroMQ. It’s a valuable alternative to the ZeroMQ-based transport because it doesn’t require a running Salt Minion agent on the managed system, and connectivity is established to the minion from the master.

#### Install Salt on saltmaster
In this section you’ll need to edit some configuration files on the VS. If you’re familiar with Vi or Emacs you might install one with `yum`. If you’re unfamiliar with either of these options, you might try the Nano text editor (cf. https://www.linode.com/docs/tools-reference/tools/using-nano):

    yum install -y nano

Install the Salt Master daemon (note that using the ‘develop’ branch is normally not recommended but there’s a JSON rendering error as of this writing that the newest code avoids):

    yum update && curl -o /tmp/install_salt.sh -L https://bootstrap.saltstack.com && sh /tmp/install_salt.sh -Z -M git v2015.5.0

Edit the file `/etc/salt/master` and enable both the fs-based fileserver and pillar systems. Once correct, the file should contain uncommented configuration lines like these:

    file_roots:
      base:
        - /srv/salt
    ...
    fileserver_backend:
      - roots
    ...
    pillar_roots:
      base:
        - /srv/pillar

Create the fileserver and pillar directories and restart the daemon:

    mkdir -p /srv/{salt,pillar} && systemctl restart salt-master

Salt SSH uses the file `/etc/salt/roster` to configure minions. Browse the documentation (http://docs.saltstack.com/en/latest/topics/ssh/) and configure a roster file for use with _dhost_ and _logger_. Note that the file’s YAML (cf. http://yaml.org/) format requires leading spaces on indented lines and not tab characters. You may use either the password for the root account or configure SSH keys with `ssh-keygen`. If you choose to use passwords, remember the convenience of `slcli vs credentials <id>`.

Once you’ve completed this step, check your work by executing a remote command from the Salt Master.

    salt-ssh -i '*' cmd.run 'uname -a'

Expected output:

    dhost:
      Linux dhost 3.10.0-229.1.2.el7.x86_64 #1 SMP Fri Mar 27 03:04:26 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
    logger:
      Linux logger 3.10.0-229.1.2.el7.x86_64 #1 SMP Fri Mar 27 03:04:57 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux

## Part 2: Using Salt States

Salt state files are idempotent declarations of the _end state_ that a salt-managed system should have. In this lab, we’ll use state files to set up the popular ELK stack (Elasticsearch, Logstash, and Kibana) on a centralized logging VS named _logger_.

### Install git and obtain the Salt State seed files

On _saltmaster_, execute:

    yum install -y git
    cd /tmp && git clone https://github.com/MIDS-scaling-up/coursework.git && cd coursework/week2/labs/salt_states_and_docker-ELK/salt_seed/

### Modify state files and update logger

Follow the directions in [salt_seed/README.md](salt_seed/README.md) to generate the necessary certificates. Once complete, copy the content of `srv/` to `/srv/` on _saltmaster_. Apply the desired state to the logger VS:

    salt-ssh 'logger' state.highstate

### Tunnel to Kibana UI from workstation

You should now visit the Kibana UI. Because the UI is unprotected we've configured the service to listen only on the server's loopback interface. To create an SSH tunnel to the logger box **from your workstation**, execute the following command. Note that you must replace 'logger_ip' with the IP of the _logger_ VS you provisioned.

    ssh -L 5601:127.0.0.1:5601 root@logger_ip -N

Now browse to the Kibana UI at `http://localhost:5601/`, create an index, and explore incoming system log message in the _Discover_ area.

## Part 3: Deploying a Containerized service

Next you’ll deploy a containerized web application ([loggen](https://github.com/michaeldye/loggen)) on _dhost_ and configure it to securely send log messages to logger using lumberjack over TLS.

### Build a Docker Image for Loggen

Rather than compose a statefile for _dhost_’s container we’ll configure the deployment with Salt remote execution commands. The result is a Docker image named ‘loggen’ constructed on _dhost_ with the appropriate logstash-forwarder SSL certificate for the server.

    salt-ssh 'dhost' pkg.install docker
    salt-ssh 'dhost' service.enable docker
    salt-ssh 'dhost' service.start docker
    salt-ssh 'dhost' pkg.install git
    salt-ssh 'dhost' git.clone /usr/local/loggen https://github.com/michaeldye/loggen.git
    salt-ssh 'dhost' cp.get_file salt://logstash/logstash-forwarder.crt /usr/local/loggen/docker/fs/etc/ssl/

Ensure you replace 'logger_ip' in the below command with the IP of your _logger_ instance:

    salt-ssh 'dhost' cmd.run 'echo -e "logger_ip elk.mids" >> /usr/local/loggen/docker/fs/etc/hosts_add'

Finally, build the docker container. Note that this last command will take some time to complete.

    salt-ssh 'dhost' cmd.run 'cd /usr/local/loggen/; docker build -t loggen .'


### Deploy Loggen

 To deploy a Docker container from a Docker Image (either pre-built and fetched from the internet or available locally as loggen is), use docker run with a command like the one below.

    salt-ssh 'dhost' cmd.run 'docker run -d --name loggen -p 80:80 -t loggen'

You can ensure that the container is running by executing:

    salt-ssh 'dhost' cmd.run 'docker ps'

### Issue HTTP Requests to Loggen, visit Kibana UI

Loggen will send log events for HTTP requests it receives. The program is simple, a user issues an HTTP GET request and the server will send log events to logger. You can issue a request to loggen with the following command (note you must replace 'dhost_ip' with the IP of your _dhost_ instance).

    curl -i http://dhost_ip/

You might want to issue quite a few requests to make finding HTTP request log message easier to find in Kibana. Visit the Kibana UI again and locate log message(s) from loggen. (Note that Elasticsearch may take a moment or two to index the new messages. Also note that you may need to use a filter like "name:loggen" to filter out syslog messages that can prevent you from viewing incoming loggen messages.
