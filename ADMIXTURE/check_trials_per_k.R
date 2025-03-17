# Function to check the number of trials for each K value
check_trials_per_k <- function(results) {
  # Extract only rows with a specific K value
  valid_results <- results[!is.na(results$K) & !is.na(results$trial), ]

  # Count the number of trials for each K value
  k_trials <- tapply(valid_results$trial, valid_results$K, function(x) {
    list(count = length(x), trials = paste(sort(unique(x)), collapse = ", "))
  })

  # Formatting the results
  trials_df <- data.frame(
    K = as.numeric(names(k_trials)),
    trial_count = sapply(k_trials, function(x) x$count),
    trials = sapply(k_trials, function(x) x$trials),
    stringsAsFactors = FALSE
  )

  # Sort by K value
  trials_df <- trials_df[order(trials_df$K), ]

  return(trials_df)
}