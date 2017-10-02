### Text generation with Recurrent Neural Networks
In this lab, we are beginning to learn about Recurrent Neural Networks

#### Creating a docker container
As usual, to complete this exercise, we will need a VM or a local environment with Docker installed in it.  If you don't have docker installed, 
follow instructions in lab2 -- https://github.com/MIDS-scaling-up/coursework/tree/master/week2/labs/docker

We are assuming for now that you are not running this in a GPU'ed machine.  If you do, however, use the appropriate FROM statement below.

Create a new directory  -- e.g mkdir torchrnn && cd torchrnn and then create a file called Dockerfile with contents below:
```
FROM kaixhin/torch
# FROM kaixhin/cuda-torch

#  nvidia-docker run --name torch -p 5555:8080 -it kaixhin/cuda-torch bash

RUN apt-get update && apt-get install -y git wget ruby

RUN luarocks install https://raw.githubusercontent.com/benglard/htmlua/master/htmlua-scm-1.rockspec
RUN luarocks install https://raw.githubusercontent.com/benglard/waffle/master/waffle-scm-1.rockspec

WORKDIR /
RUN git clone https://github.com/robinsloan/torch-rnn-server
WORKDIR /torch-rnn-server/checkpoints
#RUN wget http://from.robinsloan.com/rnn-writer/scifi-model.zip
RUN wget http://169.44.201.108/GTC_2017/scifi-model.zip
RUN unzip scifi-model.zip
WORKDIR /torch-rnn-server

COPY server.lua /torch-rnn-server/
COPY sample.rb /torch-rnn-server/

# th server.lua
# ruby sample.rb "She was"

```

