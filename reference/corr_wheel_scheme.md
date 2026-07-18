# Get a built-in colour scheme

Returns the category-colour and diverging-link-palette definition for a
built-in scheme, so you can inspect it or tweak a copy before passing it
to
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)'s
`scheme` argument.

## Usage

``` r
corr_wheel_scheme(name = "default")
```

## Arguments

- name:

  A scheme name; see
  [`corr_wheel_schemes()`](https://kriz98.github.io/circlecorR/reference/corr_wheel_schemes.md)
  for the available options.

## Value

A list with elements `colors` (an unnamed vector of category colours,
cycled across however many categories are plotted) and `palette` (a
length-3 diverging colour vector: negative, midpoint, positive).

## See also

[`corr_wheel_schemes()`](https://kriz98.github.io/circlecorR/reference/corr_wheel_schemes.md),
[`corr_wheel()`](https://kriz98.github.io/circlecorR/reference/corr_wheel.md)

## Examples

``` r
s <- corr_wheel_scheme("colorblind")
s$palette
#> [1] "#E66101" "#F7F7F7" "#5E3C99"

# Tweak a copy and use it
s$palette[2] <- "grey95"
data(gastro_symptoms)
grp <- list(Demographics = c("Age", "BMI"),
           Metrics = c("Amplitude", "Fed-Fasted AR", "Frequency", "GA-RI"))
if (requireNamespace("psych", quietly = TRUE)) {
  corr_wheel(gastro_symptoms, groups = grp, scheme = s, r_threshold = 0)
}
```
