#' Draw a circular correlation wheel plot
#'
#' Arranges variables around a circle, grouped and colour-tiled by category, and
#' connects them with curved links whose colour maps to the correlation
#' coefficient. Non-significant, weak, and (optionally) within-category
#' correlations are masked. This reproduces the MNE-style "connectivity circle"
#' natively in R using \pkg{circlize}.
#'
#' @details
#' A traditional correlation matrix is dominated by redundant information: the
#' diagonal of self-correlations, the mirror-image lower triangle, and blocks of
#' within-category correlations that are rarely of interest. The wheel keeps only
#' the correlations you actually want to inspect -- by default the
#' **between-category** correlations, with self- and within-category
#' correlations hidden.
#'
#' This is not only a display choice; it is carried through to the statistics.
#' The multiple-comparison adjustment (`adjust`) is applied over **only the
#' family of correlations shown** -- i.e. excluding self- and, when
#' `hide_within_group = TRUE`, within-category correlations. Because those
#' redundant comparisons no longer count towards the family, the correction is
#' less severe and statistical power improves.
#'
#' @param data A data frame or matrix with **one row per observation** (e.g. one
#'   row per patient) and variables in columns. Correlations and p-values are
#'   computed for you via [compute_correlations()] using `method`, `adjust`,
#'   and `use`. When `groups` is supplied, only the variables it names are used
#'   (in that order), so extra columns such as an ID are simply ignored.
#' @param method,use Passed to [compute_correlations()]: the correlation method
#'   and the missing-value handling.
#' @param adjust Multiple-comparison adjustment method applied to the raw
#'   p-values over the displayed family of correlations (see Details). Any
#'   method accepted by [stats::p.adjust()] (e.g. `"holm"`, `"hochberg"`,
#'   `"BH"`, `"bonferroni"`, `"none"`).
#' @param groups Category assignment for the variables. Either a named vector
#'   (`variable = category`) or a named list (`category = c(variables)`). The
#'   order of categories here sets their order around the wheel. If `NULL`, all
#'   variables share one group.
#' @param scheme A colour scheme providing the base category colours and
#'   diverging link palette together. One of:
#'   * `NULL` (default) -- use the package default scheme;
#'   * a built-in scheme name, see [corr_wheel_schemes()] (e.g. `"colorblind"`,
#'     `"ocean"`, `"vivid"`, `"alimetry"`);
#'   * a custom `list(colors = , palette = )`, as returned by
#'     [corr_wheel_scheme()] (optionally tweaked).
#'
#'   `colors` and `palette` (below), if supplied, override the scheme's
#'   corresponding piece -- so you can pick a scheme and still tweak one
#'   category's colour, for instance.
#' @param colors Named vector mapping category to colour, layered on top of
#'   `scheme` (or the default palette if `scheme` is `NULL`). Only the
#'   categories you name are overridden; others keep the scheme's colour.
#' @param labels Named vector mapping variable name to a display label. Missing
#'   entries fall back to the variable name.
#' @param order Optional character vector giving an explicit variable order
#'   around the wheel. Overrides ordering by `groups`. Must contain every
#'   variable.
#' @param sig_level Significance threshold; links with adjusted `p > sig_level`
#'   are hidden.
#' @param r_threshold Minimum absolute correlation to display.
#' @param hide_within_group Logical; if `TRUE` (default) correlations between
#'   two variables in the same category are hidden -- and excluded from the
#'   multiple-comparison family (see Details). Self-correlations (the diagonal)
#'   are always excluded.
#' @param r_limits Length-2 numeric giving the colour-scale limits
#'   (`c(vmin, vmax)`). Correlations beyond these are clamped for colour.
#' @param palette Colours for the diverging link scale at
#'   `c(r_limits[1], midpoint, r_limits[2])`, overriding `scheme`'s. `NULL`
#'   (default) uses the scheme's palette, or a blue-white-red scale if
#'   `scheme` is also `NULL`.
#' @param start_degree Angle (degrees) of the first variable; 90 places it at
#'   the top, going clockwise.
#' @param group_gap,node_gap Gaps (degrees) between categories and between
#'   variables within a category.
#' @param link_lwd Line width (size) of the links. Increase for thicker lines.
#' @param sort_links If `TRUE` (default), stronger correlations are drawn last
#'   (on top).
#' @param tile_height Radial thickness (size) of the coloured category blocks.
#'   Smaller values give thinner blocks at the rim.
#' @param label_cex,tile_border Label text size and tile border colour.
#' @param label_pad Extra canvas padding (as a fraction of the circle radius)
#'   to keep long outer labels from being clipped. Increase for longer labels.
#' @param label_r_offset Radial gap (in circle-radius units) between the outer
#'   edge of the tiles and the start of the labels.
#' @param title Optional plot title.
#' @param legend,colorbar Logical toggles for the category legend and the
#'   correlation colour bar.
#' @param legend_title,colorbar_title Titles for the legend and colour bar.
#'
#' @return Invisibly, a list with the ordered `vars`, resolved `groups`,
#'   `colors`, the `col_fun` colour mapping, the masked `matrix` of correlations
#'   actually drawn (others `NA`), the family-adjusted p-value matrix
#'   `p_adjusted`, the number of drawn links `n_links`, the size of the
#'   comparison family `n_tests`, and the `adjust` method applied.
#'
#' @examples
#' grp <- list(
#'   Demographics = c("Age", "BMI"),
#'   Metrics      = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"),
#'   Symptoms     = c("Nausea", "Early satiety", "Bloating", "Upper GI pain",
#'                    "Lower GI pain", "Heartburn"),
#'   Scores       = c("GCSI", "PAGI-SYM", "PAGI-QoL", "EQ-5D")
#' )
#'
#' # `gastro_symptoms` is a synthetic example dataset bundled with the package
#' # (available directly after library(circlecorR) -- no need to call data()).
#' corr_wheel(gastro_symptoms, groups = grp, r_threshold = 0.3,
#'            r_limits = c(-0.6, 0.6))
#'
#' # A built-in colour scheme, with one category colour overridden
#' corr_wheel(gastro_symptoms, groups = grp, r_threshold = 0.3,
#'            scheme = "colorblind", colors = c(Scores = "black"))
#'
#' @seealso [compute_correlations()], [corr_wheel_schemes()], [corr_wheel_scheme()]
#' @export
corr_wheel <- function(data,
                       groups = NULL,
                       scheme = NULL,
                       colors = NULL,
                       labels = NULL,
                       order = NULL,
                       sig_level = 0.05,
                       r_threshold = 0,
                       hide_within_group = TRUE,
                       method = c("pearson", "spearman", "kendall"),
                       adjust = "holm",
                       use = "pairwise.complete.obs",
                       r_limits = c(-0.5, 0.5),
                       palette = NULL,
                       start_degree = 90,
                       group_gap = 5,
                       node_gap = 1.5,
                       link_lwd = 1.6,
                       sort_links = TRUE,
                       tile_height = 0.06,
                       label_cex = 0.85,
                       label_pad = 0.45,
                       label_r_offset = 0.07,
                       tile_border = "white",
                       title = NULL,
                       legend = TRUE,
                       colorbar = TRUE,
                       legend_title = "Category",
                       colorbar_title = "Correlation\ncoefficient") {
  method <- match.arg(method)

  # Variables the user asked for, via `groups` (drives selection + ordering).
  target <- .groups_vars(groups)

  # ---- Compute correlations straight from the raw data ----------------------
  data <- as.data.frame(data)
  sel <- if (is.null(target)) colnames(data) else target
  miss <- setdiff(sel, colnames(data))
  if (length(miss)) {
    stop("These variables are not columns of `data`: ",
         paste(miss, collapse = ", "), call. = FALSE)
  }
  cc <- compute_correlations(data[, sel, drop = FALSE], method = method,
                             use = use)
  r <- cc$r
  p <- cc$p
  vars <- colnames(r)

  grp <- .resolve_groups(groups, vars)
  cats <- if (is.list(groups) && !is.null(names(groups))) names(groups) else unique(grp)

  # ---- Determine order around the wheel ------------------------------------
  if (!is.null(order)) {
    missing <- setdiff(vars, order)
    if (length(missing)) {
      stop("`order` is missing: ", paste(missing, collapse = ", "),
           call. = FALSE)
    }
    ord_vars <- order[order %in% vars]
  } else {
    ord_vars <- unlist(lapply(cats, function(k) vars[grp == k]), use.names = FALSE)
  }
  n <- length(ord_vars)
  r <- r[ord_vars, ord_vars, drop = FALSE]
  p <- p[ord_vars, ord_vars, drop = FALSE]
  grp <- grp[ord_vars]

  # ---- Colours --------------------------------------------------------------
  # `scheme` supplies a base (category colours + diverging link palette);
  # explicit `colors`/`palette` arguments override individual pieces on top.
  scheme_def <- .resolve_scheme(scheme)
  colmap <- .cycle_colors(cats, scheme_def$colors %||% .scheme_registry$default$colors)
  if (!is.null(colors)) colmap[names(colors)] <- colors
  node_cols <- stats::setNames(colmap[grp], ord_vars)

  lab_map <- .default_labels(ord_vars)
  if (!is.null(labels)) {
    common <- intersect(names(labels), names(lab_map))
    lab_map[common] <- labels[common]
  }

  final_palette <- palette %||% scheme_def$palette %||%
    .scheme_registry$default$palette
  col_fun <- circlize::colorRamp2(
    c(r_limits[1], mean(r_limits), r_limits[2]), final_palette
  )

  # ---- Family of tested correlations ---------------------------------------
  # Self-correlations (the diagonal) are never tested. When hide_within_group
  # is TRUE, within-category correlations are structurally excluded too. The
  # remaining upper-triangle pairs with a non-missing r form the *family* of
  # comparisons -- the only correlations that are displayed AND the only ones
  # that count towards the multiple-comparison correction. Shrinking the family
  # this way makes the correction less severe and so improves power.
  family <- matrix(FALSE, n, n, dimnames = list(ord_vars, ord_vars))
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      if (is.na(r[i, j])) next
      if (hide_within_group && grp[i] == grp[j]) next
      family[i, j] <- TRUE
    }
  }
  n_tests <- sum(family)

  # ---- Multiple-comparison adjustment over the family ----------------------
  p_adj <- p
  if (adjust != "none" && n_tests > 0) {
    p_adj <- matrix(NA_real_, n, n, dimnames = list(ord_vars, ord_vars))
    fam_idx <- which(family)
    p_adj[fam_idx] <- stats::p.adjust(p[fam_idx], method = adjust)
  }

  # ---- Build the mask of links to draw -------------------------------------
  keep <- family
  for (i in seq_len(n - 1)) {
    for (j in (i + 1):n) {
      if (!family[i, j]) next
      if (abs(r[i, j]) < r_threshold) keep[i, j] <- FALSE
      if (is.na(p_adj[i, j]) || p_adj[i, j] > sig_level) keep[i, j] <- FALSE
    }
  }
  drawn <- r
  drawn[!keep] <- NA

  # ---- Sector gaps ----------------------------------------------------------
  # gap AFTER each sector: node_gap within a group, group_gap at boundaries
  next_grp <- c(grp[-1], grp[1])          # group of the following sector (wraps)
  gaps <- ifelse(grp == next_grp, node_gap, group_gap)

  # ---- Draw -----------------------------------------------------------------
  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op), add = TRUE)
  # leave room on the right for the legend / colour bar
  right_pad <- if (legend || colorbar) 9 else 1
  graphics::par(mar = c(1, 1, if (is.null(title)) 1 else 3, right_pad))

  lim <- 1 + label_pad
  circlize::circos.clear()
  circlize::circos.par(
    gap.after = gaps,
    start.degree = start_degree,
    cell.padding = c(0, 0, 0, 0),
    points.overflow.warning = FALSE,
    canvas.xlim = c(-lim, lim),
    canvas.ylim = c(-lim, lim)
  )
  circlize::circos.initialize(factors = factor(ord_vars, levels = ord_vars),
                              xlim = c(0, 1))

  # Category tiles + labels
  circlize::circos.track(
    ylim = c(0, 1), track.height = tile_height, bg.border = NA,
    panel.fun = function(x, y) {
      s <- circlize::get.cell.meta.data("sector.index")
      xl <- circlize::get.cell.meta.data("xlim")
      circlize::circos.rect(xl[1], 0, xl[2], 1,
                            col = node_cols[[s]], border = tile_border)
      circlize::circos.text(
        mean(xl), 1 + label_r_offset / tile_height,
        labels = lab_map[[s]], facing = "clockwise", niceFacing = TRUE,
        adj = c(0, 0.5), cex = label_cex
      )
    }
  )

  # Links, weakest first so strong ones sit on top
  idx <- which(keep, arr.ind = TRUE)
  if (nrow(idx)) {
    if (sort_links) idx <- idx[order(abs(r[idx])), , drop = FALSE]
    for (k in seq_len(nrow(idx))) {
      i <- idx[k, 1]; j <- idx[k, 2]
      circlize::circos.link(
        ord_vars[i], 0.5, ord_vars[j], 0.5,
        col = col_fun(r[i, j]), lwd = link_lwd
      )
    }
  }

  if (!is.null(title)) graphics::title(main = title)

  # ---- Legends --------------------------------------------------------------
  if (legend || colorbar) {
    .draw_wheel_legends(
      colmap = colmap,
      col_fun = col_fun,
      r_limits = r_limits,
      show_legend = legend,
      show_colorbar = colorbar,
      legend_title = legend_title,
      colorbar_title = colorbar_title
    )
  }

  circlize::circos.clear()

  invisible(list(
    vars = ord_vars, groups = grp, colors = colmap,
    col_fun = col_fun, matrix = drawn, p_adjusted = p_adj,
    n_links = sum(keep), n_tests = n_tests, adjust = adjust
  ))
}
