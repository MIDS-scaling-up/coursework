### Darknet and Yolo
This lab is a primer on Yolo (You Only Look Once) and Darknet.

Darknet and Yolo -- https://pjreddie.com/darknet/yolo   -- has become the golden standard for low power (IoT-esque) neural network based object 
detection.  It is much faster than scanning frames for objects and is rapidly becoming available on small devices like cell phones and mobile
GPUs.

In this lab, we will learn how to get started with it. This  lab will take a while, so please give it sufficient (wait) time.
We will need a VM with docker installed in it.  Follow steps in lab2 -- https://github.com/MIDS-scaling-up/coursework/tree/master/week2/labs/docker
if you don't have it running.
#### Creating a docker file for Darknet and Yolo
In this simple example, we will not be using CUDA / CUDNN -- although it would be highly preferred if we wanted to get serious with Yolo.  We
will just run it on the CPU.  Create an empty directory, e.g. "darknet" and then copy and paste this into your Dockerfile:
```
# FROM summit.hovitos.engineering/arm64/jetsontx2:cudnn
# FROM nvidia/cuda:8.0-cudnn5-devel
FROM ubuntu

MAINTAINER bmwshop@gmail.com

# this installs darknet: http://pjreddie.com/darknet/install/
# and then configures the tiny model for yolo

RUN apt-get update && apt-get install -y tzdata
RUN apt-get install -y git pkg-config wget unzip

RUN apt-get install -y libopencv-dev
WORKDIR /

RUN git clone https://github.com/pjreddie/darknet.git
WORKDIR /darknet

# COPY Makefile /darknet/Makefile


ENV PATH /usr/local/cuda/bin:$PATH
RUN make -j4

# RUN wget http://pjreddie.com/media/files/tiny-yolo.weights
# RUN wget http://pjreddie.com/media/files/tiny-yolo-voc.weights
# RUN wget http://pjreddie.com/media/files/yolo.weights

RUN wget https://pjreddie.com/media/files/yolov3.weights 
```
Save your Dockerfile and build the container:
```
docker build -t darknet .
```
If all went well, you should have your dockerfile eventually -- although this step will take a while.

Take a moment to find out the size of your docker image.  Do you still remember the command to do so?  If not, consult the lab from 
week 2.

#### Running Yolo

Now let's run your docker container:
```
docker run --rm -ti darknet bash
```
Once inside the container, let's run a few samples:
```
cd /darknet
./darknet detect cfg/yolov3.cfg yolov3.weights data/dog.jpg
./darknet detect cfg/yolov3.cfg yolo3.weights data/horses.jpg
./darknet detect cfg/yolov3.cfg yolo3.weights data/person.jpg
```
How long does it take to process one image? 

#### [Optional] Running Yolo on your laptop / desktop
If your local machine can run Docker, Yolo could be installed on your local machine -- will be reasonably fast, if you have a GPU.  If you have a webcam attached, then you should be able to run Yolo live.  It will try to open an x window, so ensure that you have your xhost + 
command issued.
```
docker run --name darknet -ti darknet bash

cd /darknet
./darknet detector demo cfg/coco.data cfg/yolov3.cfg yolov3.weights
```
What is the framerate printed in the termina window where you started Yolo from?

#### [Optional] Tiny Yolo
If you want to achieve maximum performance on your tiny IoT device, you may want to opt for Tiny Yolo instead. 
Tiny Yolo is a much simpler network and much faster as a consequence, but it is less accurate.

Spin up your docker container:
```
docker run --name darknet -ti darknet bash
cd /darknet
wget https://pjreddie.com/media/files/yolov3-tiny.weights
```
This will take a while.  Now run the detector again and observe the difference in performance:
```
./darknet detect cfg/yolov3-tiny.cfg yolov3-tiny.weights data/dog.jpg
./darknet detector demo cfg/coco.data cfg/yolov3-tiny.cfg yolov3-tiny.weights
```
What is the framerate printed in the main terminal window where you started Yolo?

Later in the class, we'll return to Yolo and run it on a GPU.
