Tensfor For Poets
This lab is based on https://codelabs.developers.google.com/codelabs/tensorflow-for-poets

Provision VM
You will need to Ubuntu 16.04 VM with at least 2x2 GHz CPUs, 4GB of RAM, and a 20GB local disk.
Please note the IP address of your VM once it is provisioned.  

Setup TensorFlow
We will use Docker to run TensorFlow; you may install TensforFlow if wish (see https://www.tensorflow.org/install/) but for this exercise, Docker is simplier.  

The following steps assume you are running as root.

Part 1. Install Docker (see https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-repository for more details).

1. Update the apt package index:

 apt-get update
 
2. Install packages to allow apt to use a repository over HTTPS:

 sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
