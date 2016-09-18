#Assignment 3: Internet of Things 101 and MQTT processing

##Instructions
This homework should be pretty easy and consists mostly of reading. The concept of the Internet of Things deals with a large number of devices that communicate largely through messaging.

###MQTT 
MQTT - http://mqtt.org/ is a lightweight messaging protocol for the Internet of Things.  Please spend some time to read up on it.  In your homework submission, please write a one liner about the QoS 0,1, and 2 that MQTT enables.

###Mosquitto
Perhaps the most popular OpenSource MQTT toolkit is called Mosquitto.  Let's get it installed.  You should already know how to provision a VM. Use this knowledge to spin up a VM with 2G of RAM, 2 vCPUs, and the latest Ubuntu on it.  Next, ssh into your new VM and install mosquitto-clients:
```
apt-get update
apt-get install mosquitto-clients
```
### Blue Horizon
Blue Horizon - http://bluehorizon.network - is our exprimental decentralized distributed Internet of Things platform.  Please spend some time reading through the introduction. Notice that the participating devices continuously send data into the cloud portion of the project.  You are welcome to join the project as well although it's not required :-)  Please review the Ethereum white paper located at https://github.com/ethereum/wiki/wiki/White-Paper .  In a few sentences, how are block chains relevant for the Internet of Things?


### Subscribing to messages on the development  Blue Horizon MQTT Cloud Broker
At this point, we will use our new VM to subscribe to the public topic tree on the development MQTT bus of Blue Horizon:
```
mosquitto_sub -t /applications/in/+/public/# -h 198.23.89.34
```
In your homework submission, please explain what the + and # in the line above stand for, as well as provide a few lines of output that you see on screen.  Can you recognize some of the messages?  What is their meaning?

Credit / no credit, please submit prior to class 3
