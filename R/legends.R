# Draw the category legend and correlation colour bar in the right margin.
# Uses base graphics with clipping disabled so it can draw outside the circle.
.draw_wheel_legends <- function(colmap, col_fun, r_limits,
                                show_legend = TRUE, show_colorbar = TRUE,
                                legend_title = "Category",
                                colorbar_title = "Correlation\ncoefficient") {
  usr <- graphics::par("usr")
  old_xpd <- graphics::par("xpd")
  graphics::par(xpd = NA)
  on.exit(graphics::par(xpd = old_xpd), add = TRUE)

  x_right <- usr[2]
  span_x <- usr[2] - usr[1]
  span_y <- usr[4] - usr[3]

  # ---- Category legend (upper right) ---------------------------------------
  if (show_legend && length(colmap)) {
    lx <- x_right + 0.04 * span_x
    ly <- usr[4] - 0.02 * span_y
    sw <- 0.04 * span_x          # swatch size
    dy <- 0.06 * span_y          # line spacing

    graphics::text(lx, ly, labels = legend_title, adj = c(0, 0.5),
                   font = 2, cex = 0.9)
    cats <- names(colmap)
    for (i in seq_along(cats)) {
      yy <- ly - i * dy
      graphics::rect(lx, yy - sw / 2, lx + sw, yy + sw / 2,
                     col = colmap[i], border = "grey40")
      graphics::text(lx + sw + 0.02 * span_x, yy, labels = cats[i],
                     adj = c(0, 0.5), cex = 0.8)
    }
  }

  # ---- Colour bar (lower right) --------------------------------------------
  if (show_colorbar) {
    bx <- x_right + 0.06 * span_x
    bw <- 0.035 * span_x
    by0 <- usr[3] + 0.08 * span_y
    by1 <- by0 + 0.34 * span_y

    ncol <- 100
    ys <- seq(by0, by1, length.out = ncol + 1)
    vals <- seq(r_limits[1], r_limits[2], length.out = ncol)
    cols <- col_fun(vals)
    for (i in seq_len(ncol)) {
      graphics::rect(bx, ys[i], bx + bw, ys[i + 1], col = cols[i],
                     border = NA)
    }
    graphics::rect(bx, by0, bx + bw, by1, border = "grey40")

    ticks <- pretty(r_limits, n = 5)
    ticks <- ticks[ticks >= r_limits[1] & ticks <= r_limits[2]]
    ty <- by0 + (ticks - r_limits[1]) / diff(r_limits) * (by1 - by0)
    graphics::segments(bx + bw, ty, bx + bw + 0.01 * span_x, ty,
                       col = "grey40")
    graphics::text(bx + bw + 0.015 * span_x, ty, labels = ticks,
                   adj = c(0, 0.5), cex = 0.7)
    graphics::text(bx, by1 + 0.05 * span_y, labels = colorbar_title,
                   adj = c(0, 0), cex = 0.8, font = 2)
  }
}
