# Combine results from multiple runs of Adimixture analysis
- Prepare input files that have already been processed with Stacks(populations etc...) or PLINK in advance.
## Example case: Combine the results of 100 runs with K = 1 to 12
### 1. Run admixture analysis 100 times with K=1 to 12 in bash
<b>Note</b>
- The value of `K in {k..K}` is set to the desired K value.
- The value of `i in {i..I}` sets the number of cycles you want to run.
- Please set the options of the `admixture` command as desired.
```bash
for K in {k..K}; do
    for i in {i..I}; do
        # Run Admixture and output the log. Set rondum seed with $i
        admixture -s $i --cv {ped file name}.ped $K | tee log${K}_trial${i}.out
        # Save a Q file for each trial
        mv {ped file name}.${K}.Q {ped file name}.${K}_trial${i}.Q
    done
done
```
<b>Command Example</b>
```bash
## Linux
for K in {1..12}; do
    for i in {1..100}; do
        # Run Admixture and output the log
        admixture -C 0.0001 -s $i --cv=10 Admixture-input.ped $K | tee log${K}_trial${i}.out
        # Save a Q file for each trial
        mv Admixture-input.${K}.Q Admixture-input.${K}_trial${i}.Q
    done
done
```
```bash
## macOS
for K in $(seq 1 12); do
    for i in $(seq 1 100); do
        # Run Admixture and output the log
        admixture -C 0.0001 -s $i --cv=10 Admixture-input.ped $K | tee log${K}_trial${i}.out
        # Save a Q file for each trial
        mv Admixture-input.${K}.Q Admixture-input.${K}_trial${i}.Q
    done
done
```
### 2. Summarizing multiple trials using the pophelper package in R
### 2-1. Road pophelper package
```R
library(pophelper)
```
### 2-2. Set working directory
```R
setwd("{set/your/working/directory}")
```
### 2-3. Get a list of Q files (specify a file name pattern)
```R
# Example：K=3
q_files <- list.files(path = "{set/your/input/data/directory}", pattern = "{pop file name}.3_.*.Q", full.names = TRUE)
```
### 2-4. Read list file
```R
q_data <- readQ(q_files)
```
### 2-5. Align data by K value
```R
aligned_q_data <- alignK(q_data)
```
### 2-6. Merge (average) aligned data
```R
merged_q_data <- mergeQ(aligned_q_data)
```
### 2-7. Plot merged data
```R
plotQ(merged_q_data, exportpath = getwd())
```
# Output the CV error value for each trial in a box plot
in R
Summarize the CV error values ​​obtained from multiple trials.
### 1. Load the required libraries
```R
library(ggplot2)
library(dplyr)
```
### 2. Get a list of log files (specify a file name pattern)
```R
log_files <- list.files(path = "{set/your/input/data/directory}", pattern = "log\\d+_trial\\d+\\.out", full.names = TRUE)
```
### 3. Create an empty data frame to store the CV error value
```R
cv_errors <- data.frame(K = integer(0), trial = integer(0), cv_error = numeric(0))
```
### 4. Read each log file and extract CV errors
```R
for (file in log_files) {
    # Importing files
    lines <- readLines(file)
    
    # Extract the "CV error" value
    error_match <- grep("CV error", lines, value = TRUE)
    
    # Print error_match to see if the value was extracted correctly
    print(paste("error_match:", error_match))
    
    if (length(error_match) > 0) {
        # Extract the "CV error" value
        cv_value <- as.numeric(sub(".*CV error.*: ([0-9.]+).*", "\\1", error_match))
        
        # Check cv_value
        print(paste("cv_value:", cv_value))
        
        # Extract K and trial number from file name
        file_info <- strsplit(basename(file), "_")[[1]]
        
        # Extract K value
        K_value <- as.integer(sub("log(\\d+)", "\\1", file_info[1]))  # Extract "log" and numbers
        print(paste("K_value:", K_value))
        
        # Extract the trial number (the number between "trial" and ".out")
        trial_value <- as.integer(sub("trial(\\d+)\\.out", "\\1", file_info[2]))  # Extract "trial" and the number
        print(paste("trial_value:", trial_value))
        
        # Append the results to the data frame
        cv_errors <- rbind(cv_errors, data.frame(K = K_value, trial = trial_value, cv_error = cv_value))
    }
}
```
### 5. Creating a box plot
```R
ggplot(cv_errors, aes(x = factor(K), y = cv_error)) +
  geom_boxplot() +
  labs(x = "K", y = "CV error", title = "CV Error for Different K Values") +
  theme_minimal()
```
