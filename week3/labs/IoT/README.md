### Event driven processing for the Internet of Things
This lab builds upon the homework and introduces some of the tools in use today 
for Internet of Things processing

####Getting the MQTT broker running
Let us reconnect to the VM we created for the homework.  We installed mosquitto clients but this time, let
us install the mosquitto broker as well
```
apt-get install mosquitto
```
Notice that mosquitto clients and the broker itself are extremely lightweight, the total install size is just a few MB.
Now, let us start mosquitto in daemon mode
```
mosquitto -d
```
The default MQTT port is 1883. If you prefer to change this port, just use the -p option in your command lines throughout.
Let us set up a simple listener on our newly created MQTT broker:
```
mosquitto_sub -t test -h localhost -p 1883 &
```
This command will run in the background and print the messages received on the topic called "test".
Now, let us publish a message to this topic:
```
mosquitto_pub -t test -h localhost -p 1883 -m "hello world"
```
You should see the message printed below, e.g.
```
1464024282: New connection from 127.0.0.1.
1464024282: New client connected from 127.0.0.1 as mosq_pub_5063_slapi.
hello world
```
As you can see, it is incredibly easy to get started with MQTT. The tools are lightweight and easy to understand. Mosquitto can 
process thousands of messages per second; and if you need more scalability, you could use a HiveMQ or VerneMQ cluster.

Now, let us create a test endpoint that will imitate a temperature sensor. Create a file called temp_sensor.sh and add these lines:
```
#!/bin/bash

while [ true ]
do
  temp=10
  echo {"temp": $temp}
  sleep 0.3
done
```
Don't forget to make the file runnable
```
chmod a+x temp_sensor.sh
```
mosquitto_pub will terminate its connection to the broker after each message is published unless you ask it not to.  
The -l option below will keep the connection open:
```
./temp_sensor.sh | mosquitto_pub -l -h localhost -p 1883 -t test
```
You should see our imitated sensor sending data!  Once you have verified that everything works, Control-C the script.

Let us also kill the background listener:
```
fg
Control-C
```
**Quick Assignment:** modify the above script so that it emits the temperature of 20 with the probability of about 10% . Verify
that it works.

####Connecting to the IBM Internet of Things Foundation
It is totally fine to play with a standalone MQTT bus, but we want jetpacks!  Let's connect to IBM's hosted IOT foundation 
system.  It is fairly representative of the state of the industry in that it provides a hosted MQTT broker 
plus a useful structure for working with devices and gateways.

Create an Internet of things platform starter app on Bluemix
The starter application can be done with
https://console.ng.bluemix.net/docs/services/IoT/index.html#gettingstartedtemplate

Finally register the planned device with the Bluemix App:

https://console.ng.bluemix.net/docs/services/IoT/index.html#iot170

#####Adding a new device
Click "add device" and when prompted, create a new device type called "temp_sensor" with no metadata.  then, create a new device
and give it a name.  I named mine "bernie".  At this point, you will be presented with the credentials that you can use to connect to your new device e.g.
```
Organization ID qlsgr4
Device Type temp_sensor
Device ID bernie
Authentication Method token
Authentication Token Zj)Ogh616VfODFdae+
```
go to the devices dash and check on the health of your device:
```
https://yourorg.internetofthings.ibmcloud.com/dashboard/#/devices/browse
```
Now, let us publish a hello universe message to our device input topic.  Let us agree to call our application "temp_filter" - see how it enters the topic we are using:
```
mosquitto_pub -m "hello universe" -h qlsgr4.messaging.internetofthings.ibmcloud.com -p 1883 -t iot-2/evt/temp_filter/fmt/json -u use-token-auth -P "Zj)Ogh616VfODFdae+" -i d:qlsgr4:temp_sensor:bernie
```
**Quick Assignment:** modify the above script to send to this topic in a loop and start it.
Your device now should appear online and you should see its data coming in.

####Creating a NodeRed application
Now, let us create a visual event-driven application that can consume this data and do something with it.
first let us set up our node red environment.

Steps are documented in this recipe
https://console.ng.bluemix.net/docs/services/IoT/nodereddevice_sample.html#devices

Please notice the node-RED Flow data implementation to use is:
http://bh.mybluemix.net/red/#



