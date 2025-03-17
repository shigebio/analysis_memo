# Functions for calculating Evanno method and mean log-likelihood
calculate_by_evanno_method <- function(results) {
  # Extract only valid data
  valid_results <- results[!is.na(results$K) & !is.na(results$loglikelihood), ]

  # Calculate the number of trials and the mean log-likelihood for each K value
  k_stats <- tapply(valid_results$loglikelihood, valid_results$K, function(x) {
    list(
      count = length(x),
      mean = mean(x),
      sd = if(length(x) > 1) sd(x) else 0
    )
  })

  # Formatting the results
  stats_df <- data.frame(
    K = as.numeric(names(k_stats)),
    count = sapply(k_stats, function(x) x$count),
    mean_loglikelihood = sapply(k_stats, function(x) x$mean),
    sd_loglikelihood = sapply(k_stats, function(x) x$sd),
    stringsAsFactors = FALSE
  )

  # Sort by K value
  stats_df <- stats_df[order(stats_df$K), ]

  # ΔK calculation by Evanno method
  # First derivative of L(K) L'(K)
  L_prime <- c(NA, diff(stats_df$mean_loglikelihood))

  # First derivative of the absolute value of L'(K) |L''(K)|
  L_double_prime <- rep(NA, length(stats_df$K))
  if(length(stats_df$K) >= 3) {
    for(i in 2:(length(stats_df$K)-1)) {
      L_double_prime[i] <- abs(L_prime[i+1] - L_prime[i])
    }
  }

  # ΔK = |L''(K)| / sd(L(K))
  delta_k <- rep(NA, length(stats_df$K))
  for(i in 1:length(stats_df$K)) {
    if(!is.na(L_double_prime[i]) && stats_df$sd_loglikelihood[i] > 0) {
      delta_k[i] <- L_double_prime[i] / stats_df$sd_loglikelihood[i]
    }
  }

  # Formatting the results
  evanno_df <- data.frame(
    K = stats_df$K,
    count = stats_df$count,
    mean_loglikelihood = stats_df$mean_loglikelihood,
    sd_loglikelihood = stats_df$sd_loglikelihood,
    L_prime = L_prime,
    L_double_prime = L_double_prime,
    delta_k = delta_k,
    stringsAsFactors = FALSE
  )

  return(evanno_df)
}