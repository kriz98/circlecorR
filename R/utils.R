# Coerce a correlation input to a numeric matrix with dimnames.
.as_cor_matrix <- function(x, arg = "r") {
  if (is.data.frame(x)) {
    # Drop a leading label column if the first column is character/rownames-like
    if (ncol(x) && (is.character(x[[1]]) || is.factor(x[[1]]))) {
      rn <- as.character(x[[1]])
      x <- x[, -1, drop = FALSE]
      rownames(x) <- rn
    }
    x <- as.matrix(x)
  }
  if (!is.matrix(x)) {
    stop("`", arg, "` must be a matrix or data.frame.", call. = FALSE)
  }
  storage.mode(x) <- "double"
  if (nrow(x) != ncol(x)) {
    stop("`", arg, "` must be square (it is ", nrow(x), " x ", ncol(x), ").",
         call. = FALSE)
  }
  if (is.null(colnames(x))) colnames(x) <- paste0("V", seq_len(ncol(x)))
  if (is.null(rownames(x))) rownames(x) <- colnames(x)
  x
}

# Symmetrise a p-value matrix by mirroring one triangle.
# `psych::corr.test` returns raw p-values below the diagonal and adjusted
# p-values above it, so which triangle you mirror matters.
.symmetrise_p <- function(p, from = c("lower", "upper")) {
  from <- match.arg(from)
  p <- .as_cor_matrix(p, "p")
  if (from == "lower") {
    tri <- p
    tri[upper.tri(tri)] <- 0
    out <- tri + t(tri)
  } else {
    tri <- p
    tri[lower.tri(tri)] <- 0
    out <- tri + t(tri)
  }
  diag(out) <- diag(p)
  dimnames(out) <- dimnames(p)
  out
}

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

# Default category colours, close to the seaborn 'deep' palette.
.default_group_colors <- function(categories) {
  .cycle_colors(categories, .scheme_registry$default$colors)
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

# Heuristic: does `x` look like a correlation matrix (vs raw per-row data)?
# A correlation matrix is square, has ~1 on the diagonal, and values in
# [-1, 1]. Raw patient data is typically non-square with a non-unit diagonal.
# Reuses `.as_cor_matrix` so a leading label column is stripped first.
.looks_like_cor <- function(x) {
  if (inherits(x, "circlecor")) return(TRUE)
  m <- try(.as_cor_matrix(x), silent = TRUE)   # errors if not square
  if (inherits(m, "try-error")) return(FALSE)
  d <- diag(m)
  if (any(is.na(d)) || !all(abs(d - 1) < 1e-6)) return(FALSE)
  rng <- suppressWarnings(range(m, na.rm = TRUE))
  all(is.finite(rng)) && rng[1] >= -1.0001 && rng[2] <= 1.0001
}
