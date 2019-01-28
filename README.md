# Sobr 
Created by Jason Chang, Tanner Hoke, Parsa Dastjerdi, Harish Kumar </br>
01.26.2019 - 01.27.2019 @ TAMUHack 2019 (3rd Place Finish)
<p align="center"><img src="https://github.com/jasonchang0/SoBr/blob/master/sobr-logo.png" height="200" width="200"></p>

## Inspiration

Sobr was inspired by the large amount of drunk driving accidents in the U.S. In 2017, there were 10,874 deaths due to drunk driving. Sobr aims to reduce this number by preventing intoxicated drivers from stepping behind the wheel to begin with and providing alternative methods of arriving home.


## What it does?

Sobr is intended to be an accompanying application for drivers to identify whether or not they are intoxicated before driving. It uses a combination of features detected through facial recognition to unlock the car, as long as the driver is classified as sober. If the driver is classified as intoxicated, a second (different) face must be provided to act as a designated driver.

## How we built it?

We began by scraping data off a dataset of pictures of human subjects before and after they had consumed alcohol. It was rather difficult to find quality datasets of this nature, and so, we had to make do with a small initial sample.

## Preprocessing Data
With small sample pool of images collected from 53 participants, we are asked to expand the datasets to avoid underfitting the data. First, we train a Haar Cascade Classifier to detect and extract facial features from the images. From there, we turned to image augmentation for machine learning experiments, based on which we write a script to arbitrarily apply 0, 1, or 2 special effects to the original 212 images. This technique of image augmentation allows us to generate a sample pool of 50,000, equally split between positive and negative samples.

## Research Problem
We treat this as a binary classification problem where we identify whether or not the subject in the image is inebriated. We use iOS’s Vision API to detect the most prominent face in the input image, crop the corresponding bounding box, and feed this as the input to all our trained ML models.

## Prediction System
The first half of our prediction architecture is an ensemble of deep convolutional neural networks trained on different randomly sampled subsets of the augmented dataset. We observed experimentally that using an ensemble produced a much more robust and reliable result as compared to what we obtained with a single neural network. Every neural net in the ensemble had the same architecture: We have four convolutional layers that use a 3x3 kernel, each followed by a max-pooling layer that subsamples in a 2x2 area with a 2x2 stride. We use relu activations throughout the network and a softmax activation on the last layer. We used cross entropy loss along with stochastic gradient descent to find optimal weights for the neural network. We used high-memory instances from Google Cloud Platform to train our models since we required significant amounts of RAM to do so. After training, we used CoreML’s keras-to-CoreML converter to transform our model to a format that can directly run on an iOS device.

Following through with our intention to build a voting classifier out of several different models, we built a classifier out of Microsoft Cognitive Services’ Custom Vision API on the augmented image dataset. We used the General(Compact) model type and used a probability cutoff that resulted in reasonable precision and recall values.

## Aggregated Classifiers
We took a simple majority vote out of all the different classifiers that we use. Because this is a binary classification problem and because we intentionally used an odd number of classifiers, there is no possibility of a tie. The input image is classified to contain an inebriated subject(or not) based upon whichever class secures the majority vote.

## Challenges We Ran Into
When augmenting our dataset, we took a single image that contained four separate images and split the image into four separate images. For each image, two of the images were classified as sober and two were classified as drunk. When doing this, two of the images were mixed, causing our data to be skewed when training our models. The odd thing was that it performed better with the incorrectly labelled data.

## Accomplishments that We're proud of
1. Sobr was able to correctly classify intoxicated faces at 90.68% on the validation set. We do not at present have a mechanism to measure the App’s performance, but it still performed relatively well in our subjective evaluation. Also, we were able to connect to the SmartCar API in order to send commands back and forth.

2. Our dataset contained just 212 images in total and we successfully trained a deep neural network that performs well on such a small dataset.

3. DNNs are notorious for overfitting in the presence of small datasets and we overcame this problem through rigorous data augmentation and ensembling several models.

4. We also achieved excellent performance on a challenging deep learning task that has not been explored at all by the community in less than 24 hours.

5. We built a complete, end-to-end iOS application that utilizes the ML models that we built.

## What We've learned
From the perspective of data engineering, we practiced expanding the sample pool with limited amount of public data available. In terms of data science, we obtained experience manually constructing comprehensive dataset from scratch and came to realize the precious value behind such establishment of such enormous datasets. Lastly, it was fascinating to become aware of how computer science can contribute to novelizing a traditional concept from the past to enable for infinite potential and efficacy well beyond the status quo.

## What's next for Sobr
For the next steps we would like to refine the model in order to provide more accurate results. Along with this, we would like to add more components to the entire system. For example, a camera could be added to the dashboard to insure that the driver of the vehicle is not intoxicated.

Built with GCP •	CoreML •	Swift •	Python •	Microsoft Custom Visioon •	Keras •	Tensorflow

Try it out on [GitHub](https://github.com/jasonchang0/SoBr)

Watch our [demo](https://www.youtube.com/watch?v=ReqAQ463QmY)

Snapshots
[Fig.1] (http://d.pr/i/mTuUeq)
[Fig.2] (http://d.pr/i/S62gkz)
[Fig.3] (http://d.pr/i/9YqeYT)
[Fig.4] (http://d.pr/i/Way2j2)
[Fig.5] (http://d.pr/i/kcssjt)
[Fig.6] (http://d.pr/i/ZlaQEY)


## References
1. Hermosilla, Gabriel, et al. “Face Recognition and Drunk Classification Using Infrared Face Images.” Journal of Sensors, 2018, doi:10.1155/2018/5813514.
2. Koukiou, G., and V. Anastassopoulos. “Drunk Person Identification Using Local Difference Patterns.” 2016 IEEE International Conference on Imaging Systems and Techniques (IST), 2016, pp. 401–05. IEEE Xplore, doi:10.1109/IST.2016.7738259.
3. Yadav, Devendra Pratap, and Abhinav Dhall. “DIF : Dataset of Intoxicated Faces for Drunk Person Identification.” ArXiv:1805.10030 [Cs], May 2018. arXiv.org, http://arxiv.org/abs/1805.10030.
