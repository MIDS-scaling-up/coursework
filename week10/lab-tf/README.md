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

```
docker run -it tensorflow/tensorflow:1.2.1 bash
```
    
After downloading your prompt should change to root@xxxxxxx:/notebooks#.

Next check to confirm that your TensorFlow installation works by invoking Python from the container's command line:

      # Your prompt should be "root@xxxxxxx:/notebooks" 
        python

Once you have a python prompt, >>>, run the following code:

```
# python

import tensorflow as tf
hello = tf.constant('Hello, TensorFlow!')
sess = tf.Session() # It will print some warnings here.
print(sess.run(hello))
```

This should print Hello TensorFlow! (and a couple of warnings after the tf.Session line).

Now press Ctrl-d, on a blank line, once to exit python, and a second time to exit the docker image.

## Configure

Create a working directory:

```
mkdir tf_files
```

and change to that directory

```
cd ~/tf_files
```
    
You will need to download the following files to your VM: bottlenecks1.tar.gz, bottlenecks2.tar.gz, label_image.py, retrain.py
test.jpg:

```
curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/bottlenecks1.tar.gz
curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/bottlenecks2.tar.gz
curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/label_image.py
curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/retrain.py
curl -O https://raw.githubusercontent.com/MIDS-scaling-up/coursework/master/week10/lab-tf/test.jpg
```
    
Extract the bottleneck files:

```
tar xvf bottlenecks1.tar.gz 
tar xvf bottlenecks2.tar.gz 
```

This will create the following directory stucture:
 
```
- bootlenecks
    - daisy
    - dandelion
    - roses
    - sunflowers
    - tulips
```

These are the classes that we will train.  

A "Bottleneck", is an informal term that the TensorFlow team often use for the layer just before the final output layer that actually does the classification. As, near the output, the representation is much more compact than in the main body of the network.  We've provided the files to speed up training.  See  https://codelabs.developers.google.com/codelabs/tensorflow-for-poets/#4 for a detailed description on what bottlenecks do and how they speed up learning. 

Then relaunch Docker with that directory shared as your working directory, and port number 6006 published for TensorBoard:
    
```
docker run -it \
--publish 6006:6006 \
--volume ${HOME}/tf_files:/tf_files \
--workdir /tf_files \
tensorflow/tensorflow:1.2.1 bash
```

## Download the Images

Before you start any training, you'll need a set of images to teach the network about the new classes you want to recognize. We've created an archive of creative-commons licensed flower photos to use initially.

Download the sample images:

```
curl -O http://download.tensorflow.org/example_images/flower_photos.tgz
tar xzf flower_photos.tgz
```

After downloading 218MB, you should now have a copy of the flower photos available in your working directory.

Now check the contents of the folder:

```
ls flower_photos
```

## (Re)training

At this point, we have a trainer, we have data, so let's train! We will train the Inception v3 network.

Optional: Before starting the training, launch tensorboard in the background so you can monitor the training progress.  
        
```
tensorboard --logdir training_summaries &
```
     
Start your image retraining with one big command (note the --summaries_dir option, sending training progress reports to the directory that tensorboard is monitoring):

```
python retrain.py \
--bottleneck_dir=bottlenecks \
--how_many_training_steps=500 \
--model_dir=inception \
--summaries_dir=training_summaries/basic \
--output_graph=retrained_graph.pb \
--output_labels=retrained_labels.txt \
--image_dir=flower_photos
```
    
This script downloads the pre-trained Inception v3 model, adds a new final layer, and trains that layer on the flower photos you've downloaded.

ImageNet was not trained on any of these flower species originally. However, the kinds of information that make it possible for ImageNet to differentiate among 1,000 classes are also useful for distinguishing other objects. By using this pre-trained network, we are using that information as input to the final classification layer that distinguishes our flower classes.

The above example iterates only 500 times. If you skipped the step where we deleted most of the training data and are training on the full dataset you can very likely get improved results (i.e. higher accuracy) by training for longer. To get this improvement, remove the parameter --how_many_training_steps to use the default 4,000 iterations.

Optional: You may check out your tensorboard to see how training is going.  It is accessed at http://<YOUR VM IP>:6006
See https://codelabs.developers.google.com/codelabs/tensorflow-for-poets/#4 for the details.

### Using the Retrained Model

The retraining script will write out a version of the Inception v3 network with a final layer retrained to your categories to tf_files/retrained_graph.pb and a text file containing the labels to tf_files/retrained_labels.txt.

These files are both in a format that the C++ and Python image classification examples can use, so you can start using your new model immediately.

You'll use label_image.py to test your model.

First a daisy

    python label_image.py flower_photos/daisy/21652746_cc379e0eea_m.jpg

and then a rose

    python label_image.py flower_photos/roses/2414954629_3708a1a04d.jpg 

You will then see a list of flower labels, hopefully with the correct flower on top (though each retrained model may be slightly different).  For example:

    daisy (score = 0.99071)
    sunflowers (score = 0.00595)
    dandelion (score = 0.00252)
    roses (score = 0.00049)
    tulips (score = 0.00032)
    
This indicates a high confidence it is a daisy, and low confidence for any other label.

Now run:

    python label_image.py test.jpg
    
What was the classification? Surprised?

Feel free to upload additional test images and note how well (or not) your model performs.

### Optional Steps

The retraining script has several other command line options you can use. parameters you can try adjusting to see if they help your results.

You can read about these options in the help for the retrain script:

    python retrain.py -h
    
For example the --learning_rate parameter controls the magnitude of the updates to the final layer during training. So far we have left it out, using the value of 0.01. If this rate is smaller, like 0.005, the learning will take longer, but it can help the overall precision. Higher values, like 1.0, could train faster, but may obtain worse final results, or even become unstable.

You need to experiment carefully to see what works for your case.

See https://codelabs.developers.google.com/codelabs/tensorflow-for-poets/#6 for details

You may also train your own categories.  All you need to do is run the tool, specifying a particular set of sub-folders. Each sub-folder is named after one of your categories and contains only images from that category.

If you complete this step and pass the root folder of the subdirectories as the argument for the --image_dir parameter, the script should train the images that you've provided, just like it did for the flowers.
   
