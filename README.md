# Matlab-EMM
Matlab function which calculates ANCOVA and performs multiple comparison based on estimated marginal means. By default significance level is set at 0.05.
Should calculate same values as if you do in SPSS:  
Analyze -> General Linear Model -> Univariate -> Options -> Compare main effects for <fixed_variable>  
Verified against SPSS 22.
#Usage
```matlab
tab = adjustedPostHoc(dependent_variable, fixed_variable, covariate,"bonferroni");
```

