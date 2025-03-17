# Log File Processing Functions
process_logs_improved <- function(log_dir_path, pattern = "log.*\\.out$") {
  # Get a list of log files in a directory
  log_files <- list.files(path = log_dir_path, pattern = pattern, full.names = TRUE)

  # Initialize a data frame to store the results
  results <- data.frame(
    file = character(),
    K = numeric(),
    trial = numeric(),
    loglikelihood = numeric(),
    cv_error = numeric(),
    stringsAsFactors = FALSE
  )

  # Process each log file
  for (file_path in log_files) {
    file_name <- basename(file_path)
    extracted_k_trial <- extract_k_trial_from_filename(file_name)
    extracted_data <- extract_loglikelihood(file_path)

    # Check the K value
    file_k <- extracted_k_trial$K
    log_k <- extracted_data$K

    # Warn if K value mismatch (for debugging)
    if(!is.na(file_k) && !is.na(log_k) && file_k != log_k) {
      warning(paste("K value mismatch:", file_name,
                    "- K=" from file name, file_k,
                    ", K=" from log content, log_k))
    }

    # Add to result (priority is given to K value extracted from file name)
    results <- rbind(results, data.frame(
      file = file_name,
      K = if(!is.na(file_k)) file_k else log_k,
      trial = extracted_k_trial$trial,
      loglikelihood = extracted_data$loglikelihood,
      cv_error = extracted_data$cv_error,
      stringsAsFactors = FALSE
    ))
  }

  # Check for duplicates
  if(any(duplicated(results$file))) {
    warning("There are duplicate file names. Remove the duplicates.")
    results <- results[!duplicated(results$file), ]
  }

  return(results)
}
