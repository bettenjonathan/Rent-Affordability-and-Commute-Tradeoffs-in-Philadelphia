# Philadelphia ZIP Code Affordability vs. Commute Analysis

## Overview
This project analyzes **Philadelphia ZIP codes** to identify areas that balance:

- Housing affordability (rent burden as a percent of income)
- Commute time (average minutes to work)

Using publicly available U.S. Census / American Community Survey (ACS) data, the analysis builds a reproducible workflow in **R and DuckDB SQL** to score and visualize livability across ZIP codes.

The goal of this project is to demonstrate a realistic, end-to-end data analysis pipeline suitable for entry-level data analyst roles

---

## Research Question
**Which Philadelphia ZIP codes provide the best balance between affordable housing and reasonable commute times?**

---

## Data Source
Data comes from the U.S. Census Bureau – American Community Survey (ACS) at the ZIP-code level.

Key variables used:

- Median rent  
- Median household income  
- Population  
- Average commute time  
- Share of commuters with 30+ minute commutes  
- Rent burden (% of income spent on housing)

Some ZIP codes contained missing or suppressed values due to:

- Small population sizes  
- Non-residential ZIP designations  
- Dataset merge inconsistencies  

These rows were excluded in code, while the original raw dataset was preserved for reproducibility.

---

## Methodology

### 1. Data Cleaning (DuckDB SQL)
- Converted numeric fields using `TRY_CAST`
- Removed percent symbols from rent burden values
- Filtered rows missing key modeling variables:
  - rent burden  
  - commute time  
  - population  

This produced a model-ready dataset for analysis.

---

### 2. Affordability–Commute Score
Each ZIP code received a 0–100 composite score based on:

- Rent burden 
- Average commute time 

Steps:

1. Applied min–max normalization to both variables  
2. Used equal 50/50 weighting  
3. Combined into a single interpretable score  

---

### 3. Livability Thresholds
ZIP codes were classified as livable if:

- **Rent burden < 30%**  
  - Standard U.S. housing affordability benchmark  
- **Average commute < 35 minutes**  
  - Approximate upper bound of typical U.S. commute times  

---

## Results

### Livability Distribution
Only a subset of Philadelphia ZIP codes meet both affordability and commute thresholds.

Many ZIP codes show a trade-off:

- Lower housing cost but longer commute  
- Short commute but higher housing cost  

This highlights the spatial tension between affordability and accessibility in urban housing markets.

---

### Highest-Scoring ZIP Codes
The analysis identifies the top ZIP codes that best balance affordability and commute efficiency.

Project outputs include:

- Scatter plot of rent burden vs. commute time  
- Bar chart of the top 10 ZIP codes by composite score  
- CSV export of scored ZIP-code results  

These visuals provide a clear, decision-ready summary of livable areas.

---

## Tools and Technologies

- **R** – data analysis and visualization  
- **DuckDB** – in-memory SQL data processing  
- **dplyr / ggplot2** – transformation and plotting  
- **U.S. Census ACS** – real public data source  

---

## Limitations

- Equal weighting of affordability and commute may not reflect all preferences  
- ZIP-code aggregation hides neighborhood-level variation  
- Commute time does not distinguish transit mode or traffic variability  

---

## Future Improvements

Potential extensions:

- Sensitivity analysis using different score weightings  
- Interactive geographic mapping of ZIP scores  
- Expansion to multiple U.S. cities for comparison  
- Adding home prices, crime, or transit accessibility metrics  

---

## Repository Structure

```
philly-affordability-analysis/
│
├── data/
│   └── Sample Project.csv
├── scripts/
│   └── analysis.R
├── outputs/
│   ├── philly_affordability_commute.png
│   ├── top10_affordability_commute.png
│   └── philly_clean_scored.csv
└── README.md
```

---

## Author

Jonathan Betten  
University of Massachusetts Amherst — Mathematics    
Aspiring data analyst
