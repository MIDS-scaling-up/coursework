# Lab: Rsync Investigation

## Preconditions

This lab assumes you have two VSes to perform data transfers with. If you do not, follow the instructions in [Data Transfer Performance](../data_xfer_perf).

In this lab, `rsync` and `scp` are used, and both use SSH for transport. Ensure that you can SSH between test systems without using passwords.

### Install unzip

    yum install -y unzip

### Fetch sample data set

Fetch some Google 2-mer files, decompress them, and create a large concatenation of them:

    for i in {0..3}; do wget http://storage.googleapis.com/books/ngrams/books/googlebooks-eng-all-2gram-20090715-${i}.csv.zip; unzip -p *${i}.csv.zip >> 2gram_concat.csv; \rm *${i}.csv.zip; done

Observe that the Indominus Rex you've created is a  GB file:

    ls -lh 2gram_concat.csv

    -rw-r--r--   1 root root 6.3G Jun 14 11:17 2gram_concat.csv

Ask yourself, how might you transfer this file to another VS? Try `scp` and evaluate its performance. How long will it take to transfer the file?

## Working with Rsync

### Install rsync

    yum install -y rsync

As an alternative to `scp`, you can try `rsync` (type `man rsync` to access the manual pages for the program). A simple invocation of `rsync` that **pushes** a file to a remote system has the following form:

    rsync --stats --progress <path_to_source_file> <remote_system_name_or_ip>:<path>

Use this form to initiate a push of `2gram_concat.csv` to your second VS, specifying `/root/` as the destination directory. Note the transfer speed. This isn't very fast, how can you improve the transfer speed?

Once you've found a way to speed up the transfer and successfully transferred the file to your second VS, modify the file on the **destination** like this:

    ssh <secondary_vs> "echo 'abc' >> /root/2gram_concat.csv"

The content of the file on the destination system is now different than the content of the file on the source system. How might you use `rsync` to repair the file without transferring all of its content?
