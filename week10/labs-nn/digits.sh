#!/bin/sh

# this installs Nvidia digits.  Nnote that the Nvidia driver installation requires some user input.  It will try to update itself - the --update flag
apt-get update
apt-get install -y curl
cd /tmp

# we assume here that the drivers are installed. if not, uncomment..
curl http://AFED.http.sjc01.cdn.softlayer.net/nvidia/NVIDIA-Linux-x86_64-370.28.run -o /tmp/NVIDIA-Linux-x86_64-370.28.run
chmod a+x ./NVIDIA-Linux-x86_64-370.28.run
./NVIDIA-Linux-x86_64-370.28.run -a --update

#curl http://AFED.http.sjc01.cdn.softlayer.net/nvidia/nvidia-docker_1.0.0.rc.3-1_amd64.deb -o /tmp/nvidia-docker_1.0.0.rc.3-1_amd64.deb
#curl https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb  -o /tmp/nvidia-docker_1.0.1-1_amd64.deb
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb

# docker
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main"  | sudo tee /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y linux-image-extra-$(uname -r) linux-image-extra-virtual
apt-get update
apt-get install -y docker-engine

# nvidia docker
dpkg -i nvidia-docker_1.0.1-1_amd64.deb


service docker start

# the data dir is shared with digits
mkdir -m 777 /data

# it may fail the first time because nvidia!
nvidia-docker run --name digits -v /data:/data -d -p 5000:34448 nvidia/digits

nvidia-docker run --name digits -v /data:/data -d -p 5000:34448 nvidia/digits
