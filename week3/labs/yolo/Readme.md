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

RUN apt-get update && apt-get install -y git pkg-config wget unzip

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

RUN mkdir /coco
RUN cp /darknet/scripts/get_coco_dataset.sh /coco
WORKDIR /coco
RUN bash /coco/get_coco_dataset.sh
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
./darknet detect cfg/yolo.cfg yolo.weights data/dog.jpg
./darknet detect cfg/yolo.cfg yolo.weights data/horses.jpg
./darknet detect cfg/yolo.cfg yolo.weights data/person.jpg
```

Yolo can be installed on your local machine -- e.g. Macbook -- and will be reasonably fast, especially if you have a GPU.
if you have a webcam attached, then you should be able to run Yolo live.  IT will try to open an x window, so ensure that you have your xhost + 
command issued.
```
./darknet detector demo cfg/coco.data cfg/yolo.cfg yolo.weights
```

#### Tiny Yolo
If you want to achieve maximum performance on your tiny IoT device, you may want to opt for Tiny Yolo instead. 
Tiny Yolo is a much simpler network and much faster as a consequence, but it is less accurate.

Spin up your docker container:
```
docker run --name darknet -ti darknet bash
cd /darknet
wget https://pjreddie.com/media/files/tiny-yolo-voc.weights
```
This will take a while.  Now run the detector again and observe the difference in performance:
```
./darknet detector test cfg/voc.data cfg/tiny-yolo-voc.cfg tiny-yolo-voc.weights data/dog.jpg
```
Later in the class, we'll return to Yolo and run it on a GPU
