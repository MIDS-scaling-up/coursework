# salt-elk

## Introduction

Salt state and pillar data to set up a single-box ELK stack. To use this, you'll need to have a saltmaster (ask mdye@us.ibm.com about this if you need help with this).

You'll also need to generate an SSL certificate for the logstash forwarder and paste the content into `/srv/pillar/ssl.sls`. Make sure to set the CN to 'elk-salt' (an entry in /etc/hosts on the box must match this). Copy the matching cert into `/srv/salt/logstash/`.

Something similar needs to be done for kibana's SSL key and cert.

Your openssl key and cert generation commands may look like this:

        openssl genrsa -out logstash-forwarder.key 4096

    openssl req -subj "/C=US/ST=State/L=City/O=Org/CN=elk-salt/emailAddress=hostmaster@hovitos.engineering" -new -key logstash-forwarder.key -out logstash-forwarder.csr

    openssl x509 -req -days 3650 -in logstash-forwarder.csr -signkey logstash-forwarder.key -out logstash-forwarder.crt