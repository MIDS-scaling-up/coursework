### Using Spark with Intel BigDL
In this lab, we are experimenting with [Intel's BigD]
(https://github.com/intel-analytics/BigDL), a distributed Deep Learning framework developed specifically for Intel hardware

We will use the code from the link below with some minor modification.  Feel free to go over it time permitting:
https://bigdl-project.github.io/0.2.0/#PythonUserGuide/python-examples/

### Installing BigDL
Download and install BigDL on the master node
```
# on the master node only
cd /usr/local
mkdir -m 777 bigdl
cd bigdl
wget https://oss.sonatype.org/content/groups/public/com/intel/analytics/bigdl/dist-spark-1.6.2-scala-2.10.5-linux64/0.3.0-SNAPSHOT/dist-spark-1.6.2-scala-2.10.5-linux64-0.3.0-20171016.200700-73-dist.zip
unzip *.zip
rm *.zip
```
Now, propagate this directory to other nodes
```
# repeat for all slave nodes
cd /usr/local
rsync -avz bigdl spark2:/usr/local
rsync -avz bigdl spark3:/usr/local
```
### Validating the install
To get a python shell with BigDL you do this:
```
export BIGDL_HOME=/usr/local/bigdl
cd $BIGDL_HOME/lib
BIGDL_VERSION=0.3.0-SNAPSHOT
${SPARK_HOME}/bin/pyspark --master local[2] \
--conf spark.driver.extraClassPath=bigdl-SPARK_1.6-${BIGDL_VERSION}-jar-with-dependencies.jar \
--py-files bigdl-${BIGDL_VERSION}-python-api.zip \
--properties-file ../conf/spark-bigdl.conf
```
Assuming it started with no errors, see if you can create a basic linear layer:
```
from bigdl.util.common import *
from pyspark import SparkContext
from bigdl.nn.layer import *
import bigdl.version

# create sparkcontext with bigdl configuration
sc = SparkContext.getOrCreate(conf=create_spark_conf()) 
init_engine() # prepare the bigdl environment 
bigdl.version.__version__ # Get the current BigDL version
linear = Linear(2, 3) # Try to create a Linear layer
```
### Training LeNet
LeNet is a classic neural network developed in the late 90's to classify handwritten digits


