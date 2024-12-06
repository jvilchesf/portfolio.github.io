---
title: "[NYC Real Estate Trends] Data Visualization & Analysis"
excerpt: "Tableau dashboards to explore New York City's real estate landscape."
collection: portfolio
---

# Overview

This project focuses on exploring and visualizing real estate trends in New York City. The ultimate goal is to help building owners, prospective buyers, and other stakeholders understand current market dynamics, regulatory approvals, and construction activities. By leveraging publicly available datasets, we shed light on how economic conditions, city policies, and neighborhood characteristics influence the permitting process and building trends throughout NYC.

The target audience includes professionals and residents who live and work in New York City and are interested in real estate trends, data-driven insights, and the evolving landscape of apartment buildings. The content is aimed at individuals who wish to gain a nuanced understanding of the city’s economic health, regulatory environment, and ongoing developmental patterns.

## Outcome

Below is a preview of the Tableau dashboard created from the processed dataset. This dashboard enables users to interactively explore NYC real estate trends, filtering by borough, time period, and various building attributes to uncover insights into permit approvals, construction costs, and job types.

<img src = "https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_4_nyc_dashboard.png" tab = "NYC Real states DOB">

* Note: The above image is a placeholder. The link to the actual version can be found at the end of this publication.

## Tools and Technologies

- **Python (pandas, polars)**: Employed for data cleaning, processing, and aggregation of publicly available permit application data.
- **Tableau**: Used to create an interactive dashboard enabling easy exploration of trends, filtering by borough, year, job type, and other relevant metrics.
- **Seaborn & Matplotlib**: Utilized for preliminary data exploration and static visualizations during the analysis phase.

## Dataset Description and Methodology

### Source

- **NYC DOB Job Application Filings Dataset**: This dataset includes details on building permit applications, approvals, and related metrics. It provides insights into construction activity, renovations, and regulatory compliance in the city.
- **Source Link** [here](https://data.cityofnewyork.us/Housing-Development/DOB-Job-Application-Filings/ic3t-wcy2/about_data).


### Size and Structure

- The raw dataset includes thousands of rows detailing permit applications and 96 columns.
- Key fields include:
  - **Borough**: Indicates the NYC borough (Manhattan, Brooklyn, Queens, The Bronx, Staten Island).
  - **Job Type**: Type of job application (e.g., new building, alteration, etc.).
  - **Job Status**: Current status of the application (Approved, Filed, etc.).
  - **Approved**: The date when the job application was approved.
  - **Job #**: Unique identifier for each job application.
  - **Building Type**: Classification of the building (e.g., Residential, Mixed-use).
  - **Pre-Filing Date**: The initial date when the application was submitted.
  - **BUILDING_CLASS**: An NYC Department of Finance classification code.
  - **GIS_LATITUDE** and **GIS_LONGITUDE**: Geospatial coordinates for mapping.
  - **Initial Cost**: Estimated initial project cost.
  - **Fully Paid**: Indicates whether all related fees or payments are settled.

### Preprocessing Steps

1. **Reading and Cleaning Data**:  
   Data was loaded using `polars` and converted to `pandas` for compatibility. We applied schema overrides and handled potential null values.  
   
2. **Datetime Parsing**:  
   The 'Approved' date field was parsed into a proper datetime format to filter by approval year.

3. **Year Filtering**:  
   Focused on approvals in 2023 and 2024 to understand recent trends.

4. **Aggregations**:  
   Grouped data by Borough, Job Type, Job Status, and other dimensions to calculate:
   - Average GIS coordinates for geospatial patterns.
   - Summations of the 'Initial Cost' to understand financial trends.
   
5. **Exporting Data**:  
   A consolidated and cleaned CSV output was generated for ingestion into Tableau, ensuring a smooth data-to-dashboard workflow.

### Code Example

Below is a code snippet that illustrates the data cleaning and aggregation process. This code reads the DOB job application filings dataset, filters by the approval years 2023 and 2024, aggregates key metrics, and exports the cleaned dataset as a CSV for Tableau visualization.

        ```python
        import seaborn as sns
        import matplotlib.pyplot as plt
        import pandas as pd
        import polars as pl

        # Specify schema overrides if needed
        schema_overrides = {
            "Applicant License #": pl.Utf8
        }

        # Read the CSV with polars
        df = pl.read_csv(
            '/path/to/DOB_Job_Application_Filings_20241010.csv',
            schema_overrides=schema_overrides,
            ignore_errors=True,
            null_values=["H65055"]
        )

        # Convert to pandas for convenience
        df_pandas = df.to_pandas()

        # Convert 'Approved' column to datetime
        df_pandas['Date_Approved'] = pd.to_datetime(df_pandas['Approved'], format='%d/%m/%Y', errors='coerce')

        # Filter for 2023 and 2024
        df_filtered = df_pandas[df_pandas['Date_Approved'].dt.year.isin([2023, 2024])]

        if df_filtered.empty:
            print("The filtered DataFrame is empty. Check the filtering conditions.")
        else:
            # Group and aggregate
            grouped_df = df_filtered.groupby(
                ['Borough','Job Type','Job Status','Approved','Job #','Building Type','Pre- Filing Date','BUILDING_CLASS','Job Description','Date_Approved','Fully Paid'],
            ).agg({
                'GIS_LATITUDE': 'mean',
                'GIS_LONGITUDE': 'mean',
                'Initial Cost': 'sum',
            }).reset_index()

            # Export to CSV for Tableau
            grouped_df.to_csv('/path/to/job_application_filings_output.csv', index=False)

## Methodology

The workflow integrated NYC open data, Python for data processing, and Tableau for visualization. By preparing a clean and structured dataset, we empower interactive dashboards that allow stakeholders to examine trends by borough, time period, building type, and more.

### Data Visualization Workflow

- **Data Preparation**: Python was used for all ETL (Extract, Transform, Load) steps.
- **Visualization in Tableau**:
  - **Maps**: Display the geographic distribution of permit approvals.
  - **Trend Lines**: Show how approval counts or construction costs have evolved over time.
  - **Bar Charts & Tables**: Allow users to filter by job type, borough, and status, making it easy to identify patterns or anomalies.

*Due to confidentiality in certain proprietary datasets, the sample dashboard shown utilizes public data. All personal identifying information (PII) is not included or is masked if required by data privacy regulations.*

### Challenges and Solutions

- **Challenge**: Understanding the underlying dataset and its intricacies—especially dealing with numerous building classes, job types, and borough-level nuances—was time-consuming.
- **Solution**: Extensive data exploration and communication with the client to clarify data elements and business objectives ensured that the final product matched the user’s needs for actionable insights.

### Impact

- **Informed Decision-Making**: Stakeholders can quickly identify neighborhood-level trends, understanding where construction is booming or slowing.
- **Market Insights**: Owners and investors can track construction approvals, costs, and building types to guide strategic decisions.
- **Time Savings**: Automated data cleaning and preparation pipelines reduce manual work and help clients focus on analysis and interpretation rather than data wrangling.

### Code Repository

The Python script used for processing and aggregation is available on GitHub:  
[NYC Real Estate Data - Code Repository](https://github.com/jvilchesf/portfolio.github.io/tree/main/_portfolio_scripts/nyc_realstates)

### Visualization Link

The interactive Tableau dashboard is accessible here:  
[NYC Real Estate Trends - Tableau Dashboard](https://public.tableau.com/app/profile/jose.miguel.vilches.fierro/viz/Job_application_filling/Dashboard1) 

*It allows users to filter, sort, and drill down into the data to gain insights into the evolving real estate landscape of New York City.*
