FROM kaixhin/cuda-torch

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

COPY server-cuda.lua /torch-rnn-server/server.lua
COPY sample.rb /torch-rnn-server/

# th server.lua
# ruby sample.rb "She was"
