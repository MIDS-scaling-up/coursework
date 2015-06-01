# Homework: Part 2 - The Mumbler 

## Markov chain text generator application.  

_Note: Remember to back up your code in order to prevent losing work. A simple method might be to develop locally and push to test, or to pull periodically._

The idea of this very simple exercise is to understand and play with data to compute affinity.
Oftentimes fundamental issues are lost in complexity, so here are considering a trivial example that in 
practice could be scaled to hundreds or thousands of nodes and requires no map-reduce or any 
complicated scheduler.

First, we assume that you have a GPFS FPO cluster configured with write affinity and replication=1 
(meaning no data replication, writes will be attempted local).  Metadata will be replicated and that’s ok.
You’ll need to write a couple of scripts to download the google two-gram 27G data set - English version 20090715, 
further down the page - from here: http://storage.googleapis.com/books/ngrams/books/datasetsv2.html.
_Note: considering the above, it does make a difference FROM WHERE you are downloading the data set._

![Google data set][googledata]

Since GPFS FPO is not replicated, each file will be placed on one of the nodes.  Make sure you 
understand where each file is placed and control this placement.  The same goes for uncompressing 
(unzipping) the fragments.  Make sure you run the unzip on the node where you want to resulting file to 
reside :)

The structure of the google ngram dataset is as follows:

    ngram TAB year TAB match_count TAB page_count TAB volume_count NEWLINE

For instance (from a real data set):

    financial analysis       2000    3       3       1
    financial analysis       2002    2       2       1
    financial analysis       2004    1       1       1
    financial analysis       2005    4       4       3
    financial analysis       2006    10      10      7
    financial analysis       2007    47      37      17
    financial analysis       2008    63      54      31
    financial capacity       1899    1       1       1
    financial capacity       1997    2       2       2
    financial capacity       1998    4       4       2
    financial capacity       1999    3       3       3
    financial capacity       2000    4       2       2
    financial capacity       2003    1       1       1
    financial capacity       2004    4       4       3
    financial capacity       2005    2       2       2
    financial capacity       2006    2       2       2
    financial capacity       2007    26      24      17
    financial capacity       2008    26      25      19
    financial straits        1998    2       2       2
    financial straits        1999    1       1       1
    financial straits        2000    1       1       1
    financial straits        2002    3       3       3
    financial straits        2004    1       1       1
    financial straits        2005    6       6       6
    financial straits        2006    8       8       6
    financial straits        2007    8       8       8
    financial straits        2008    23      23      20


In this example, there are three two-grams that start with the word ‘financial’: financial analysis, 
financial capacity, financial straights.

Your goal is two write the mumbler application, in any language you choose, as follows:

It should take two parameters:

    mumbler <starting word> <max number of words>

Let’s say the starting word is “financial”.  The mumber needs to look up all n-grams that start with 
“financial”.  We see them above, there are three in total.  Then, it needs to select one of them randomly 
with a weight equal to its relative occurrence across all years, e.g.

Picking financial straits = number of times financial straits occurred / number of times all n-grams that 
start with financial occurred across all years.  In this case, there are total 258 n-gram occurrences that 
start with ‘financial’ , and there are 53 occurrences of “financial straits”.  So, the mumbler should pick 
the word “straits” with the probability of 53/258, and the word “capacity” with the probability of 75/258 
and the word “analysis” , 130/258.

Let’s say, the mumbler picks "straits".  Now, it becomes the starting n-gram word.  Now, it needs to 
evaluate all two-grams that start with "straits" and select the next word.

The process is repeated until either there is no two-gram that starts with that words or the length of the 
mumble is exhausted.

The trick is to write the mumbler in such a way that the amount of network traffic is minimized.
We ask that you install nmon (http://sourceforge.net/projects/nmon/files/nmon_linux_x86_64/download)
and use it to see how much network traffic you generate as you run the mumbler.  If you write it well, the 
amount of network traffic will be small as it is running.

Think about the fact that your 27G data set does not fit on any individual node, so it will be split 
between the three nodes in GPFS even if you don’t use the write affinity to distribute the data set.
Knowing where each file is, however, should enable you to move compute (as part of your mumbler) to 
the data and minimize network chatter.

## Submission

By submission time you should have the program described above 'mumbler' which can perform the task of walking the n-gram dataset according to the probabilities associated with each word.

Please submit:

 * Your login information for the cluster (you can obtain the root password for us with slcli vs list and slcli vs detail --passwords, or in the softlayer portal at control.softlayer.com)
 * Pointers for the grader about where the mumbler script is and how to run it  

## Grade scale

 * **50%** - GPFS installation
 * **25%** - A running mumbler
 * **25%** - Quality score

## Extra credit

10% Extra credit will be given for preprocessing input files to speed up the runtime of the text generator/mumbler command.

[googledata]: ./google_data_set.png
