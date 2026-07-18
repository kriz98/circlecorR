# Generate the circlecorR hex-sticker logo as a hand-authored vector SVG
# (the canonical asset, committed at man/figures/logo.svg), then rasterise a
# PNG copy for tools that need a raster (pkgdown favicons, non-SVG contexts).
#
# Design: matches Alimetry's brand ethos (from alimetry.com) -- a dark
# teal-to-navy diagonal gradient (not a light/pale surface), a vivid electric-
# cyan accent for the ring and chords (their CTA-button/headline colour), a
# white wordmark, and softly rounded (squircle-like) corners echoing their
# rounded-pill buttons/badges. The halo ring stays segmented like the
# category-tile ring in the actual plots, and the chords stay bold, per
# earlier feedback for stronger presence.
#
# Colours are approximated by eye from screenshots of alimetry.com, not taken
# from an official brand-colour spec -- swap the hex codes below if exact
# values are supplied later.

# --- Geometry (pointy-top hexagon, the standard hex-sticker proportions) --
H  <- 1200
r  <- H / 2
W  <- sqrt(3) * r
cx <- W / 2
cy <- H / 2

verts <- rbind(
  c(cx, 0), c(W, r / 2), c(W, H - r / 2),
  c(cx, H), c(0, H - r / 2), c(0, r / 2)
)

# Round every corner of a convex polygon by the same radius: at each vertex,
# move `radius` back along each incident edge and join those two points with
# a circular arc of that radius -- the standard "squircle-corner" construction.
rounded_polygon_path <- function(verts, radius) {
  n <- nrow(verts)
  get <- function(i) verts[((i - 1) %% n) + 1, ]
  unit <- function(v) v / sqrt(sum(v^2))

  p1 <- matrix(NA_real_, n, 2); p2 <- matrix(NA_real_, n, 2)
  for (i in seq_len(n)) {
    cur <- get(i); prv <- get(i - 1); nxt <- get(i + 1)
    p1[i, ] <- cur + unit(prv - cur) * radius
    p2[i, ] <- cur + unit(nxt - cur) * radius
  }

  d <- sprintf("M %.2f %.2f", p2[1, 1], p2[1, 2])
  for (i in 2:n) {
    d <- c(d, sprintf("L %.2f %.2f", p1[i, 1], p1[i, 2]),
           sprintf("A %.2f %.2f 0 0 1 %.2f %.2f", radius, radius, p2[i, 1], p2[i, 2]))
  }
  d <- c(d, sprintf("L %.2f %.2f", p1[1, 1], p1[1, 2]),
         sprintf("A %.2f %.2f 0 0 1 %.2f %.2f Z", radius, radius, p2[1, 1], p2[1, 2]))
  paste(d, collapse = " ")
}

hex <- rounded_polygon_path(verts, radius = 60)

deg2rad <- function(d) d * pi / 180

# --- The halo ring, segmented like the category-tile ring in the actual
# plots (a dashed circle) rather than a plain continuous one ---------------
ring_cx  <- cx
ring_cy  <- 470
R_ring   <- 235
n_seg    <- 15
circ     <- 2 * pi * R_ring
dash_on  <- circ / n_seg * 0.72
dash_gap <- circ / n_seg * 0.28

# --- Chords: gentle bows across the ring, monochrome blue -- bolder and
# more uniformly present than a whisper-thin sketch, for clearer presence -
node_deg <- c(-90, -45, 0, 45, 90, 135, 180, 225)   # 8 compass points
node_x <- ring_cx + R_ring * cos(deg2rad(node_deg))
node_y <- ring_cy + R_ring * sin(deg2rad(node_deg))

# pairs index into node_deg (1=-90 top ... 8=225 upper-left)
pairs <- rbind(
  c(1, 4), c(2, 7), c(3, 6), c(8, 4), c(2, 5), c(1, 6)
)
chord_col <- "#22C3F0"
chord_w   <- c(10, 8, 9, 7, 8, 7)
chord_op  <- c(.95, .7, .85, .6, .75, .65)

pull <- 0.6   # 0 = straight line, 1 = bow fully through the ring centre
chords <- vapply(seq_len(nrow(pairs)), function(k) {
  i <- pairs[k, 1]; j <- pairs[k, 2]
  mx <- (node_x[i] + node_x[j]) / 2
  my <- (node_y[i] + node_y[j]) / 2
  qx <- mx + (ring_cx - mx) * pull
  qy <- my + (ring_cy - my) * pull
  sprintf(
    paste0('<path d="M %.1f %.1f Q %.1f %.1f %.1f %.1f" fill="none" ',
           'stroke="%s" stroke-width="%.1f" stroke-linecap="round" ',
           'opacity="%.2f"/>'),
    node_x[i], node_y[i], qx, qy, node_x[j], node_y[j],
    chord_col, chord_w[k], chord_op[k]
  )
}, character(1))

# --- Assemble SVG -------------------------------------------------------
svg <- sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%.2f" height="%d" viewBox="0 0 %.2f %d">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0.75" y2="1">
      <stop offset="0%%"   stop-color="#1878A0"/>
      <stop offset="55%%"  stop-color="#0D3B5C"/>
      <stop offset="100%%" stop-color="#081420"/>
    </linearGradient>
    <clipPath id="hexClip"><path d="%s"/></clipPath>
    <filter id="softShadow" x="-40%%" y="-40%%" width="180%%" height="180%%">
      <feDropShadow dx="0" dy="10" stdDeviation="22" flood-color="#000000" flood-opacity="0.35"/>
    </filter>
    <filter id="glow" x="-60%%" y="-60%%" width="220%%" height="220%%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <path d="%s" fill="url(#bg)" filter="url(#softShadow)"/>

  <g clip-path="url(#hexClip)">
    <!-- halo ring, segmented like the category-tile ring in the real plots -->
    <circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="#22C3F0"
            stroke-width="20" stroke-dasharray="%.1f %.1f"
            stroke-linecap="round" opacity="0.95" filter="url(#glow)"/>

    <!-- correlation chords -->
    %s
  </g>

  <!-- wordmark -->
  <text x="%.1f" y="860" text-anchor="middle"
        font-family="Avenir Next, Century Gothic, Futura, Helvetica Neue, Arial, sans-serif"
        font-size="98" font-weight="600" fill="#FFFFFF"
        letter-spacing="1">circlecorR</text>
</svg>',
  W, H, W, H,
  hex,
  hex,
  ring_cx, ring_cy, R_ring, dash_on, dash_gap,
  paste(chords, collapse = "\n    "),
  cx
)

svg_path <- "man/figures/logo.svg"
writeLines(svg, svg_path)
cat("wrote", svg_path, "\n")

# --- Rasterise a PNG copy, preserving the true (non-square) aspect ratio --
# the hex is narrower than tall (W/H = sqrt(3)/2); forcing a square output
# here would stretch everything horizontally.
out <- "man/figures/logo.png"
png_h <- 1200
png_w <- round(png_h * W / H)
status <- system2("rsvg-convert",
                  c("-w", png_w, "-h", png_h, svg_path, "-o", out))
if (status != 0) stop("rsvg-convert failed")
cat("wrote", out, sprintf("(%dx%d)", png_w, png_h), "\n")
