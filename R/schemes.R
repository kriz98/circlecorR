# Built-in colour schemes: an (unnamed, cycled) set of category colours plus
# a 3-colour diverging link palette (negative, midpoint, positive).
.scheme_registry <- list(
  default = list(
    colors  = c("#4C72B0", "#DD8452", "#55A868", "#C44E52", "#8172B3",
               "#937860", "#DA8BC3", "#8C8C8C", "#CCB974", "#64B5CD"),
    palette = c("#2166AC", "#FFFFFF", "#B2182B")
  ),
  colorblind = list(
    # Okabe-Ito categorical palette + a colourblind-safe (PuOr) diverging scale
    colors  = c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2",
               "#D55E00", "#CC79A7", "#999999"),
    palette = c("#E66101", "#F7F7F7", "#5E3C99")
  ),
  ocean = list(
    # Cool-toned but hue-varied (teal, blue, indigo, violet, slate) so
    # categories stay easy to tell apart at a glance -- shades of a single
    # colour read as one blur once there are more than two or three
    # categories. Blue<->warm diverging echoes the package's hex-sticker
    # branding.
    colors  = c("#0E7490", "#2563EB", "#4338CA", "#7C3AED", "#475569"),
    palette = c("#1D4ED8", "#F5F7FF", "#F0834D")
  ),
  vivid = list(
    colors  = c("#EF476F", "#FFB703", "#06D6A0", "#118AB2", "#7B2CBF"),
    palette = c("#2166AC", "#FFFFFF", "#B2182B")
  ),
  alimetry = list(
    # Blues alternating with warm golds, echoing Alimetry's brand palette
    # (a dark teal-to-navy backdrop with an electric-cyan accent) and the
    # blue-to-yellow heatmaps in their spectrogram figures. The two yellows
    # are spread well apart in lightness (rich gold vs. pale lemon) so they
    # stay distinguishable, rather than reading as near-duplicates. Diverging
    # scale mirrors that same blue<->yellow visual language.
    colors  = c("#0D3B5C", "#F5C518", "#1878A0", "#FDE047", "#22C3F0"),
    palette = c("#1878A0", "#F5F7FF", "#F5C518")
  )
)

# Resolve the `scheme` argument of corr_wheel() to a list(colors=, palette=).
# `scheme` may be NULL, a built-in name, or a custom list(colors=, palette=).
.resolve_scheme <- function(scheme) {
  if (is.null(scheme)) return(list(colors = NULL, palette = NULL))
  if (is.character(scheme) && length(scheme) == 1) {
    if (!scheme %in% names(.scheme_registry)) {
      stop("Unknown scheme '", scheme, "'. Available schemes: ",
           paste(names(.scheme_registry), collapse = ", "), call. = FALSE)
    }
    return(.scheme_registry[[scheme]])
  }
  if (is.list(scheme)) {
    if (!is.null(scheme$palette) && length(scheme$palette) != 3) {
      stop("`scheme$palette` must have length 3 (negative, midpoint, ",
           "positive colours).", call. = FALSE)
    }
    return(list(colors = scheme$colors, palette = scheme$palette))
  }
  stop("`scheme` must be NULL, a built-in scheme name (see ",
       "corr_wheel_schemes()), or a list(colors = , palette = ).",
       call. = FALSE)
}

#' List built-in colour schemes
#'
#' Returns the names of the colour schemes bundled with the package, for use
#' as the `scheme` argument of [corr_wheel()].
#'
#' @return A character vector of scheme names.
#' @seealso [corr_wheel_scheme()], [corr_wheel()]
#' @examples
#' corr_wheel_schemes()
#' @export
corr_wheel_schemes <- function() names(.scheme_registry)

#' Get a built-in colour scheme
#'
#' Returns the category-colour and diverging-link-palette definition for a
#' built-in scheme, so you can inspect it or tweak a copy before passing it to
#' [corr_wheel()]'s `scheme` argument.
#'
#' @param name A scheme name; see [corr_wheel_schemes()] for the available
#'   options.
#'
#' @return A list with elements `colors` (an unnamed vector of category
#'   colours, cycled across however many categories are plotted) and
#'   `palette` (a length-3 diverging colour vector: negative, midpoint,
#'   positive).
#' @seealso [corr_wheel_schemes()], [corr_wheel()]
#' @examples
#' s <- corr_wheel_scheme("colorblind")
#' s$palette
#'
#' # Tweak a copy and use it
#' s$palette[2] <- "grey95"
#' data(gastro_symptoms)
#' grp <- list(Demographics = c("Age", "BMI"),
#'            Metrics = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"))
#' if (requireNamespace("psych", quietly = TRUE)) {
#'   corr_wheel(gastro_symptoms, groups = grp, scheme = s, r_threshold = 0)
#' }
#' @export
corr_wheel_scheme <- function(name = "default") {
  name <- match.arg(name, names(.scheme_registry))
  .scheme_registry[[name]]
}
