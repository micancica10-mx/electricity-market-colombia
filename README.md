# Energy Price Volatility and Renewable Energy Generation in Colombia: A Multivariate GARCH Approach

## Overview

This project examines the interdependence between electricity price volatility and electricity generation from non-conventional renewable energy sources (NCRES) and hydropower in Colombia. Using daily observations from January 2018 to July 2022, it applies univariate GARCH models and a multivariate Dynamic Conditional Correlation GARCH (DCC-GARCH) framework to investigate time-varying volatility and correlations across electricity-market variables.

The analysis focuses on four series: the electricity spot price, the bid price of hydropower plants, NCRES generation, and hydropower availability.

## Research question

How are volatility in Colombian electricity prices and fluctuations in renewable electricity generation related over time?

## Data

The analysis uses daily data for **January 2018–July 2022**, obtained from the dataset used in:

> Cardona-Vasquez, D., Garcia-Rendon, J., & Arango-Manrique, A. (2024). *Effect of the intermittency of non-conventional renewable energy sources on the volatility of the Colombian spot price*. Renewable Energy, 232. https://doi.org/10.1016/j.renene.2024.121073

Variables used in the R script:

| Variable in code | Description |
| --- | --- |
| `pbolsa` | Electricity spot price |
| `pofe_hidro` | Hydropower bid price |
| `gen_frnc` | Electricity generation from non-conventional renewable energy sources |
| `disp_hidro` | Hydropower availability |

**Data availability:** The dataset is not redistributed in this repository. Refer to the cited article and any accompanying data-availability information for access and reuse conditions. The script expects an Excel workbook named `data.xlsx` with worksheets `data_dc`, `data_nces`, and `data_cap` (the last is loaded but not used in the main analysis).

## Empirical approach

1. **Exploratory analysis:** Summary statistics, time-series plots, log differences, distributional diagnostics, and autocorrelation functions.
2. **Time-series diagnostics:** Normality tests, Augmented Dickey–Fuller and Phillips–Perron unit-root tests, and ARCH-effect tests.
3. **Univariate volatility models:** ARIMA specifications for the conditional mean and GJR-GARCH(1,1) specifications for conditional volatility.
4. **Multivariate volatility model:** A DCC-GARCH(1,1) model to estimate time-varying conditional correlations and covariances among the four variables.
5. **Shock simulations:** Comparison of simulated conditional variances under shocked and baseline scenarios over a 60-period horizon.

The analysis is descriptive and econometric; conditional correlations and shock simulations should not be interpreted as causal estimates without additional identifying assumptions.

## Repository contents

- `electricity_market_volatility.R` — R script for data preparation, diagnostics, ARIMA/GJR-GARCH estimation, DCC-GARCH estimation, and conditional-variance shock simulations.
- `README.md` — Project overview and methodological documentation.

## Software and reproducibility

To run the analysis:

1. Obtain the data from an authorized source and place `data.xlsx` in your local project directory.
2. Install the R packages listed at the beginning of the script.
3. Update the local working-directory setting in the script or run it from the project directory.
4. Execute the script in R or RStudio.

## Reference

Cardona-Vasquez, D., Garcia-Rendon, J., & Arango-Manrique, A. (2024). Effect of the intermittency of non-conventional renewable energy sources on the volatility of the Colombian spot price. *Renewable Energy, 232*. https://doi.org/10.1016/j.renene.2024.121073
