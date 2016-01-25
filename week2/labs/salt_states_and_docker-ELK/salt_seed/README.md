# salt-elk

## Introduction

Salt state and pillar data to set up a single-box ELK stack. To use this, you'll need to have a saltmaster (ask an instructor if you need help with this).

You'll also need to generate an SSL certificate for the logstash forwarder and **replace** the dummy RSA private key content in `srv/pillar/ssl.sls`.  It is located in [Github] (https://github.com/MIDS-scaling-up/coursework/blob/master/week2/labs/salt_states_and_docker-ELK/salt_seed/srv/pillar/ssl.sls).

Your openssl key and cert generation commands may look like this (please review and change fields to match your locale and email address):

    openssl genrsa -out logstash-forwarder.key 4096

    openssl req -subj "/C=US/ST=State/L=City/O=Org/CN=elk.mids/emailAddress=hostmaster@hovitos.engineering" -new -key logstash-forwarder.key -out logstash-forwarder.csr

    openssl x509 -req -days 3650 -in logstash-forwarder.csr -signkey logstash-forwarder.key -out logstash-forwarder.crt

Note that logstash is really picky about certs: make sure to set the CN to 'elk.mids' and create an entry in /etc/hosts on the transmitting box to match this.

Note that the formatting of `ssl.sls` is really particular: you need to indent the entire pasted key content the way the dummy text was indented. To do this with Vi, open the file and execute this Vi command:

    g/BEGIN RSA PRIVATE KEY/ .,.+4 d | r !sed -e 's/^/    /' logstash-forwarder.key

Copy the matching cert into `srv/salt/logstash/`.
