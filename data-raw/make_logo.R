# Generate the circlecorR hex-sticker logo as a hand-authored vector SVG
# (the canonical asset, committed at man/figures/logo.svg), then rasterise a
# PNG copy for tools that need a raster (pkgdown favicons, non-SVG contexts).
#
# Design: a sleek, blue-gradient "premium tech" hex. A single thin gradient
# halo ring stands in for the category tiles, and a handful of gently bowed
# gradient chords (mostly cool blues, a couple of warm accents for the
# diverging-correlation idea) cross it -- restrained rather than a flat
# multi-colour pie, which read as busy/childish in the previous version.

# --- Geometry (pointy-top hexagon, the standard hex-sticker proportions) --
H  <- 1200
r  <- H / 2
W  <- sqrt(3) * r
cx <- W / 2
cy <- H / 2

hex <- sprintf(
  "M %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f L %.2f %.2f Z",
  cx, 0,  W, r / 2,  W, H - r / 2,  cx, H,  0, H - r / 2,  0, r / 2
)

deg2rad <- function(d) d * pi / 180

# --- The halo ring -----------------------------------------------------
ring_cx <- cx
ring_cy <- 470
R_ring  <- 235

# --- Chords: gentle bows across the ring, blue-dominant with two warm
# accents (nodding at the diverging correlation colour scale without going
# full rainbow) --------------------------------------------------------
node_deg <- c(-90, -45, 0, 45, 90, 135, 180, 225)   # 8 compass points
node_x <- ring_cx + R_ring * cos(deg2rad(node_deg))
node_y <- ring_cy + R_ring * sin(deg2rad(node_deg))

# pairs index into node_deg (1=-90 top ... 8=225 upper-left)
pairs <- rbind(
  c(1, 4), c(2, 7), c(3, 6), c(8, 4), c(2, 5), c(1, 6)
)
# solid tones, not per-chord gradients -- one hero gradient (the ring) is
# plenty; flat colour keeps the linework calm and legible
chord_col <- c("#EAF4FF", "#5EA8F2", "#F0834D", "#2E5FD1", "#8FC1F7", "#F0834D")
chord_w   <- c(7, 6, 7, 5, 6, 5)
chord_op  <- c(.85, .6, .85, .5, .55, .55)

pull <- 0.62   # 0 = straight line, 1 = bow fully through the ring centre
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
    chord_col[k], chord_w[k], chord_op[k]
  )
}, character(1))

# --- Assemble SVG -------------------------------------------------------
svg <- sprintf('<svg xmlns="http://www.w3.org/2000/svg" width="%.2f" height="%d" viewBox="0 0 %.2f %d">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="0.6" y2="1">
      <stop offset="0%%"   stop-color="#1E40AF"/>
      <stop offset="100%%" stop-color="#0C1440"/>
    </linearGradient>
    <linearGradient id="ringGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%%"   stop-color="#D6EAFF"/>
      <stop offset="100%%" stop-color="#4C8DF0"/>
    </linearGradient>
    <clipPath id="hexClip"><path d="%s"/></clipPath>
  </defs>

  <path d="%s" fill="url(#bg)"/>

  <g clip-path="url(#hexClip)">
    <!-- halo ring -->
    <circle cx="%.1f" cy="%.1f" r="%.1f" fill="none" stroke="url(#ringGrad)"
            stroke-width="14" opacity="0.95"/>

    <!-- correlation chords -->
    %s
  </g>

  <!-- wordmark -->
  <text x="%.1f" y="860" text-anchor="middle"
        font-family="Avenir Next, Century Gothic, Futura, Helvetica Neue, Arial, sans-serif"
        font-size="100" font-weight="500" fill="#F7FAFF"
        letter-spacing="1.5">circlecorR</text>

  <!-- thin hex border -->
  <path d="%s" fill="none" stroke="#9DC4FF" stroke-width="5" opacity="0.45"/>
</svg>',
  W, H, W, H,
  hex,
  hex,
  ring_cx, ring_cy, R_ring,
  paste(chords, collapse = "\n    "),
  cx,
  hex
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
