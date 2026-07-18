# Correlation wheel plots with circlecorR

``` r

library(circlecorR)
```

## Motivation

A traditional correlation matrix carries a large amount of **redundant
information**. For $`k`$ variables it has $`k^2`$ cells, but only
$`k(k-1)/2`$ of them are unique: the diagonal is all self-correlations
($`r = 1`$), the two triangles mirror each other, and large blocks of
*within-category* correlations (symptom–symptom, metric–metric) are
often not the question being asked. As $`k`$ grows, the interesting
**between-category** relationships are buried in this redundancy and the
figure becomes unreadable.

The **correlation wheel** was introduced by Gharibans and colleagues to
cut through this: variables sit around a circle, grouped by category,
and only the correlations of interest are drawn as curved links coloured
by their coefficient (Gharibans et al. 2019). `circlecorR` reproduces
that figure natively in R and makes the grouping, colours, and
statistics configurable.

## The simplest path: straight from your data

Most datasets have **one row per subject** and **one column per
variable**. You do not need to build correlation matrices yourself –
hand that data frame directly to
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
and it computes the correlations (and p-values) for you.

The only other thing you supply is `groups`: a named list mapping each
category to its variables. This both **selects** which variables appear
(any other columns, such as an ID, are ignored) and sets their **order**
around the wheel.

``` r

groups <- list(
  Demographics = c("Age", "BMI"),
  Metrics      = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"),
  Symptoms     = c("Nausea", "Early satiety", "Bloating",
                   "Upper GI pain", "Lower GI pain", "Heartburn"),
  Scores       = c("GCSI", "PAGI-SYM", "PAGI-QoL", "EQ-5D")
)
```

``` r

# `gastro_symptoms` is a synthetic per-row example dataset shipped with the package
head(gastro_symptoms[, 1:5])
#>   Age  BMI Amplitude Fed-Fasted AR Frequency
#> 1  74 41.0  30.26932     2.0004345  2.808546
#> 2  51 42.8  29.15670     0.7884043  1.760702
#> 3  59 36.2  29.73068     0.1899037  3.483917
#> 4  47 40.8  31.16330    -0.8294263  2.842009
#> 5  29 46.1  31.07111     0.9579552  4.015299
#> 6  50 36.4  29.86780    -2.0601868  1.179358

corr_wheel(
  gastro_symptoms,             # raw data: one row per subject
  groups      = groups,
  method      = "pearson",     # correlation method
  adjust      = "hochberg",    # multiple-comparison adjustment (see below)
  sig_level   = 0.05,          # hide links with adjusted p > 0.05
  r_threshold = 0.3,           # ...and links with |r| < 0.3
  r_limits    = c(-0.6, 0.6)
)
```

![](circlecorR_files/figure-html/raw-data-1.png)

## Hiding self- and within-category correlations

Two of the wheel’s most important features are that it **never draws
self-correlations** (the diagonal) and, by default, **hides
within-category correlations** (`hide_within_group = TRUE`). This
removes exactly the redundant parts of the matrix and leaves the
between-category structure.

Crucially, this is carried through to the **statistics**.
Multiple-comparison correction penalises you for the number of
hypotheses tested. If self- and within-category correlations are never
tested, they should not count towards that family.
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
therefore applies the adjustment over **only the correlations it
displays**. Shrinking the family makes the correction less severe – so
power improves – while remaining statistically consistent with what is
shown.

``` r

res <- corr_wheel(gastro_symptoms, groups = groups, adjust = "hochberg",
                  r_threshold = 0.3, r_limits = c(-0.6, 0.6))
```

![](circlecorR_files/figure-html/family-1.png)

``` r


k <- length(unlist(groups))
cat("Unique correlations in the full matrix:", k * (k - 1) / 2, "\n")
#> Unique correlations in the full matrix: 120
cat("Correlations actually tested (the family):", res$n_tests, "\n")
#> Correlations actually tested (the family): 92
```

Because the family is smaller, each raw p-value is corrected by a
smaller factor. Taking Bonferroni for a transparent example, the *same*
correlation is penalised by the number of tests in its family – here 92
rather than 120:

``` r

p_raw <- 5e-4                       # a raw p-value for one correlation
k_all <- k * (k - 1) / 2

cat("Bonferroni across the full matrix:", signif(p_raw * k_all, 3), "\n")
#> Bonferroni across the full matrix: 0.06
cat("Bonferroni across the family only:", signif(p_raw * res$n_tests, 3), "\n")
#> Bonferroni across the family only: 0.046
```

The step-up methods (`"holm"`, `"hochberg"`, `"BH"`) behave the same
way: fewer comparisons never gives a larger adjusted p-value, so hiding
redundant self- and within-category correlations can only help power.

If you pass a **pre-computed p-value matrix** instead of raw data, it is
taken as given (no re-adjustment), since it may already be corrected.

## Other inputs

[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
auto-detects what you pass:

- **raw data** (non-square) – correlations computed for you;
- a **correlation matrix** plus a matching `p` matrix;
- a **`circlecor`** object from
  [`compute_correlations()`](https://kriz98.github.io/circlecorR/reference/compute_correlations.md).

``` r

r <- as.matrix(read.csv("Rvalues.csv", row.names = 1))
p <- as.matrix(read.csv("Pvalues.csv", row.names = 1))
corr_wheel(r, p, groups = groups, r_threshold = 0.3)
```

## Customising the look

### Colours and labels

`colors` maps categories to colours; `labels` gives pretty display
names. Both are named vectors – specify only the ones you want to
change.

``` r

corr_wheel(
  gastro_symptoms, groups = groups, r_threshold = 0.3, r_limits = c(-0.6, 0.6),
  colors = c(Demographics = "#4C72B0", Metrics = "#DD8452",
             Symptoms = "#55A868", Scores = "#C44E52"),
  labels = c(`GA-RI` = "Rhythm index")
)
```

![](circlecorR_files/figure-html/colours-1.png)

### Size of blocks and lines

- `tile_height` – radial thickness of the category **blocks** (smaller =
  thinner).
- `link_lwd` – **line** width of the links (larger = thicker).

``` r

corr_wheel(
  gastro_symptoms, groups = groups, r_threshold = 0.3, r_limits = c(-0.6, 0.6),
  tile_height = 0.12,   # thicker blocks
  link_lwd    = 3       # thicker lines
)
```

![](circlecorR_files/figure-html/sizes-1.png)

### The diverging colour scale

`palette` sets the three colours at `c(-limit, 0, +limit)` and
`r_limits` the scale range.

``` r

corr_wheel(
  gastro_symptoms, groups = groups, r_threshold = 0.3,
  palette  = c("#2166AC", "white", "#B2182B"),   # blue - white - red
  r_limits = c(-0.5, 0.5)
)
```

![](circlecorR_files/figure-html/palette-1.png)

## Saving to a file

[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
draws on the active graphics device, so save it the usual way:

``` r

png("correlation_wheel.png", width = 2500, height = 2000, res = 300)
corr_wheel(gastro_symptoms, groups = groups, r_threshold = 0.3,
           r_limits = c(-0.6, 0.6))
dev.off()
```

## References

Gharibans, Armen A., Todd P. Coleman, Hayat Mousa, and David C. Kunkel.
2019. “Spatial Patterns from High-Resolution Electrogastrography
Correlate with Severity of Symptoms in Patients with Functional
Dyspepsia and Gastroparesis.” *Clinical Gastroenterology and Hepatology*
17 (13): 2668–77. <https://doi.org/10.1016/j.cgh.2019.04.039>.
