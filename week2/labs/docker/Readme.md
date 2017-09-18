### Docker 101
This lab is a primer on docker, which in the past few years emerged as the dominant workload management and deployment tool.

Docker - https://www.docker.com/  - is a collection of tools around Linux Containers [which are a lightweight form of virtualization]. 
Linux Containers have been part of the Linux kernel for quite some time now, but the user space tooling has lagged, which provided 
an opportunity for Docker as a company.  Recently, Docker became available on MacOS X and even on Windows 10 Professional or later, in addition
to Linux. Note that while Docker on MacOS X is "native", it requires an underlying hypervisor on Windows. It is important to realize
that a linux container shares the kernel with the underlying VM or host; there is no need to copy the entire OS.  This is why the containers
are very small and light, they are easy to spin up and you can have many of them on devices as small as Raspberry Pi Zero..

#### Installing docker
If you already have docker running, you may skip this step.  However, you may wish to do it if you never installed docker on ubuntu.
This assumes that you have an slcli installed somewhere, e.g. on a VM in softlayer or in your local environment.

Let us spin up a clean VM.  This will take a few minutes to come up:
```
 slcli vs create --datacenter=dal09 --domain=<something here> --hostname=<something here> --os=UBUNTU_16_64 --cpu=1 --memory=1024 --billing=hourly --key=<your key>
```

Now, let us follow the official instructions here to install DockerCE on Ubuntu 16:
https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
```
apt-get update
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    
# add the docker repo    
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
 
# install it
apt-get update
apt-get install docker-ce
```
#### Running and managing docker containers.
Let us validate that docker is installed:
```
docker run hello-world
```
If this completed successfully, you have successfully got your first docker container running!  Now. let's try to find it:
```
docker ps
```
This command should show you all active docker containers.  At this point, the list should be empty, since the hello-world container exited.  However, the container should still be there:
```
docker ps -a
# Should see something similar to the bwlow:
# CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                          PORTS               NAMES
# 94a841d96b07        hello-world         "/hello"            About a minute ago   Exited (0) About a minute ago                       elated_brahmagupta
```
Now, let us remove this docker container:
```
docker rm <container_id>
docker ps -a
```

The container should be gone now.

Let's get a ubuntu container going:
```
docker run --name my_ubuntu -ti ubuntu bash
```
This should have downloaded the docker ubuntu image,  created a container called my_ubuntu, started it, and attached a terminal to it.  At this point, you should be inside the container.  The -ti flag connects the current terminal to the container.  Do something inside this container, e.g. 
```
apt-get update
```
Now, let us temporarily disconnect from this container:
```
Ctrl-P Ctrl-Q
```
You should now be back in your VM.  Let's see what's running :
```
docker ps
# you should see your container is actively running.
```





