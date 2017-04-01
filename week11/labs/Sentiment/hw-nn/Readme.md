###DIGITS and Object Detection    

#### Intro
[Digits](https://github.com/NVIDIA/nvidia-docker/wiki/DIGITS) is the leading tool for rapid training of image related networks.
It supports Caffe and Torch and now is on version 5.  In the previous lab, we used it to train a simple image classification network. 
In this assignment, we will go to the next step and focus on DetectNet, a network for object localization.

#### General
This lab follows DIGITS's [Object Detection Example] (https://github.com/NVIDIA/DIGITS/tree/master/examples/object-detection) 

http://169.50.131.114:5001/  is the URL to access our server running a docker container with DIGITS 5 inside.

The instructors have done some work for you already: the `./prepare_kitti_data.py` script has already been run; you need to pick up 
from the LOADING DATA INTO DIGITS section.

The object detection example files are located under /data/DIGITS/examples/object-detection (e.g. kitti data will be in 
/data/DIGITS/examples/object-detection/kitti-data )

We suggest that each student uses a unique "group" for their work -- and as a submittable for the homework just tell us what it is so we can check your work
Tell us where to find your data set and your trained model.  Make sure you validate your model by running it on a few sample images.
