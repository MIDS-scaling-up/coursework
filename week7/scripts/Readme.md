# Data transfer scripts

requirements: slcli, swift cli
```
pip install softlayer
pip install python-swiftclient
```

The idea is to add the upload.sh script to crontab 
```
crontab -e
# then add this line
0,10,20,30,40,50 * * * * /somepath/upload.sh
```
The upload script will call sw_upload.sh which will scan the configured directory for MP4 files and upload them to Swift.
Just edit the connectivity information for Swift as well as the path to the directory where your files are located
