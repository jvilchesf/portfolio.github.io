---
title: "[Looker Studio]Rate prices telephone company"
excerpt: "Looker studio dashboard to compare costs of different providers<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_5_lookerStudio_telephone.png' width = 300 height = 300>"
collection: portfolio
---

# Overview

The objective of this project is to create a visualization to compare costs for different telephone call providers. The dashboard was created with Looker Studio, leveraging Google Colab's development capabilities and BigQuery as a data repository.

This company provides telephone services to several businesses, with a cost associated with each phone call, whether national or international. It has been challenging for them to track which providers are profitable in specific cases and which ones are too expensive, indicating the need for a different alternative. This is why the dashboard was created.

# Tools and Technologies  

- To approach this project I used: 
    -   Python: Using the pandas, PostgreSQL, and BigQuery libraries, I successfully retrieved data from PostgreSQL and structured it.
    -   BigQuery: I used BigQuery as a data repository because it allowed me to connect Looker Studio easily for handling large amounts of data.
    -   Looker Studio: I used Looker Studio to create a dashboard that displays the structured data and generates the KPIs to be shown.

# Workflow Diagram

- This diagram is intended to provide an overview of the workflow.

    - Connect to a MySQL database via a Python script.
    - There are two Python scripts with different goals: one updates the table in BigQuery daily, and the other runs on demand with daily data.
    - BigQuery is the data repository where the final structured data, sent from Python, will be saved.
    - Looker Studio is the final layer where the dashboard is displayed.

<div style="text-align: center;">
    <img src="/images/portfolio_viz_5_workflow.png" alt="Workflow Diagram" width="400" height="400">
</div>

# Outcome

The final Looker Studio dashboard offers users an intuitive, interactive platform to explore pricing differences, track trends over time, and gain insights into their call provider costs. By leveraging the processed dataset, the dashboard allows for dynamic filtering and clear visual comparisons, empowering decision-makers to quickly identify the most cost-effective options.

<img src="/images/porfolio_viz_5_telephone_dashboard.png" alt="Telephone Dashboard Preview" width="600" height="600" >

*Note: The above image is a placeholder. A link to the live dashboard is provided at the end of this publication.*

**Script Delivery:**  
All relevant scripts were delivered to the client in a structured zip file for installation on their Linux server. This package includes:

- **README.md:** Guidance on setup and usage.  
- **requirements.txt:** List of Python dependencies for easy environment setup.  
- **telecom_adhoc.py:** The main Python script to extract, transform, and load the data.

# Dataset Description and Methodology  

## Source

- The data sources is a MySql data base with an specific table with call with ~21.000.000. 

| Field Name        | Type     | Description                                |
|-------------------|----------|--------------------------------------------|
| id                | INTEGER  | Unique identifier for each record         |
| DateTime          | DATETIME | Timestamp of the call                     |
| Origin            | INTEGER  | ID of the origin location (e.g., caller)  |
| Destination       | INTEGER  | ID of the destination location (e.g., receiver) |
| Seconds           | INTEGER  | Duration of the call in seconds           |
| DirectionForwarded| INTEGER  | Indicates if the call was forwarded       |
| Cost              | FLOAT    | Cost of the call                          |
| Sell              | FLOAT    | Selling price of the call                 |
| Profit            | FLOAT    | Profit generated from the call            |
| CallType          | INTEGER  | Type of the call (e.g., local, international) |
| CustIdent         | INTEGER  | Customer identifier                       |
| customername      | STRING   | Name of the customer                      |
| acc_num           | STRING   | Account number associated with the customer |
| description_name  | STRING   | Description of the call or service        |
| carrier_name      | STRING   | Name of the carrier/provider              |
| minutes           | FLOAT    | Duration of the call in minutes           |


# Preprocessing: Steps taken to clean, transform, or augment the data.

The preprocessing phase involves several steps designed to clean, transform, and augment the source data before loading it into BigQuery.

## 1. Data Retrieval

**Description:**  
Fetch the most recent `DateTime` from the target BigQuery table and use it to query a MySQL database for new records. This ensures that only data newer than the recorded `DateTime` is retrieved.

**Code Snippet:**

    ```python
    query = """
        SELECT MAX(DateTime) AS max_datetime
        FROM `cdr-data.telecom_rates.telecom_calls`
    """
    query_job = client.query(query)
    result = query_job.result()

    max_datetime = None
    for row in result:
        max_datetime = row.max_datetime

    print("Max DateTime retrieved:", max_datetime)

## 2. Data Integration

**Description:**  
Load multiple related tables (e.g., descriptions, carriers, customers) from MySQL and merge them into a single main table. This process involves joining datasets on common keys, ensuring a comprehensive dataset is prepared for analysis.

**Code Snippet:**

    # Merging multiple DataFrames into one main table
    main_table = df_data_type.merge(df_customer_name, how='left', left_on='CustomerName', right_on='customer_name_id')
    main_table = main_table.merge(df_customer, how='left', left_on='Customer', right_on='customer_id')
    main_table = main_table.merge(df_description, how='left', left_on='Description', right_on='description_id')
    main_table = main_table.merge(df_carrier, how='left', left_on='Carrier', right_on='carrier_id')

### 3. Data Cleaning & Restructuring

**Description:**
Rename columns for clarity, remove unnecessary fields, and convert columns (such as DateTime) to their proper data types. This step ensures that the data is clean, consistent, and ready for further transformation.

**Code Snippet:**

    # Rename columns for clarity
    df_description.rename(columns={'id': 'description_id', 'Name': 'description_name'}, inplace=True)

    # Remove columns that are no longer needed
    columns_to_delete = ['CustomerName', 'Customer', 'customer_name_id', 'customer_id',
                        'description_id', 'carrier_id', 'User', 'Carrier', 'AccNum', 'Description']
    main_table.drop(columns=columns_to_delete, inplace=True)

    # Convert DateTime to proper format
    main_table['DateTime'] = pd.to_datetime(main_table['DateTime'], errors='coerce')

### 4. Data Transformation & Enhancement

**Description:**
Adjust numerical values to appropriate scales and create new derived features. For instance, scale Cost, Profit, and Sell values for easier interpretation, and create a minutes column from Seconds to provide more intuitive time metrics.

**Code Snippet:**

    # Adjust numerical values
    main_table['Cost'] = main_table['Cost'] / 10000
    main_table['Profit'] = main_table['Profit'] / 100000
    main_table['Sell'] = main_table['Sell'] / 10000

    # Create a new 'minutes' column from 'Seconds'
    main_table['minutes'] = main_table['Seconds'] / 60

    print("Data transformation and enhancement completed.")

### 5. Data Loading into BigQuery

**Description:**  
The final step in the preprocessing pipeline involves appending the processed and enhanced data to an existing BigQuery table. Rather than replacing the existing dataset, the new rows are added to the current table, ensuring that historical data is preserved. The schema is automatically detected, making the process straightforward and flexible.

**Code Snippet:**

    ```python
    table_ref = f"{project}.{dataset_id}.{table_id}"
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        autodetect=True
    )

    job = client.load_table_from_dataframe(main_table, table_ref, job_config=job_config)
    job.result()  # Wait for the load job to complete

    print(f"Appended {job.output_rows} rows to {dataset_id}:{table_id}.")


# Methodology

The development of this dashboard followed an iterative, user-centered methodology, ensuring that the final product aligned closely with the customer’s needs. The process involved several key steps:

1. **Initial Consultation & Requirements Gathering:**  
   Early meetings with the client were conducted to understand their business objectives, data sources, and key performance indicators (KPIs). During these sessions, we identified essential metrics like the number of calls, costs, profits, and sell values.

2. **Data Exploration & Cleaning:**  
   Using Python and SQL, the source data was extracted, cleansed, and standardized. This included removing unnecessary columns, adjusting time formats, and creating meaningful derived metrics. The customer’s input at this stage was crucial to verify data quality and ensure that the chosen metrics accurately reflected real-world scenarios.

3. **Iterative Dashboard Design & Feedback Loops:**  
   The initial dashboard layout was developed in Looker Studio, focusing on clarity, usability, and relevance of the displayed data. Regular feedback sessions with the client allowed for adjustments to visual elements, color schemes, and data groupings. These iterative reviews ensured that the dashboard’s filters, charts, and summary cards effectively highlighted the key insights the customer needed.

4. **Refinement of KPIs & Visualization Techniques:**  
   As the project progressed, ongoing discussions helped refine the KPIs further. We experimented with different chart types, date ranges, and comparison periods. The client provided continuous feedback on what best represented their operational reality, leading to a more intuitive and actionable final design.

5. **Validation & Final Review:**  
   Before deployment, the dashboard underwent a final round of validation meetings. The client confirmed that the metrics aligned with their internal records and that the visualizations supported strategic decision-making. Any last-minute changes, such as adding new filters or adjusting the labeling of certain KPIs, were incorporated to finalize the solution.

**In essence, the methodology centered on close collaboration and frequent check-ins with the customer, ensuring that every stage—from data preparation to visual design—was informed by their feedback and aligned with their business goals.**

    

# Data Visualization Workflow

The visualization process began with identifying the client’s target KPIs and data sources. After data extraction and cleaning, metrics were carefully chosen to reflect business insights. These metrics were then visualized in Looker Studio, with each round of feedback guiding adjustments in chart types, filtering mechanisms, and layout. The workflow was iterative, with continuous client involvement ensuring that the final product effectively communicated the necessary insights.

# Results and Insights

The final dashboard presents a clear comparison of different telephone call providers, highlighting trends in cost, profit, and call duration. Users can quickly identify which providers offer the best value and under what circumstances. This clarity helps stakeholders make informed decisions about switching providers, optimizing call routes, or negotiating better rates.

# Code Repository

The Python script used for processing and aggregation is available on GitHub:  
[Telephone company - Code Repository](https://github.com/jvilchesf/portfolio.github.io/tree/main/_portfolio_scripts/nyc_realstates)

# Visualization Link

The interactive Looker studio dashboard is accessible here:  
[Telephone company - Looker Studio Dashboard](https://lookerstudio.google.com/u/0/reporting/2010797f-edec-4608-8f4d-f8949c0a6c70/page/nO1HE/edit) 

