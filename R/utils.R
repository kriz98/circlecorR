# Turn a `groups` argument into an ordered, named character vector aligned to
# the variables present in the matrix.
.resolve_groups <- function(groups, vars) {
  if (is.null(groups)) {
    g <- stats::setNames(rep("All", length(vars)), vars)
    return(g)
  }
  if (is.list(groups) && !is.data.frame(groups)) {
    # named list: category -> vector of variables
    g <- character(0)
    for (cat in names(groups)) {
      members <- groups[[cat]]
      g <- c(g, stats::setNames(rep(cat, length(members)), members))
    }
    groups <- g
  }
  if (is.null(names(groups))) {
    if (length(groups) != length(vars)) {
      stop("Unnamed `groups` must have one entry per variable (", length(vars),
           ").", call. = FALSE)
    }
    names(groups) <- vars
  }
  missing <- setdiff(vars, names(groups))
  if (length(missing)) {
    stop("No group assigned for: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  stats::setNames(as.character(groups[vars]), vars)
}

# Cycle an (unnamed) colour vector across a set of categories, recycling if
# there are more categories than colours.
.cycle_colors <- function(categories, pal) {
  n <- length(categories)
  cols <- pal[((seq_len(n) - 1) %% length(pal)) + 1]
  stats::setNames(cols, categories)
}

# `x %||% y`: return x unless it's NULL, in which case return y.
`%||%` <- function(x, y) if (is.null(x)) y else x

.default_labels <- function(vars) stats::setNames(vars, vars)

# The set of variables named by a `groups` argument, in order.
.groups_vars <- function(groups) {
  if (is.null(groups)) return(NULL)
  if (is.list(groups) && !is.data.frame(groups)) {
    return(unlist(groups, use.names = FALSE))
  }
  if (!is.null(names(groups))) return(names(groups))
  as.character(groups)
}
