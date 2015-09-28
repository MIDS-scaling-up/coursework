# Lab: Preprocess 2-gram data for Mumbler

### Preconditions
This lab assumes you have a Hadoop cluster set up **and** that you've completed the Lab [Load Google 2-gram dataset into HDFS](../hdfs_2gram_data_load/README.md).

## Part 1: Create a data-filtering map script

In `/home/hadoop`, write the __mapper__ function to filter the 2-gram dataset stored in HDFS:

    cat <<\EOF > mapper-filter.py
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
            if not a[0].isalpha() or not a[1].isalpha():
                    continue;

            word = a[0] + " " + a[1];
            try:
                    n = int(a[3]);
            except ValueError:
                    continue;
            print word, "\t", n
    EOF

This step merely filters non-alphanumeric words from lines of data.

Finally set the permissions and copy the file into HDFS:

    chmod ugo+rx mapper-filter.py
    hadoop fs -cp file:///home/hadoop/mapper-filter.py hdfs:///mumbler

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
    #!/usr/bin/python2

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

Again, set the permissions and copy the script into HDFS:

    chmod ugo+rx reducer.py
    hadoop fs -cp file:///home/hadoop/reducer.py hdfs:///mumbler

# Part 3: Execute Mumbler data pre-processing job

Execute the __mapper__ and __reducer__ scripts on the Google 2gram data written to HDFS previously (note, this will take a significant amount of time to complete):

    hadoop jar $(ls $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-*.jar) \
    -Dmapreduce.job.reduces=6 \
    -Dmapreduce.output.fileoutputformat.compress=true \
    -Dmapreduce.map.output.compress=true \
    -files hdfs:///mumbler/mapper-filter.py,hdfs:///mumbler/reducer.py \
    -input hdfs:///mumbler/pass \
    -output hdfs:///mumbler/results \
    -mapper mapper-filter.py \
    -reducer reducer.py

## Part 4: Investigate results

You can view the compressed output of the reduce operation with hadoop commands like this:

    hadoop fs -text hdfs:///mumbler/results/part-00000.deflate
