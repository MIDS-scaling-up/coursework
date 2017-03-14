### Digits 5 and Image Classification with Transfer Learni ng

Intro

Digits is currently one of the leading tools to easily train and run neural nets. It supports Caffe and Torch and is in furious development. Note that the production branch is 4 while the dev branch with a lot more features is 5.

#### The training set

We prepared an image dataset, it is located here: http://169.50.131.114:7002/tset/ Please take a few minutes to aquaint yourself with it. As you can see, the structure is simple: there is a bunch of directories which correspond to class names, with images underneath that correspond to that class. Note that some directories are empty, and that's OK. Many public data sets share the same structure.

This particular training set is generated via this GUI: http://169.50.131.114:7002/index.html?c=11071917_foo This is an experimental project around the surveillance use case. If motion is detected, a simple algorithm localizes it in the frame (draws a bounding box around it) and sends it over to the cloud for manual annotation. Once you have annotated the bounding box, it is added to the training set.

#### Importing the training set into DIGITS 
Access DIGITS 5.1 at http://169.50.131.114:5001/ 
Make sure you are on the DataSets tab. Click on the new data set icon on the right, choose Images -> Classification. Choose Fill as your resize transformation. Select a name for your group name and data set. Set minimum samples per class to 10. Set the URL for the training images to http://169.50.131.114:7002/tset/ and click Create at the bottom.

#### Training a GoogleNet-based model using transfer learning 
Click on the Models tab and choose New model - > classification. Choose your newly created data set on the left. Select the "custom network" tab. At the bottom, in the pre-trained network field, type "/data/bvlc_googlenet.caffemodel". Leave the number of GPUs used at 1. Use the same group name as you used previously for your data set and select a name for your model. In the Custom Network field paste the model from this link. This is a model with fixed lower layers. Click Create. How long does it take for the model to exceed 90% accuracy?

#### Training a GoogleNet-based model using transfer learning with unfixed lower layer weights 
Let us repeat the previous steps, but now let us use a network from this link. the only difference is that we unfixed the lower layers. Now, how long does it take for the model to reach 90% accuracy?

#### Training a GoogleNet-based model from random weights. 
Let's repeat the previous step using the same custom model but this time, let us clear out the "pre-trained model" field. Now, how long does it take for the model to reach 90% accuracy?

#### Applying the model to classification 
From the DIGITS homepage, select one of your trained models. At the bottom of the page, under Test a Single Image, pick an image -- e.g. from a path beginning with /data/eye/classes/ (the system will pre-fill / show names of existing dirs and files). Feel free to upload your own file. Check the "show visualizations and statistics" checkbox and click "Classify One"

e some of the work already: the ./prepare_kitti_data.py script has already been run; you need to pick up from there.

The object detection example files are located under /data/DIGITS/examples/object-detection

http://169.50.131.107:5000/ is the URL to access our server running a docker container with DIGITS inside.

We suggest that you form groups; and each group can practice independently creating their own data sets and models with unique names.
