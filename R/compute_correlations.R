#' Compute a correlation matrix and (raw) p-values from raw data
#'
#' A thin wrapper around [psych::corr.test()] that returns the correlation
#' (`r`) and **unadjusted** p-value (`p`) matrices bundled in a single object
#' suitable for passing straight to [corr_wheel()].
#'
#' Multiple-comparison adjustment is deliberately **not** applied here. On a
#' correlation wheel, self-correlations and (usually) within-category
#' correlations are never tested, so they should not count towards the family
#' of comparisons. [corr_wheel()] therefore applies the adjustment itself, over
#' exactly the set of correlations it displays -- which is both statistically
#' consistent and more powerful than adjusting across the full matrix. See the
#' `adjust` and `hide_within_group` arguments of [corr_wheel()].
#'
#' @param data A data frame or matrix of observations (rows) by variables
#'   (columns).
#' @param vars Optional character vector selecting and ordering the columns of
#'   `data` to use. Defaults to all columns.
#' @param method Correlation method, passed to [psych::corr.test()]. One of
#'   `"pearson"`, `"spearman"`, `"kendall"`.
#' @param use Handling of missing values, passed to [psych::corr.test()].
#'
#' @return An object of class `"circlecor"`: a list with elements `r` (the
#'   correlation matrix), `p` (a symmetric matrix of **raw**, unadjusted
#'   p-values), `n` (the pairwise sample sizes from `psych`), and `method`.
#'
#' @seealso [corr_wheel()]
#' @examples
#' if (requireNamespace("psych", quietly = TRUE)) {
#'   cc <- compute_correlations(mtcars, method = "pearson")
#'   str(cc)
#' }
#' @export
compute_correlations <- function(data,
                                 vars = NULL,
                                 method = c("pearson", "spearman", "kendall"),
                                 use = "pairwise.complete.obs") {
  if (!requireNamespace("psych", quietly = TRUE)) {
    stop("`compute_correlations()` requires the 'psych' package. ",
         "Install it with install.packages('psych'), or pass pre-computed ",
         "r/p matrices to corr_wheel() directly.", call. = FALSE)
  }
  method <- match.arg(method)
  if (!is.null(vars)) {
    missing <- setdiff(vars, colnames(data))
    if (length(missing)) {
      stop("These `vars` are not columns of `data`: ",
           paste(missing, collapse = ", "), call. = FALSE)
    }
    data <- data[, vars, drop = FALSE]
  }
  # adjust = "none": $p is the symmetric matrix of raw p-values.
  ct <- psych::corr.test(as.matrix(data), method = method, use = use,
                         adjust = "none")
  structure(list(r = ct$r, p = ct$p, n = ct$n, method = method),
            class = "circlecor")
}
