grp <- list(
  Demographics = c("Age", "BMI"),
  Metrics      = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"),
  Symptoms     = c("Nausea", "Early satiety", "Bloating", "Upper GI pain",
                   "Lower GI pain", "Heartburn"),
  Scores       = c("GCSI", "PAGI-SYM", "PAGI-QoL", "EQ-5D")
)

test_that("corr_wheel runs on a circlecor object and returns structure", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_cor, groups = grp)
  expect_type(res, "list")
  expect_setequal(res$vars, colnames(gastro_cor$r))
  # ordered by group
  expect_equal(res$vars[1:2], c("Age", "BMI"))
  expect_true(res$n_links >= 1)
  expect_true(is.function(res$col_fun))
})

test_that("corr_wheel accepts bare r/p matrices", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_cor$r, gastro_cor$p, groups = grp)
  expect_true(res$n_links >= 1)
})

test_that("hide_within_group removes intra-category links", {
  pdf(NULL)
  on.exit(dev.off())
  hidden <- corr_wheel(gastro_cor, groups = grp, hide_within_group = TRUE)
  shown  <- corr_wheel(gastro_cor, groups = grp, hide_within_group = FALSE)
  expect_lt(hidden$n_links, shown$n_links)
})

test_that("significance and r thresholds reduce link count", {
  pdf(NULL)
  on.exit(dev.off())
  loose  <- corr_wheel(gastro_cor, groups = grp, sig_level = 1, r_threshold = 0)
  strict <- corr_wheel(gastro_cor, groups = grp, sig_level = 0.05,
                       r_threshold = 0.4)
  expect_lte(strict$n_links, loose$n_links)
})

test_that("custom colours and labels are honoured", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(
    gastro_cor, groups = grp,
    colors = c(Symptoms = "#000000"),
    labels = c(Age = "Age (yrs)")
  )
  expect_equal(unname(res$colors["Symptoms"]), "#000000")
})

test_that("a grouped variable absent from the input errors", {
  pdf(NULL)
  on.exit(dev.off())
  bad <- grp
  bad$Scores <- c(bad$Scores, "NotAVariable")
  expect_error(corr_wheel(gastro_cor, groups = bad), "NotAVariable")
})

test_that("dropping a variable from groups excludes it (not an error)", {
  pdf(NULL)
  on.exit(dev.off())
  sub <- grp
  sub$Scores <- setdiff(sub$Scores, "EQ-5D")
  res <- corr_wheel(gastro_cor, groups = sub)
  expect_false("EQ-5D" %in% res$vars)
  expect_equal(length(res$vars), 15L)
})

test_that("corr_wheel computes correlations straight from raw data", {
  skip_if_not_installed("psych")
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_symptoms, groups = grp, r_threshold = 0.3)
  expect_setequal(res$vars, unlist(grp, use.names = FALSE))
  expect_true(res$n_links >= 1)
})

test_that("raw data ignores extra (non-grouped) columns like IDs", {
  skip_if_not_installed("psych")
  pdf(NULL)
  on.exit(dev.off())
  d <- gastro_symptoms
  d$patient_id <- as.character(seq_len(nrow(d)))  # would break psych if used
  res <- corr_wheel(d, groups = grp, r_threshold = 0.3)
  expect_false("patient_id" %in% res$vars)
})

test_that("passing p alongside raw data errors", {
  skip_if_not_installed("psych")
  expect_error(
    corr_wheel(gastro_symptoms, p = gastro_cor$p, groups = grp),
    "raw data"
  )
})

test_that(".looks_like_cor distinguishes matrices from raw data", {
  expect_true(.looks_like_cor(gastro_cor$r))
  expect_true(.looks_like_cor(gastro_cor))
  expect_false(.looks_like_cor(gastro_symptoms))
})

test_that("compute_correlations returns raw (unadjusted) symmetric p", {
  skip_if_not_installed("psych")
  cc <- compute_correlations(gastro_symptoms)
  expect_s3_class(cc, "circlecor")
  expect_true(isSymmetric(unname(cc$p)))
  # raw p should match a direct cor.test on a pair
  pr <- stats::cor.test(gastro_symptoms$Nausea, gastro_symptoms$GCSI)$p.value
  expect_equal(cc$p["Nausea", "GCSI"], pr, tolerance = 1e-6)
})

test_that("self-correlations are never drawn", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_cor, groups = grp, sig_level = 1, r_threshold = 0)
  expect_true(all(is.na(diag(res$matrix))))
})

test_that("hiding within-category shrinks the comparison family (n_tests)", {
  pdf(NULL)
  on.exit(dev.off())
  hidden <- corr_wheel(gastro_cor, groups = grp, hide_within_group = TRUE)
  shown  <- corr_wheel(gastro_cor, groups = grp, hide_within_group = FALSE)
  expect_lt(hidden$n_tests, shown$n_tests)
})

test_that("family-restricted adjustment is no less powerful than global", {
  skip_if_not_installed("psych")
  pdf(NULL)
  on.exit(dev.off())
  # Family adjustment (this package): adjust only across cross-category pairs.
  fam <- corr_wheel(gastro_cor, groups = grp, hide_within_group = TRUE,
                    adjust = "holm", r_threshold = 0)

  # Global adjustment: adjust across every off-diagonal pair, then mask.
  praw <- gastro_cor$p
  ut <- upper.tri(praw)
  padj_global <- praw
  padj_global[ut] <- stats::p.adjust(praw[ut], method = "holm")
  padj_global[lower.tri(padj_global)] <- t(padj_global)[lower.tri(padj_global)]
  glob <- corr_wheel(gastro_cor$r, padj_global, groups = grp,
                     hide_within_group = TRUE, r_threshold = 0)

  # Fewer comparisons -> smaller adjusted p -> at least as many significant.
  expect_gte(fam$n_links, glob$n_links)
})

test_that("non-square r matrix errors", {
  expect_error(.as_cor_matrix(matrix(1:6, 2, 3)), "square")
})

test_that("p symmetrisation mirrors the requested triangle", {
  # column-major fill: m["b","a"] (lower) = 0.01, m["a","b"] (upper) = 0.9
  m <- matrix(c(0, 0.01, 0.9, 0), 2, 2,
              dimnames = list(c("a", "b"), c("a", "b")))
  lo <- .symmetrise_p(m, from = "lower")
  expect_equal(lo["a", "b"], lo["b", "a"])
  expect_equal(lo["a", "b"], 0.01)  # lower-triangle value mirrored up
  up <- .symmetrise_p(m, from = "upper")
  expect_equal(up["a", "b"], 0.9)   # upper-triangle value mirrored down
})

test_that("corr_wheel_schemes lists the built-in schemes", {
  s <- corr_wheel_schemes()
  expect_true(all(c("default", "colorblind", "ocean", "vivid") %in% s))
})

test_that("corr_wheel_scheme returns a colors/palette list", {
  s <- corr_wheel_scheme("colorblind")
  expect_true(all(c("colors", "palette") %in% names(s)))
  expect_length(s$palette, 3)
  expect_error(corr_wheel_scheme("not_a_scheme"))
})

test_that("built-in scheme category colours are all distinct", {
  for (nm in corr_wheel_schemes()) {
    cols <- corr_wheel_scheme(nm)$colors
    expect_equal(length(unique(cols)), length(cols), info = nm)
  }
})

test_that("scheme sets category colours and link palette", {
  pdf(NULL)
  on.exit(dev.off())
  s <- corr_wheel_scheme("colorblind")
  res <- corr_wheel(gastro_cor, groups = grp, scheme = "colorblind")
  expect_equal(unname(res$colors), .cycle_colors(names(res$colors), s$colors)[names(res$colors)] |> unname())
  # the diverging palette actually changed the link colour function
  expect_match(unname(res$col_fun(0)), "^#F7F7F7")
})

test_that("explicit colors/palette override the scheme on top", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_cor, groups = grp, scheme = "colorblind",
                    colors = c(Scores = "#000000"),
                    palette = c("green", "white", "purple"))
  expect_equal(unname(res$colors["Scores"]), "#000000")
  # other categories still come from the scheme, not the default
  expect_equal(unname(res$colors["Demographics"]),
              unname(corr_wheel_scheme("colorblind")$colors[1]))
})

test_that("unknown scheme name errors informatively", {
  pdf(NULL)
  on.exit(dev.off())
  expect_error(corr_wheel(gastro_cor, groups = grp, scheme = "nope"), "Unknown scheme")
})

test_that("a custom list scheme works and validates palette length", {
  pdf(NULL)
  on.exit(dev.off())
  custom <- list(colors = c("#111111", "#222222"), palette = c("blue", "white", "red"))
  res <- corr_wheel(gastro_cor, groups = grp, scheme = custom)
  expect_equal(unname(res$colors["Demographics"]), "#111111")

  bad <- list(colors = c("#111111"), palette = c("blue", "red"))  # length 2, invalid
  expect_error(corr_wheel(gastro_cor, groups = grp, scheme = bad), "length 3")
})
