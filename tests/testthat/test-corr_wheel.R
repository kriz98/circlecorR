grp <- list(
  Demographics = c("Age", "BMI"),
  Metrics      = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"),
  Symptoms     = c("Nausea", "Early satiety", "Bloating", "Upper GI pain",
                   "Lower GI pain", "Heartburn"),
  Scores       = c("GCSI", "PAGI-SYM", "PAGI-QoL", "EQ-5D")
)

test_that("corr_wheel computes correlations straight from a data frame", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_symptoms, groups = grp)
  expect_type(res, "list")
  expect_setequal(res$vars, unlist(grp, use.names = FALSE))
  # ordered by group
  expect_equal(res$vars[1:2], c("Age", "BMI"))
  expect_true(res$n_links >= 1)
  expect_true(is.function(res$col_fun))
})

test_that("raw data ignores extra (non-grouped) columns like IDs", {
  pdf(NULL)
  on.exit(dev.off())
  d <- gastro_symptoms
  d$patient_id <- as.character(seq_len(nrow(d)))  # would break psych if used
  res <- corr_wheel(d, groups = grp, r_threshold = 0.3)
  expect_false("patient_id" %in% res$vars)
})

test_that("hide_within_group removes intra-category links", {
  pdf(NULL)
  on.exit(dev.off())
  hidden <- corr_wheel(gastro_symptoms, groups = grp, hide_within_group = TRUE)
  shown  <- corr_wheel(gastro_symptoms, groups = grp, hide_within_group = FALSE)
  expect_lt(hidden$n_links, shown$n_links)
})

test_that("hiding within-category shrinks the comparison family (n_tests)", {
  pdf(NULL)
  on.exit(dev.off())
  hidden <- corr_wheel(gastro_symptoms, groups = grp, hide_within_group = TRUE)
  shown  <- corr_wheel(gastro_symptoms, groups = grp, hide_within_group = FALSE)
  expect_lt(hidden$n_tests, shown$n_tests)
})

test_that("significance and r thresholds reduce link count", {
  pdf(NULL)
  on.exit(dev.off())
  loose  <- corr_wheel(gastro_symptoms, groups = grp, sig_level = 1, r_threshold = 0)
  strict <- corr_wheel(gastro_symptoms, groups = grp, sig_level = 0.05,
                       r_threshold = 0.4)
  expect_lte(strict$n_links, loose$n_links)
})

test_that("self-correlations are never drawn", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_symptoms, groups = grp, sig_level = 1, r_threshold = 0)
  expect_true(all(is.na(diag(res$matrix))))
})

test_that("custom colours and labels are honoured", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(
    gastro_symptoms, groups = grp,
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
  expect_error(corr_wheel(gastro_symptoms, groups = bad), "NotAVariable")
})

test_that("dropping a variable from groups excludes it (not an error)", {
  pdf(NULL)
  on.exit(dev.off())
  sub <- grp
  sub$Scores <- setdiff(sub$Scores, "EQ-5D")
  res <- corr_wheel(gastro_symptoms, groups = sub)
  expect_false("EQ-5D" %in% res$vars)
  expect_equal(length(res$vars), 15L)
})

test_that("compute_correlations returns raw (unadjusted) symmetric p", {
  cc <- compute_correlations(gastro_symptoms)
  expect_s3_class(cc, "circlecor")
  expect_true(isSymmetric(unname(cc$p)))
  # raw p should match a direct cor.test on a pair
  pr <- stats::cor.test(gastro_symptoms$Nausea, gastro_symptoms$GCSI)$p.value
  expect_equal(cc$p["Nausea", "GCSI"], pr, tolerance = 1e-6)
})

test_that("family-restricted adjustment is no less powerful than global", {
  vars <- unlist(grp, use.names = FALSE)
  cc <- compute_correlations(gastro_symptoms[, vars, drop = FALSE])
  grp_of <- stats::setNames(rep(names(grp), lengths(grp)), vars)

  idx <- which(upper.tri(cc$p), arr.ind = TRUE)
  p_raw <- cc$p[idx]
  is_family <- grp_of[vars[idx[, 1]]] != grp_of[vars[idx[, 2]]]

  # Family adjustment (what corr_wheel does): correct only across cross-
  # category pairs.
  p_family_adj <- stats::p.adjust(p_raw[is_family], method = "holm")
  # Global adjustment: correct across every off-diagonal pair, then look at
  # just the family pairs for a fair comparison.
  p_global_adj <- stats::p.adjust(p_raw, method = "holm")[is_family]

  # Fewer comparisons in the family -> smaller adjusted p -> at least as many
  # significant results as adjusting over the full matrix.
  expect_gte(sum(p_family_adj <= 0.05), sum(p_global_adj <= 0.05))
})

test_that("corr_wheel_schemes lists the built-in schemes", {
  s <- corr_wheel_schemes()
  expect_true(all(c("default", "colorblind", "ocean", "vivid", "alimetry") %in% s))
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
  res <- corr_wheel(gastro_symptoms, groups = grp, scheme = "colorblind")
  expect_equal(unname(res$colors), .cycle_colors(names(res$colors), s$colors)[names(res$colors)] |> unname())
  # the diverging palette actually changed the link colour function
  expect_match(unname(res$col_fun(0)), "^#F7F7F7")
})

test_that("explicit colors/palette override the scheme on top", {
  pdf(NULL)
  on.exit(dev.off())
  res <- corr_wheel(gastro_symptoms, groups = grp, scheme = "colorblind",
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
  expect_error(corr_wheel(gastro_symptoms, groups = grp, scheme = "nope"), "Unknown scheme")
})

test_that("a custom list scheme works and validates palette length", {
  pdf(NULL)
  on.exit(dev.off())
  custom <- list(colors = c("#111111", "#222222"), palette = c("blue", "white", "red"))
  res <- corr_wheel(gastro_symptoms, groups = grp, scheme = custom)
  expect_equal(unname(res$colors["Demographics"]), "#111111")

  bad <- list(colors = c("#111111"), palette = c("blue", "red"))  # length 2, invalid
  expect_error(corr_wheel(gastro_symptoms, groups = grp, scheme = bad), "length 3")
})
