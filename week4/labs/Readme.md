# Lab 1 - evaluating GPFS performance on FS writes vs direct writes to a local disk

For this simple test, we'll use the standard 'dd' command - see below - to take data from the unix /dev/zero device and write it to disk in a given location and a given block size.
Please try block sizes of 1k, 4k, 16k, 32k, 64k, 1m, 128m and repeat this test in /tmp and /gpfs/gpfsfpo (mounted gpfs directory).

The count parameter could be lowered with larger block sizes so that the tests would not take that long

```
dd bs=$blocksize count=1024 if=/dev/zero of=test oflag=dsync
```
Note that the 'dsync' flag means 'direct and sync' and attempts to override any caching

What do you observe?

# Lab 2 - evaluating GPFS performance on local vs remote reads
For this lab, make sure that you have [nmon](http://sourceforge.net/projects/nmon/files/nmon_linux_x86_64/download) installed on your gpfs nodes.

In your GPFS installation, create three subdirectories: gpfs1, gpfs2, and gpfs3

Now log into (ssh) the gpfs1 node, cd to your gpfs1 subdirectory and download one of the google 2-gram files, e.g.
```
wget http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-0.csv.zip
```
Next, log into the gpfs2 node, cd to your gpfs2 subdirecttory, and download another 2-gram file, e.g.
```
wget http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-40.csv.zip
```
Do the same for gpfs node3, e.g. 
```
wget http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-70.csv.zip
```
Go back to gpfs1. Fire up nmon, pressing "c" and "n" to get CPU and network statistics.  Now, replacing $word and $file below with some word you want to search for and one of your downloaded file, run the command below.  
```
time zgrep -h "^$word [A-Za-z]\+" $file
```
Run this for a file located on gpfs1 and also for remote files.  Watch for the CPU and network utilization in nmon.  What do you observe?  Compare to the screenshot below:
![nmon screenshot][nmon]
[nmon!](nmon.png)
