# Correlation matrices for the synthetic gastric-symptom dataset

A `"circlecor"` object (Pearson, Hochberg-adjusted) computed from
[gastro_symptoms](https://kriz98.github.io/circlecorR/reference/gastro_symptoms.md)
with
[`compute_correlations()`](https://kriz98.github.io/circlecorR/reference/compute_correlations.md).
Ready to pass to
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md).

## Usage

``` r
gastro_cor
```

## Format

A list of class `"circlecor"` with elements `r` (16x16 correlation
matrix) and `p` (16x16 p-value matrix).

## See also

[gastro_symptoms](https://kriz98.github.io/circlecorR/reference/gastro_symptoms.md),
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)
