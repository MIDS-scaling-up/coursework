#Assignment 3: MQTT processing

##Instructions
###MQTT 
MQTT - http://mqtt.org/ is a lightweight protocol for the Internet of Things.  Please spend some time to read up on it.  In your homework submission, please write a one liner about the QoS 0,1, and 2 that MQTT enables.

###Mosquitto
Perhaps the most popular MQTT broker is called Mosquitto.  Let's get one running.  You should already know how to provision a VM. Use this knowledge to spin up a VM with 2G of RAM, 2 vCPUs, and the latest Ubuntu on it.  Next, ssh into your new VM and install mosquitto-clients:
```
apt-get install mosquitto-clients
```
### Blue Horizon
Blue Horizon - http://bluehorizon.network - is our exprimental Internet of Things platform.


### Subscribing to messages on the development  Blue Horizon MQTT Cloud Broker
mosquitto_sub -t /applications/in/+/public/# -h 198.23.89.34
