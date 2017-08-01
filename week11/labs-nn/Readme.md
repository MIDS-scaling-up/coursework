### These labs focus on the basic aspects of Deep Learning.

#### 1. Classification of a 2D dataset using ConvnetJS
ConvnetJS is a very simple yet powerful JavaScript library for Convolutional Neural Networks created by Andrei Karpathy, previously a Graduate Student at Stanford (under Fei-Fei Li) 
and now the leader of the Autonomous Driving project at Tesla.  You can read more about ConvNetJs at http://cs.stanford.edu/people/karpathy/convnetjs/
Our first lab aligns with the 2D classification example available here: http://cs.stanford.edu/people/karpathy/convnetjs/demo/classify2d.html
Once you hit this page, the network starts running.  
* Add a few red dots in previously green areas by clicking the left mouse button.  Is the network able to adjust and correctly predict the color now?
* Add a few green dots in previously red areas by clicking the shift left mouse button.  Can the network adapt?
* Review the network structure in the text box.  Can you name the layers and explain what they do?
* Reduce the number of neurons in the conv layers and see how the network responds. Does it become less accurate?
* Increase the number of neurons and layers and cause an overfit.  Make sure you understand the concept
* Play with activation functions.. -- relu vs sigmoid vs tanh... Do you see a difference ? Relu is supposed to be faster but less accurate.
