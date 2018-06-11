#####################
## load the data
#####################
load("C:/Users/Owner/Desktop/Root/mobileTrips.RData") 
load("C:/Users/Owner/Desktop/Root/obd2Trips.RData") 

# This function is used to calculate the normalized cross-correlation between two signals/series of same length
# It takes in two vectors of the same length and return their normalized cross-correlation score when lag = 0
norm_corfun <- function (a, b) {
  a. <- a - mean(a) 
  b. <- b - mean(b)
  SSa <- sum(a.^2) 
  SSb <- sum(b.^2) 
  SaSb <- sqrt(SSa*SSb) 
  return(sum(a.*b.)/SaSb)
}

# This function is used to perform first-differencing to trips
# It takes in the any Trips dataset, such as mobileTripsTrain or obd2TripsTrain in this case
# It calculates the speed difference between the t-th and (t+1)-th timestamp and creates a diff column in each dataset. 
first_differencing <- function (Trips) {
  for (i in 1:length(Trips)) {
    Trips[[i]]$diff <- ave(Trips[[i]]$speed, FUN=function(x) c(0, diff(x)))
  }
  return(Trips)
}

# This function is used to return required output
# It takes mobile trip datasets and obd trip datasets, and an additional threshold value as inputs
# The threshold value is chosen based on how similar the user wants the returned signals to be.
result_function <- function (mobileTrips, obdTrips, threshold) {
  
  # The following code applies the first differencing function to update both data sets
  mobileTrips <- first_differencing(mobileTrips)
  obdTrips <- first_differencing(obdTrips)
  
  # Initialize a 3-dimensional array to store all information
  similarity_array <- array(0, dim = c(length(mobileTrips), length(obdTrips), 3))
  
  # Need to compare m * n pairs of trips
  for (m in 1:length(mobileTrips)){
    for (n in 1:length(obdTrips)){
      
      # Find the shorter trip between the two trips, and save the information about which trip is shorter as the third layer in the array
      if (nrow(mobileTrips[[m]]) >= nrow(obdTrips[[n]])) {
        shorter_signal <- obdTrips[[n]]$diff
        longer_signal <- mobileTrips[[m]]$diff
        similarity_array[m, n, 3] <- 1   # Use 1 to present the obd trips
      } else {
        shorter_signal <- mobileTrips[[m]]$diff
        longer_signal <- obdTrips[[n]]$diff
        similarity_array[m, n, 3] <- 2  # Use 2 to present mobile trips
      }
      
      # Calculate the highest cross-correlation score these two trips can achieve and use this as the similarity measure.
      # The following code creates a vector, the index of which indicates the matching position and the value of which stores the similarity score
      counter <- 1
      align_vector <- numeric(length(longer_signal) - length(shorter_signal) + 1)
      while (counter < (length(longer_signal) - length(shorter_signal) + 2)) {
        cut_signal <- longer_signal[counter: (counter + length(shorter_signal) - 1)]
        align_vector[counter] <- norm_corfun(shorter_signal, cut_signal)
        counter = counter + 1
      }
      
      # From the align vector above, obtain the best align position 
      best_align_position <- which.max(align_vector)
      if (length(best_align_position) == 0) {
        best_align_position <- 0  # indicating no position found
      }
      
      # From the align vector above, obtain the best align value
      best_align_value <- max(align_vector)
      
      # The best align value is saved in the first layer of the array
      similarity_array[m, n, 1] <- best_align_value
      
      # The best align position is saved in the second layer of the array
      similarity_array[m, n, 2] <- best_align_position  
    }
  }
  
  # If there are NaN values, their values are set to zero
  similarity_array[is.nan(similarity_array)] <- 0
  
  # To compare similarity, a threshold value is needed. 
  # if the similarity score between the two trips are above this threshold, 
  # it can be considered that these two trips contain similar patterns.
  matching_pairs <- which(similarity_array[ , , 1] > threshold, arr.ind = TRUE) 
  
  # Use the information stored in the array to extract the data frames and output the results in the required format
  result <- list()
  for (p in 1:(length(matching_pairs)/2)){
    first_ind <- matching_pairs[p, "row"]
    second_ind <- matching_pairs[p, "col"]
    matching_position <- similarity_array[first_ind, second_ind, 2]
    shorter_series <- similarity_array[first_ind, second_ind, 3]
    if (shorter_series == 1){
      df.1 <- obdTrips[[second_ind]]
      df.2 <- mobileTrips[[first_ind]][matching_position : (matching_position + length(df.1$diff) - 1), ]
      result[[p]] <- list(df.1,df.2)
    } else {
      df.2 <- mobileTrips[[first_ind]]
      df.1 <- obdTrips[[second_ind]][matching_position : (matching_position + length(df.2$diff) - 1), ]
      result[[p]] <- list(df.1,df.2)
    }
  }
  return(result)
}

# To obtain the final results, need to call the following:
output <- result_function(mobileTripsTrain, obd2TripsTrain, 0.3)



















