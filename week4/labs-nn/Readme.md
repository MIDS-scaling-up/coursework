### Text generation with Recurrent Neural Networks
In this lab, we are beginning to learn about Recurrent Neural Networks.

We will use the code from the links below with some minor modification.  Feel free to go over these time permitting:
https://github.com/robinsloan/torch-rnn-server
https://www.robinsloan.com/notes/writing-with-the-machine

And of course, this work -- and many others -- were inspired by the wonderful blog entry from Andrej Karpathy:
http://karpathy.github.io/2015/05/21/rnn-effectiveness/

#### Creating a docker container
As usual, to complete this exercise, we will need a VM or a local environment with Docker installed in it.  If you don't have docker installed, 
follow instructions in lab2 -- https://github.com/MIDS-scaling-up/coursework/tree/master/week2/labs/docker

We are assuming for now that you are not running this in a GPU'ed machine.  If you do, however, use the appropriate FROM statement below.

Create a new directory  -- e.g mkdir torchrnn && cd torchrnn and then create a file called Dockerfile with contents below:
```
apt-get update && apt-get install -y git
git clone https://github.com/MIDS-scaling-up/coursework.git
cd coursework/week4/labs-nn
docker build -t torchrnn
docker run --name torchrnn -ti torchrnn bash
# if your machine has nvidia-docker and cuda installed, do this instead:
# cp Dockerfile.cuda Dockerfile
# docker build -t torchrnn
# nvidia-docker run --name torchrnn -ti torchrnn bash
```

Assuming your container starts with no issues, let's generate some text!
```
ruby sample.rb "She was"
```

We also have a hosted version of this on a GPU server.  Try pasting this URL into your browser:

http://169.44.201.108:5555/generate?start_text=star&n=5

Or, play with an auto-complete page here:

http://169.44.201.108/au/


