####In this lab, we'll play with an alternative to scp / tcp

we assume that by this time, you have a pair of VMs separated by an ocean or two.  We also assume that you've tried to 
transfer a large file over.  If not, let's do so now, for instance

```
scp /root/googlebooks-eng-all-2gram-20090715-45.csv <far away VM>:/tmp
```
As scp runs, it'll report transfer speed.

Now, let's try installing UDT.  These instructions work with ubuntu
```
apt-get install -y libudt-dev
# Make sure you have g++ also installed eg
apt-get -y install g++ make
```

Now, it's time to download UDT from https://sourceforge.net/projects/udt/files/latest/download
untar / unzip the file, then
```
cd udt4
make -e ARCH=AMD64
make install
```
Assuming the compilation succeeded, we can now try to transfer some files!

On the machine where large files reside
```
cd udt4/app
./sendfile
# note the port that it comes up with, you'll need it
```
On the machine where you want to file to be transferred to
```
cd udt4/app
./recvfile remote_machine remote_port remotefile localfile
```

Is there a difference in speed between udt and scp?
