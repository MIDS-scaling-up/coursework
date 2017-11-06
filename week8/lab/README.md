# darknet dockerfile
[darknet](http://pjreddie.com/darknet/) is an open source neural network framework written in C and CUDA. This docker image (created by [loretoparisi](https://github.com/loretoparisi/docker/tree/master/darknet)) contains all the models you need to run darknet with the following neural networks and models

- [yolo](http://pjreddie.com/darknet/yolo/) real time object detection
- [imagenet](http://pjreddie.com/darknet/imagenet/) classification
- [nightmare](http://pjreddie.com/darknet/nightmare/) cnn inception
- [rnn](http://pjreddie.com/darknet/rnns-in-darknet/) Recurrent neural networks model for text prediction
- [darkgo](http://pjreddie.com/darknet/darkgo-go-in-darknet/) Go game play

## How to install Docker

We will be using Docker to run this lab. You will need a VM. Any VM will do, this will not affect your homeworks, but you can provision a fresh VM (2 cpu, 4GB ram, 100GB disk) if you wish. The steps below will install Docker CE on your VM.

```
sudo apt install -y python
sudo apt-get remove -y docker docker-engine docker.io
sudo apt-get -f install
sudo apt-get update
sudo apt-get install -y apt-transport-https     ca-certificates     curl     software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
sudo docker run hello-world
```

## How to build the Docker container
You can build build the docker image from the Dockerfile folder or from Docker repositories hub.

To pull the [darknet image](https://store.docker.com/community/images/loretoparisi/darknet) from the repo

```
docker pull loretoparisi/darknet
```

This will build all layers, cache each of them with a opportunist caching of git repositories for hunspell and dictionaries stable branches.

## INFORMATIONAL: How to build your own darknet container
If you want to play with darknet further, you can modify and build the container using the `Dockerfile` contained in the `cpu/` folder. Run:

```
git clone https://github.com/loretoparisi/docker.git
cd docker/darknet/cpu/
./build.sh
```

You can then run and enter the container by running
`./run.sh` in the same directory.

## How to test the docker image

Then to run the container in interactive mode (bash) do

```
docker run --rm -it --name darknet darknet bash
```

then you can perform some darknet tasks like

Run [yolo](http://pjreddie.com/darknet/yolo/)

```
cd darknet
./darknet detector test cfg/coco.data cfg/yolo.cfg /root/yolo.weights data/dog.jpg
layer     filters    size              input                output
    0 conv     32  3 x 3 / 1   416 x 416 x   3   ->   416 x 416 x  32
    1 max          2 x 2 / 2   416 x 416 x  32   ->   208 x 208 x  32
    2 conv     64  3 x 3 / 1   208 x 208 x  32   ->   208 x 208 x  64
    3 max          2 x 2 / 2   208 x 208 x  64   ->   104 x 104 x  64
    4 conv    128  3 x 3 / 1   104 x 104 x  64   ->   104 x 104 x 128
    5 conv     64  1 x 1 / 1   104 x 104 x 128   ->   104 x 104 x  64
    6 conv    128  3 x 3 / 1   104 x 104 x  64   ->   104 x 104 x 128
    7 max          2 x 2 / 2   104 x 104 x 128   ->    52 x  52 x 128
    8 conv    256  3 x 3 / 1    52 x  52 x 128   ->    52 x  52 x 256
    9 conv    128  1 x 1 / 1    52 x  52 x 256   ->    52 x  52 x 128
   10 conv    256  3 x 3 / 1    52 x  52 x 128   ->    52 x  52 x 256
   11 max          2 x 2 / 2    52 x  52 x 256   ->    26 x  26 x 256
   12 conv    512  3 x 3 / 1    26 x  26 x 256   ->    26 x  26 x 512
   13 conv    256  1 x 1 / 1    26 x  26 x 512   ->    26 x  26 x 256
   14 conv    512  3 x 3 / 1    26 x  26 x 256   ->    26 x  26 x 512
   15 conv    256  1 x 1 / 1    26 x  26 x 512   ->    26 x  26 x 256
   16 conv    512  3 x 3 / 1    26 x  26 x 256   ->    26 x  26 x 512
   17 max          2 x 2 / 2    26 x  26 x 512   ->    13 x  13 x 512
   18 conv   1024  3 x 3 / 1    13 x  13 x 512   ->    13 x  13 x1024
   19 conv    512  1 x 1 / 1    13 x  13 x1024   ->    13 x  13 x 512
   20 conv   1024  3 x 3 / 1    13 x  13 x 512   ->    13 x  13 x1024
   21 conv    512  1 x 1 / 1    13 x  13 x1024   ->    13 x  13 x 512
   22 conv   1024  3 x 3 / 1    13 x  13 x 512   ->    13 x  13 x1024
   23 conv   1024  3 x 3 / 1    13 x  13 x1024   ->    13 x  13 x1024
   24 conv   1024  3 x 3 / 1    13 x  13 x1024   ->    13 x  13 x1024
   25 route  16
   26 reorg              / 2    26 x  26 x 512   ->    13 x  13 x2048
   27 route  26 24
   28 conv   1024  3 x 3 / 1    13 x  13 x3072   ->    13 x  13 x1024
   29 conv    425  1 x 1 / 1    13 x  13 x1024   ->    13 x  13 x 425
   30 detection
Loading weights from /root/yolo.weights...Done!
data/dog.jpg: Predicted in 8.208007 seconds.
car: 54%
bicycle: 51%
dog: 56%
Not compiled with OpenCV, saving to predictions.png instead
```
You just analyzed an image (data/dog.jpg) and found a car, a bicyle, and a dog.

The pre-defined (and pre-trained) categories can be viewed in [the darknet github repo](https://github.com/pjreddie/darknet/blob/master/examples/yolo.c).

Run the [rnn](http://pjreddie.com/darknet/rnns-in-darknet/)

```
cd ./darknet/
./darknet rnn generate cfg/rnn.cfg /root/shakespeare.weights -srand 0 -seed CLEOPATRA -len 200 
rnn
layer     filters    size              input                output
    0 RNN Layer: 256 inputs, 1024 outputs
		connected                             256  ->  1024
		connected                            1024  ->  1024
		connected                            1024  ->  1024
    1 RNN Layer: 1024 inputs, 1024 outputs
		connected                            1024  ->  1024
		connected                            1024  ->  1024
		connected                            1024  ->  1024
    2 RNN Layer: 1024 inputs, 1024 outputs
		connected                            1024  ->  1024
		connected                            1024  ->  1024
		connected                            1024  ->  1024
    3 connected                            1024  ->   256
    4 softmax                                         256
    5 cost                                            256
Loading weights from /root/shakespeare.weights...Done!
CLEOPATRA. O, the Senate House?
    These haste doth bear the studiest dangerous weeds,
    Which never had more profitable mind,
    And yet most woeful note to you,
    That hang them in these worthiest serv
```

If you want to run darknet against your own images, you can put them into a directory on your VM and mount it into your container with:

```
docker run -v /directory/of/images:/pictures --rm -it --name darknet darknet bash
```

*(make sure to update the `directory/of/images` to point to a directory on your VM that actually contains images)*

Then you can re-run darknet:

```
cd darknet
./darknet detector test cfg/coco.data cfg/yolo.cfg /root/yolo.weights /pictures/your_picture.jpg
```
where you replace `your_picture.jpg` with your image name.
