# Digits in a separate VM in Softlayer

Unfortunately, this is a little bit involved but ultimately, worth it!


### Provision the VM 
We are using two P-100 GPUs for this VM, the fastest currently available in SoftLayer.  We are using Ubuntu 16 as the OS as of right now, 18.04 is not yet supported with GPUs.

Notice that we are getting two disks; the larger one will be used for dataset storage later on.
```
# replace the things in <> with your own values
slcli vs create --datacenter=dal13 --hostname=<hostname> --domain=<domain> --os=UBUNTU_16_64 --flavor AC1_16X120X25 --billing=hourly --san --disk=25 --disk=2000 --network 1000 --key=<your SL key>

# for instance, this is what I did:
slcli vs create --datacenter=dal13 --hostname=p100 --domain=dima.com --os=UBUNTU_16_64 --flavor AC1_16X120X25 --billing=hourly --san --disk=25 --disk=2000 --network 1000 --key=p305
``` 
### Install cuda
As of right now, 10 is the latest version.  Check https://developer.nvidia.com/cuda-toolkit  for the latest..
```
wget https://developer.nvidia.com/compute/cuda/10.0/Prod/local_installers/cuda-repo-ubuntu1604-10-0-local-10.0.130-410.48_1.0-1_amd64
dpkg -i cuda-repo-ubuntu1604-10-0-local-10.0.130-410.48_1.0-1_amd64
# the key
apt-key add /var/cuda-repo-10-0-local-10.0.130-410.48/7fa2af80.pub
# install it!
apt-get update
apt-get install cuda
```
### Install docker
Validate these at https://docs.docker.com/install/linux/docker-ce/ubuntu/
```
apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
	
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"	

apt-get update

apt-get install docker-ce

# verify

docker run hello-world
```

### Install nvidia-docker (version 2)
First, add the package repositories
```
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
```

Now, install nvidia-docker2 and reload the Docker daemon configuration
```
apt-get install -y nvidia-docker2
pkill -SIGHUP dockerd
```
Test nvidia-smi with the latest official CUDA image
```
docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi
```
Hopefully, you will see your GPUs.  
### Prepare the second disk
What is it called?
```
fdisk -l
```
You should see your large disk, something like this
```
Disk /dev/xvdc: 2 TiB, 2147483648000 bytes, 4194304000 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```
In this case, our disk is called /dev/xvdc.  Your disk may be named differently.  Format it:
```
# first
mkdir -m 777 /data
mkfs.ext4 /dev/xvdc
```

Add to /etc/fstab
```
# edit /etc/fstab and all this line:
/dev/xvdc /data                   ext4    defaults,noatime        0 0
```
Mount the disk
```
mount /data
```

### Start Digits in a container
Login into nvcr.io
```
# make sure you register at https://ngc.nvidia.com and enter your credentials when prompted
docker login nvcr.io
```
Pull and start the container.  Note that we are using 18.10 here; you will likely need to pull the latest.  Note also that we are passing through the /data disk to the container to be used for datasets:
```
# check the latest version of the Digits container here: https://ngc.nvidia.com/catalog/containers/nvidia%2Fdigits
nvidia-docker run --shm-size=1g --ulimit memlock=-1 --name digits -d -p 8888:5000 -v /data:/data -v /data/digits-jobs:/workspace/jobs nvcr.io/nvidia/digits:18.10
```
### Validate that Digits is running
Just hit this url:  http://<your VM IP>:8888
	
