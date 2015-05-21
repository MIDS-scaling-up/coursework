# loggen

Loggen is a log-generating NodeJS webapp that serves BSD fortune output as `text/plain`.

## Configuration

Write the logstash cert as `docker/fs/etc/ssl/logstash-forwarder.crt` and set the value of the 'host' field in the 'tlsOptions' object in server.js (note that logstash is really picky about certs and the host value must match the CN of the certificate used for that box).

## Docker image building

In the project directory, build the docker image with:

    docker build -t loggen .

Once built, start the container from the image with:

    docker run -d --name loggen -p 80:80 -t loggen
