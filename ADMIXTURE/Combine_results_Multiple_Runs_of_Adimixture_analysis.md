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
### 2. Summarizing multiple trials using the [pong](https://github.com/ramachandran-lab/pong)
#### 2-1. Create filemap file
Creating filemap file program: [create_pong_map.py](https://github.com/shigebio/analysis_memo/blob/main/ADMIXTURE/create_pong_map.py)

<b>Note</b>: The file will be generated according to the output file name output according to the procedure in this article, so if you have a different file name pattern, please take measures according to that pattern.
```bash
python create_pong_map.py -K {K value} -R {Number of trials} -o {Output file name}
```
```bash
# Example for K=1~12, Trial=100
python create_pong_map.py -K 12 -R 100 -o admixture_runsK12R100.txt
```
```
# Example output
K1r1	1	./Admixture-input.1_trial1.Q
K1r2	1	./Admixture-input.1_trial2.Q
K1r3	1	./Admixture-input.1_trial3.Q
K1r4	1	./Admixture-input.1_trial4.Q
```
#### 2-2. Run pong
```bash
pong -m {filemap file name} -v
```
```bash
# Example
pong -m admixture_runsK12R100.txt -v
```
#### 2-3. Open local server
When summerizes are completed, open [local server](http://localhost:4000).
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

# Determine the best K using Evanno's ΔK method and caluculate mean log-likelihood
#### 1. Process log files
[process_logs.R](https://github.com/shigebio/analysis_memo/blob/main/ADMIXTURE/process_logs.R)

Additionally, define the following functions.
```
extract_k_trial_from_filename <- function(filename) {
  k <- as.numeric(gsub("log([0-9]+)_.*", "\\1", filename))
  trial_value <- as.numeric(gsub("log([0-9]+)_trial([0-9]+).*", "\\2", filename))
  return(list(K = k, trial = trial_value))
}
```
```
extract_loglikelihood <- function(file_path) {
  log_content <- readLines(file_path)
  
  ll_line <- grep("Loglikelihood:", log_content, fixed = TRUE)
  if (length(ll_line) > 0) {
    ll_text <- log_content[ll_line]
    loglikelihood <- as.numeric(gsub(".*Loglikelihood: ([0-9.-]+).*", "\\1", ll_text))
  } else {
    loglikelihood <- NA
  }
  
  cv_line <- grep("CV error", log_content)
  if (length(cv_line) > 0) {
    cv_text <- log_content[cv_line]
    k_value <- as.numeric(gsub(".*CV error \\(K=([0-9]+)\\):.*", "\\1", cv_text))
    cv_error <- as.numeric(gsub(".*CV error \\(K=[0-9]+\\): ([0-9.]+).*", "\\1", cv_text))
  } else {
    k_value <- NA
    cv_error <- NA
  }
  
  return(list(K = k_value, loglikelihood = loglikelihood, cv_error = cv_error))
}
```
execution
```
log_likelihood_results <- process_logs("path/to/log_file/directory")
```

#### 2. Check the number of trials for each K value
[check_trials_per_k.R](https://github.com/shigebio/analysis_memo/blob/main/ADMIXTURE/check_trials_per_k.R)
This is for confirmation purposes only, so it is not required.
```
trials_info <- check_trials_per_k(log_likelihood_results)
print(trials_info)
```

#### 3. Calculation by Evanno method
[calculate_by_evanno_method.R](https://github.com/shigebio/analysis_memo/blob/main/ADMIXTURE/calculate_by_evanno_method.R))
```
evanno_results <- calculate_by_evanno_method(log_likelihood_results)
print(evanno_results)
```

#### 4. Visualization
<b>Note</b>: Requires ggplot2
```
if(require(ggplot2)) {
  # Plotting of mean log-likelihood
  p1 <- ggplot(evanno_results, aes(x = K, y = mean_loglikelihood)) +
    geom_point() +
    geom_line() +
    geom_errorbar(aes(ymin = mean_loglikelihood - sd_loglikelihood,
                     ymax = mean_loglikelihood + sd_loglikelihood), width = 0.2) +
    labs(title = "Mean log-likelihood by K",
         x = "K", y = "Mean L(K)") +
    theme_minimal()

  # Plot of ΔK (except K=1)
  delta_k_plot_data <- subset(evanno_results, !is.na(delta_k) & K > 1)
  if(nrow(delta_k_plot_data) > 0) {
    p2 <- ggplot(delta_k_plot_data, aes(x = K, y = delta_k)) +
      geom_point() +
      geom_line() +
      labs(title = "Evanno's ΔK Method",
           x = "K", y = "ΔK") +
      theme_minimal()

    # Show both plots
    if(require(gridExtra)) {
      grid.arrange(p1, p2, ncol = 1)
    } else {
      print(p1)
      print(p2)
    }
  } else {
    print(p1)
    warning("Not enough data to plot ΔK")
  }
} else {
  # Basic plotting without ggplot2
  par(mfrow = c(2, 1))
  plot(evanno_results$K, evanno_results$mean_loglikelihood,
       type = "b", xlab = "K", ylab = "Mean L(K)",
       main = "Mean log-likelihood by K")


  # Add error bars
  arrows(evanno_results$K,
         evanno_results$mean_loglikelihood - evanno_results$sd_loglikelihood,
         evanno_results$K,
         evanno_results$mean_loglikelihood + evanno_results$sd_loglikelihood,
         length = 0.05, angle = 90, code = 3)

  # Plot of ΔK (excluding K=1 and NA)
  valid_k <- !is.na(evanno_results$delta_k) & evanno_results$K > 1
  if(sum(valid_k) > 0) {
    plot(evanno_results$K[valid_k], evanno_results$delta_k[valid_k],
         type = "b", xlab = "K", ylab = "ΔK",
         main = "Evanno's ΔK Method")
  }
  par(mfrow = c(1, 1))
}
```
![77ea29eb-930d-40fb-9a6c-330963ba3da5](https://github.com/user-attachments/assets/614ec25e-a346-4c8d-a708-1a1245bc97d6)
