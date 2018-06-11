# Trip-Signal-Matching


### Overall Goal 
Given a set of mobile phone sensor datasets and a set of OBDII sensor datasets, figure out which mobile phone trip dataset correspond to which OBDII trip dataset. 

### Datasets Description
*	obd2Trips.RData is a list containing a data frame of vehicle speed data for each trip collected from the OBDII plug-in device; For each trip in this dataset: 
  *	It contains columns: trip_id, timestamp, and speed
  *	Its length is not necessarily equal to other obd trips (and mobile trips)
*	mobileTrips.RData is a list containing a data frame of smartphone speed data for each trip collected from the phone; For each trip in this dataset:
  *	It contains columns: trip_id, created_at, timestamp, speed and accuracy
  *	Its length is not necessarily equal to other mobile trips (and obd trips)

### Observations and Assumptions
*	The trip_id column is present in both datasets, but their naming has nothing in common; therefore, it is not considered when building the model
*	The created_at column in the mobile trip dataset shows the timestamp when the trip is created, however, similar information is not available in the obd trip dataset. Therefore, it is not considered when building the model
*	The timestamp column is present in both datasets, both with the unit of (epoch) second. However, their scales are very different (one in absolute scale, the other in a relative scale). But the interval between each observation is roughly 1 second for both datasets. Therefore, the assumption I have made is that each trip starts at time zero and the observations were made at every one second 
*	The accuracy column is only present in mobile trip datasets, which has the unit of meters. The larger the x, the less reliable the speed measurement. 

### Explanatory Data Analysis
The first four trips from mobile datasets are visualized:

![first_four_mobile_trip](https://user-images.githubusercontent.com/33201700/41252451-2ec29988-6d8b-11e8-888f-9631f91b138e.png)

The first four trips from obd datasets are visualized:

![first_four_obd_trip](https://user-images.githubusercontent.com/33201700/41252456-333b34ca-6d8b-11e8-888d-0146c437e86f.png)

From these plots, it can be inferred that the time series are not stationary, rendering most techniques not applicable. Therefore, first-differencing technique is used to stabilize the time series. The function in the code calculates the speed difference between the t-th and (t+1)-th timestamp and creates a diff column in each dataset. 

The following figures show the results after the first-differencing:

![first_four_mobile_diff](https://user-images.githubusercontent.com/33201700/41252463-38ccdd44-6d8b-11e8-96ad-c81d563c4f30.png)

![first_four_obd_diff](https://user-images.githubusercontent.com/33201700/41252469-3ca0cd7c-6d8b-11e8-8631-f84cd607f26e.png)

After the first differencing, it can be observed that the time series are roughly stabilized. 

### Potential Approaches at First Thought
*	Extract features from time series (i.e. transform the time series to a feature space), then do a similarity analysis in the feature space. A potential way is to derive the power spectrum to find dominant frequencies of each trip and use those as features
*	Use cross correlation to align signals and find the similarities between the signals

### Actions Taken
#### Power Spectrum Density Approach
The following figure shows a power spectrum associated with the 1-st mobile trip:

![psd_plot](https://user-images.githubusercontent.com/33201700/41247112-040d44d2-6d7b-11e8-98a3-d8109619793c.png)

It can be observed that there are no prominent peaks that can be focused on. So this approach is not very realistic. 

#### Correlation Approach
The basic thinking is as follows:
* For each mobile trip and obd trip, find the best matching position (the idea is to see what is the highest cross correlation score these two trips can achieve and use this score as a similarity measure). To find this best matchinng position:
  * Find the shorter trip between the two trips
  * Use the shorter trip as the “pattern-to-search” in the longer trip
  * Find the best matching position with the largest cross-correlation values and save this value as the similarity score

The following figure visualize this idea:

![thinking](https://user-images.githubusercontent.com/33201700/41247962-87f5922a-6d7d-11e8-909f-dfa56eb36423.png)

When the shorter signal is compared to different parts of the longer signal, different correlations scores can be obtained, i.e. a1, a2, a3, a4. If a3 is max among the four, then the best matching position between the two signal is at position 3.

* Next, compare this score between various pairs of trips, total of m * n combinations, where m is the number of trips in mobile dataset and n is the number of trips in the obd dataset. 
*	To implement this, I have created a 3-dimensional array in R, with the dimension of m * n * 3. In the first layer, the similarity scores are stored; In the second layer, the best matching positions are stored; and in the third layer, the dataset corresponds to the shorter trip is stored (the value is 1 if the shorter trip is an odb trip; and value is 2 if the shorter trip is a mobile phone trip). 
*	To compare similarity, a threshold value is needed. That is to say, if the similarity score between the two trips are above this threshold, it can be considered that this two trips contains similar patterns. 
*	Use the information stored in the array to extract the corresponding data frames and output the results in the required format. 

### Possible Future Improvements
*	Use dynamic time warping (DTW) to compare the similarity between two time series of different length and use the distance between the two series provided by DTW as similarity measure
*	Use the accuracy values in the mobile datasets as weighing factors. The larger the x, the less reliable the speed measurement.
*	Add filters to the time series to remove noises in measurement to achieve better matching score
