# Lab 1 - evaluating GPFS performance on local writes vs direct writes to a local disk

For this simple test, we'll use the standard 'dd' command - see below - to take data from the unix /dev/zero device and write it to disk in a given location and a given block size.
Please try block sizes of 1k, 4k, 16k, 32k, 64k, 1m, 128m and repeat this test in /tmp and /gpfs/gpfsfpo (mounted gpfs directory).

The count parameter could be lowered with larger block sizes so that the tests would not take that long

```
dd bs=$blocksize count=1024 if=/dev/zero of=test oflag=dsync
```


What do you observe?
