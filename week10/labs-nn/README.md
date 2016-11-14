###Digits 4 and Object Detection

#### Intro
[Digits](https://github.com/NVIDIA/nvidia-docker/wiki/DIGITS) is currently one of the leading tools to easily train and run neural nets.
It supports Caffe and Torch and is in furious development. Note that the production branch is 4 while the dev branch with a lot more features is 5.

#### General
This lab follows DIGITS's [Object Detection Example] (https://github.com/NVIDIA/DIGITS/tree/master/examples/object-detection) 
We have done some of the work already: the `./prepare_kitti_data.py` script has already been run; you need to pick up from there.

The object detection example files are located under /data/DIGITS/examples/object-detection

http://169.50.131.107:5000/  is the URL to access our server running a docker container with DIGITS inside.

We suggest that you form groups; and each group can practice independently creating their own data sets and models with unique names.
