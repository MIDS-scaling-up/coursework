# TensorFlow For Poets

This lab is based on https://codelabs.developers.google.com/codelabs/tensorflow-for-poets

## Provision VM

You will need to Ubuntu 16.04 VM with at least 2x2 GHz CPUs, 4GB of RAM, and a 20GB local disk.
Please note the IP address of your VM once it is provisioned.  

## Setup TensorFlow

We will use Docker to run TensorFlow; you may install TensforFlow if wish (see https://www.tensorflow.org/install/) but for 
this exercise, Docker is simplier.  

The following steps assume you are running as root.

We'll start by installing Docker, see see https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/#install-using-the-repository for more details.

Update your apt package index with the following command:

    apt-get update
     
Next, you'll install the packages needed to enable apt to work with HTTPS by running the following command:

    apt-get install \
     apt-transport-https \
     ca-certificates \
     curl \
     software-properties-common
    
Now add Docker’s official GPG key:

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 
Optional: See detailed instructions on how to verify the key.

You'll need add the Docker repository; this is done by:

    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
   
You'll need to update the package index again to include the new repository:

    apt-get update 
 
To install Docker, run the following: 

    apt-get install docker-ce
 
And finally, to verify the install:
 
    docker run hello-world
 
 This command downloads a test image and runs it in a container. When the container runs, it prints an informational message and exits.  The text will be similar to:
 
     Hello from Docker!
     This message shows that your installation appears to be working correctly.
     
## Validate TensorFlow

With Docker installed, you may now test out the TensorFlow image:
      
     docker run -it tensorflow/tensorflow:1.2.1 bash
    
After downloading your prompt should change to root@xxxxxxx:/notebooks#.

Next check to confirm that your TensorFlow installation works by invoking Python from the container's command line:

      # Your prompt should be "root@xxxxxxx:/notebooks" 
        python

Once you have a python prompt, >>>, run the following code:

      # python

      import tensorflow as tf
      hello = tf.constant('Hello, TensorFlow!')
      sess = tf.Session() # It will print some warnings here.
      print(sess.run(hello))

This should print Hello TensorFlow! (and a couple of warnings after the tf.Session line).

Now press Ctrl-d, on a blank line, once to exit python, and a second time to exit the docker image.

## Configure

Create a working directory:

    mkdir tf_files

and change to that directory

    cd ~/tf_files
    
You will need to download the following files to your VM: bottlenecks1.tar.gz, bottlenecks2.tar.gz, label_image.py, retrain.py
test.jpg:

    curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/bottlenecks1.tar.gz
    curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/bottlenecks2tar.gz
    curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/label_image.py
    curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/retrain.py
    curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf.test.jpg
    
Extract the bottleneck files:



