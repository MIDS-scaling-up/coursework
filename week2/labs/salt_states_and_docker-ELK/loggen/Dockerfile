FROM centos:centos7
MAINTAINER mdye <mdye@us.ibm.com>

RUN yum install -y rsync
ADD docker /docker
RUN rsync -a /docker/fs/ /
RUN yum --enablerepo='epel-bootstrap' -y install epel-release

RUN yum install --nogpgcheck -y git nodejs npm fortune-mod

# do build, copy to installation dir
ADD . /src
RUN cd /src && npm install

EXPOSE 80

CMD ["/usr/local/bin/loggen_start"]
