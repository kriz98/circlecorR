# Generate SYNTHETIC example data for circlecorR.
# This is fully simulated -- it is NOT patient data. It mimics the *structure*
# of a gastric-symptom study (demographics, gastric metrics, symptom
# sub-scales, and summary scores). Loadings are deliberately moderate and
# uneven -- some variables are essentially noise -- so the resulting wheel has
# a realistic, sparse set of significant links (like a real study figure)
# rather than everything correlating with everything.

set.seed(2024)
n <- 100

# Latent "disease severity" drives symptoms up and quality of life / gastric
# function down.
severity <- rnorm(n)

# helper: loading on severity + independent noise
sev <- function(load, noise = 1) load * severity + rnorm(n, sd = noise)

gastro_symptoms <- data.frame(
  # Demographics: mostly unrelated to severity (few links expected)
  Age        = round(rnorm(n, 45, 13)),
  BMI        = round(sev(0.25, 1.2) * 4 + 40, 1),   # weak link only

  # Gastric metrics: better function -> lower severity (negative loadings)
  Amplitude  = sev(-0.45, 1.0) + 30,
  ff_AR      = rnorm(n),                             # pure noise (no links)
  PGF        = sev(-0.60, 0.9) + 2.7,
  GA_RI      = sev(-0.50, 0.9) + 0.5,

  # Symptom sub-scales: higher severity -> worse symptoms (positive loadings)
  Nausea     = pmax(0, sev(0.70, 1.0) + 2),
  Satiety    = pmax(0, sev(0.75, 1.0) + 2),
  Bloating   = pmax(0, sev(0.60, 1.1) + 2),
  Upper_pain = pmax(0, sev(0.70, 1.0) + 2),
  Lower_pain = pmax(0, sev(0.30, 1.2) + 2),          # weak link
  Heartburn  = pmax(0, sev(0.55, 1.1) + 2),

  stringsAsFactors = FALSE
)

# Summary scores: composites of the symptom sub-scales (strong), plus two
# quality-of-life scores that fall as severity rises.
sx <- with(gastro_symptoms,
           Nausea + Satiety + Bloating + Upper_pain + Heartburn)
gastro_symptoms$GCSI    <- scale(sx)[, 1] * 1.0 + rnorm(n, 0, 0.6) + 3
gastro_symptoms$PAGISYM <- scale(sx)[, 1] * 0.9 + rnorm(n, 0, 0.7) + 3
gastro_symptoms$PAGIQOL <- sev(-0.55, 0.9) + 3
gastro_symptoms$EQ5D    <- sev(-0.45, 1.0) + 0.8

# Column order used throughout the package examples
ord <- c("Age", "BMI",
         "Amplitude", "ff_AR", "PGF", "GA_RI",
         "Nausea", "Satiety", "Bloating", "Upper_pain", "Lower_pain", "Heartburn",
         "GCSI", "PAGISYM", "PAGIQOL", "EQ5D")
gastro_symptoms <- gastro_symptoms[, ord]

# Clean, human-readable column names for the example / figures
clean <- c(
  Age = "Age", BMI = "BMI",
  Amplitude = "Amplitude", ff_AR = "Fed-Fasted AR",
  PGF = "Frequency", GA_RI = "GA-RI",
  Nausea = "Nausea", Satiety = "Early satiety", Bloating = "Bloating",
  Upper_pain = "Upper GI pain", Lower_pain = "Lower GI pain",
  Heartburn = "Heartburn",
  GCSI = "GCSI", PAGISYM = "PAGI-SYM", PAGIQOL = "PAGI-QoL", EQ5D = "EQ-5D"
)
names(gastro_symptoms) <- unname(clean[names(gastro_symptoms)])

# Correlation object (r + raw p) via the package's own helper
suppressMessages(devtools::load_all("."))
gastro_cor <- compute_correlations(gastro_symptoms, method = "pearson")

usethis::use_data(gastro_symptoms, overwrite = TRUE)
usethis::use_data(gastro_cor, overwrite = TRUE)
