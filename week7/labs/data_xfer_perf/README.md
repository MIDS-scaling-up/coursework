# Lab: Data Transfer Performance

## Overview

## Part 1: Provision and Configure VSes

Provision two Ubuntu VSes, one in a datacenter in the US and one in a datacenter far away—London, Amsterdam, Singapore, Hong Kong, Australia, or another. Please choose different source and destination datacenters from other groups in your section.

Each VS must have 1gb public **and** private virtual nics. Configure an SSH key when you provision for easier management. Other VS configuration details are up to you.

Set up key-based SSH authentication to VSes.

### Install iperf
Assuming you've spun up Ubuntu VMs, you can do

    apt-get install iperf
Otherwise, if you are on RHEL or Centos:

    yum install epel-release
    yum install iperf

### Configure VLAN spanning and test private networking

Private network traffic between VSes in SoftLayer is free so we'll prefer using that to public traffic for these tests. In order to create a private network between two VSes, enable VLAN spanning. You can do this through the SoftLayer portal at https://control.softlayer.com. Browse to Network > IP Management > VLANs and select the "Span" tab in the upper-right corner. Click the "On" radio button to enable spanning.

Modify `/etc/hosts` on both systems: ensure there is an entry for **each** system that maps its private IP address (the one on the 10.x.x.x network) to the hostname for the system. You may wish to comment out the public IP address so there is no confusion.  Here’s an example of mine:

    127.0.0.1           localhost.localdomain localhost
    # 169.54.196.228    Dallas-DataXfer.peterr.com Dal-DataXfer
    10.121.154.4        Dallas-DataXfer.peterr.com dal-dataxfer
    10.67.63.26         Singapore-DataXfer.peterr.com sng-dataxfer

Check connectivity between systems with `ping`.

On one of the systems, start the iperf server:

    iperf -s

You should see output like this:

    ------------------------------------------------------------
    Server listening on TCP port 5001
    TCP window size: 85.3 KByte (default)
    ------------------------------------------------------------

## Part 2: Perform transfer tests

### iperf introduction

At the end of part 1, you started an iperf server on one of your systems. On the other of your two systems, use the iperf tool to connect to that server and perform a simple data transfer performance test and evaluate the output (note that this assumes the hostname of the listening server is `dal-dataxfer`):

    root@SNG-DataXfer:~# iperf -c dal-dataxfer

    ------------------------------------------------------------
    Client connecting to dal-dataxfer, TCP port 5001
    TCP window size: 23.5 KByte (default)
    ------------------------------------------------------------
    [  3] local 10.67.63.26 port 51449 connected with 10.121.154.4 port 5001
    [ ID] Interval       Transfer     Bandwidth
    [  3]  0.0-10.9 sec  78.0 MBytes  59.8 Mbits/sec

This test used a single thread, it opened a socket to the server over port 5001 and tested throughput (note that this test only involves network equipment speed, it doesn't test computation speed and it doesn't use any storage systems).

Browse to the iperf website, https://iperf.fr, and learn about the tool's features.

### iperf transfer tests

Using the iperf tool, perform transfer performance tests and record your results with `1`, `3`, `5`, `10`, `20`, `50`, and `100` concurrent threads. Of specific interest in the output is the `[SUM]` line: this is a calculation of data throughput among all threads. Your iperf invocation will look something like this:

    iperf -c <server-hostname> -P n
