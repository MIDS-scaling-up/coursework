# Lab: Preprocess 2-gram data for Mumbler

### Preconditions
This lab assumes you have a Hadoop cluster set up **and** that you've completed the Lab [Load Google 2-gram dataset into HDFS](../hdfs_2gram_data_load/README.md).

## Part 1: Create a data-filtering map script

In `/home/hadoop`, write the __map__ function to filter the 2-gram dataset stored in HDFS:

    cat <<\EOF > mapper.py
    #!/usr/bin/python2

    import sys

    lastword = "";
    lastwc = 0;

    for line in sys.stdin:

            a = line.split( );
            if len(a) < 4:
                    continue;

            word1= a[0]
            word2= a[1]
            if not a[0].isalpha():
                    continue;

            if not a[1].isalpha():
                    continue;

            word = a[0] + " " + a[1];
            try:
                    n = int(a[3]);
            except ValueError:
                    continue;
            print word, "\t", n
    EOF

This step merely filters non-alphanumeric words from lines of data.

Finally set the permissions:

    chmod ugo+rx reducer.py

## Part 2: Create a reducer script

After the map step is complete, lines of the 2-gram dataset look something like this:

    food     tastes    32
    food     tastes    330
    food     tastes    1
    food     is        551
    food     is        26

A mumbler algorithm cares about the total number of occurrences of the word "tastes" following the word "food", but the fact that this information spans multiple lines is an unnecessary vestige of the original data's more information-rich format. For performance, we're best off pre-processing such data so that it's compacted like this:

    food     tastes    363
    food     is        577

To accomplish this, we'll apply the following function in Hadoop's __reduce__ step:

    cat <<\EOF > reducer.py
    #!/usr/bin/python

    import sys

    lastword = "";
    lastwc = 0;
    for line in sys.stdin:
            a = line.split( );
            if len(a) < 2:
                    continue;

            word = a[0] + " " + a[1];
            try:
                    n = int(a[2]);
            except ValueError:
                    continue;

            if word == lastword:
                    lastwc = lastwc + n;
            else:
                    if lastwc > 0:
                            print lastword, lastwc
                    lastword = word;
                    lastwc = n;


    if lastwc > 0:
            print lastword, lastwc
    EOF

Again, set the permissions:

    chmod ugo+rx reducer.py

# Part 3: Run the map, reduce scripts with Hadoop

Note that this will take a while. Note also that this assumes you're using Hadoop v1; if you're using Hadoop v2, substitute the following jar path: `/usr/local/hadoop/share/hadoop/tools/lib/hadoop-streaming-2.6.0.jar`:

    hadoop jar /usr/local/hadoop/contrib/streaming/hadoop-streaming-1.2.1.jar -D mapred.reduce.tasks=6 \
    -D mapred.output.compress=true -D mapred.compress.map.output=true -input /mumbler/pass \
    -output /mumbler/results -mapper mapper.py -reducer reducer.py \
    -file /home/hadoop/mapper.py -file /home/hadoop/reducer.py
