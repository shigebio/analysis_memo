# Combine results from multiple runs of [ADMIXTURE](https://dalexander.github.io/admixture/index.html) analysis
- Prepare input files that have already been processed with [Stacks](https://catchenlab.life.illinois.edu/stacks/)(populations etc...) or [PLINK](https://www.cog-genomics.org/plink/) in advance.
## Example case: Combine the results of 100 runs with K = 1 to 12
### 1. Run ADMIXTURE analysis 100 times with K=1 to 12 in bash
<b>Note</b>
- The value of `K in {k..K}` is set to the desired K value.
- The value of `i in {i..I}` sets the number of cycles you want to run.
- Please set the options of the `admixture` command as desired.
```bash
for K in {k..K}; do
    for i in {i..I}; do
        # Run ADMIXTURE and output the log. Set rondum seed with $i
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
        # Run ADMIXTURE and output the log
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
        # Run ADMIXTURE and output the log
        admixture -C 0.0001 -s $i --cv=10 Admixture-input.ped $K | tee log${K}_trial${i}.out
        # Save a Q file for each trial
        mv Admixture-input.${K}.Q Admixture-input.${K}_trial${i}.Q
    done
done
```
### 2. Summarizing multiple trials using the [pophelper](https://www.royfrancis.com/pophelper/articles/index.html) package in [R](https://www.r-project.org/)
#### 2-1. Road pophelper package
```R
library(pophelper)
```
#### 2-2. Set working directory
```R
setwd("{set/your/working/directory}")
```
#### 2-3. Get a list of Q files (specify a file name pattern)
```R
q_files <- list.files(path = "{set/your/input/data/directory}", pattern = "{pop file name}.{K value you want to summarize}_.*.Q", full.names = TRUE)
```
Example: K=3
```R
q_files <- list.files(path = "{set/your/input/data/directory}", pattern = "Admixture-input.3_.*.Q", full.names = TRUE)
```
#### 2-4. Read list file
```R
q_data <- readQ(q_files)
```
#### 2-5. Align data by K value
```R
aligned_q_data <- alignK(q_data)
```
Check that the ratios assigned to each cluster are consistent (may not know until the results are released).
```R
> print(aligned_q_data )
$`Admixture-input.3_trial1.Q`
   Cluster1 Cluster2 Cluster3
1  0.000010 0.999980 0.000010
2  0.000010 0.999980 0.000010
・
・
```
#### 2-6. Merge (average) aligned data
```R
merged_q_data <- mergeQ(aligned_q_data)
```
Check that the values ​​are averaged for each cluster.
```R
> print(merged_q_data )
$`3`
     Cluster1   Cluster2   Cluster3
1  0.00001018 0.99997980 0.00001002
2  0.00001000 0.99997997 0.00001003
・
・
```
#### 2-7. Plot merged data
```R
plotQ(merged_q_data, exportpath = getwd())
```
# Output the CV error value for each trial in a box plot
in R
Summarize the CV error values ​​obtained from multiple trials.
#### 1. Load the required libraries
```R
library(ggplot2)
library(dplyr)
```
#### 2. Get a list of log files (specify a file name pattern)
<b>Note</b>:The `patten` argument must be edited to a regular expression that matches the name of your log file. In this example, it is written to match the log file name output by the ADMIXTURE analysis flow above.If you have followed the above flow, you may not need to make any changes.
```R
log_files <- list.files(path = "{set/your/input/data/directory}", pattern = "log\\d+_trial\\d+\\.out", full.names = TRUE)
```

#### 3. Create an empty data frame to store the CV error value
```R
cv_errors <- data.frame(K = integer(0), trial = integer(0), cv_error = numeric(0))
```
Check that the values ​​are stored in `K`, `trial`, and `cv_error` as shown below.
```R
> print(cv_errors)
     K trial cv_error
1    1     1  0.67527
2    1    10  0.67553
3    1   100  0.67528
4    1    11  0.67398
5    1    12  0.67589
・
・
```
#### 4. Read each log file and extract CV errors
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
#### 5. Creating a box plot
```R
ggplot(cv_errors, aes(x = factor(K), y = cv_error)) +
  geom_boxplot() +
  labs(x = "K", y = "CV error", title = "CV Error for Different K Values") +
  theme_minimal()
```
![image](https://github.com/user-attachments/assets/1c1bb730-a4e5-4ba9-9839-828a7d0df795)
