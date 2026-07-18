# Compute a correlation matrix and (raw) p-values from raw data

A thin wrapper around
[`psych::corr.test()`](https://rdrr.io/pkg/psych/man/corr.test.html)
that returns the correlation (`r`) and **unadjusted** p-value (`p`)
matrices bundled in a single object suitable for passing straight to
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md).

## Usage

``` r
compute_correlations(
  data,
  vars = NULL,
  method = c("pearson", "spearman", "kendall"),
  use = "pairwise.complete.obs"
)
```

## Arguments

- data:

  A data frame or matrix of observations (rows) by variables (columns).

- vars:

  Optional character vector selecting and ordering the columns of `data`
  to use. Defaults to all columns.

- method:

  Correlation method, passed to
  [`psych::corr.test()`](https://rdrr.io/pkg/psych/man/corr.test.html).
  One of `"pearson"`, `"spearman"`, `"kendall"`.

- use:

  Handling of missing values, passed to
  [`psych::corr.test()`](https://rdrr.io/pkg/psych/man/corr.test.html).

## Value

An object of class `"circlecor"`: a list with elements `r` (the
correlation matrix), `p` (a symmetric matrix of **raw**, unadjusted
p-values), `n` (the pairwise sample sizes from `psych`), and `method`.

## Details

Multiple-comparison adjustment is deliberately **not** applied here. On
a correlation wheel, self-correlations and (usually) within-category
correlations are never tested, so they should not count towards the
family of comparisons.
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
therefore applies the adjustment itself, over exactly the set of
correlations it displays – which is both statistically consistent and
more powerful than adjusting across the full matrix. See the `adjust`
and `hide_within_group` arguments of
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md).

## See also

[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)

## Examples

``` r
if (requireNamespace("psych", quietly = TRUE)) {
  cc <- compute_correlations(mtcars, method = "pearson")
  str(cc)
}
#> List of 4
#>  $ r     : num [1:11, 1:11] 1 -0.852 -0.848 -0.776 0.681 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:11] "mpg" "cyl" "disp" "hp" ...
#>   .. ..$ : chr [1:11] "mpg" "cyl" "disp" "hp" ...
#>  $ p     : num [1:11, 1:11] 0.00 6.11e-10 9.38e-10 1.79e-07 1.78e-05 ...
#>   ..- attr(*, "dimnames")=List of 2
#>   .. ..$ : chr [1:11] "mpg" "cyl" "disp" "hp" ...
#>   .. ..$ : chr [1:11] "mpg" "cyl" "disp" "hp" ...
#>  $ n     : num 32
#>  $ method: chr "pearson"
#>  - attr(*, "class")= chr "circlecor"
```
