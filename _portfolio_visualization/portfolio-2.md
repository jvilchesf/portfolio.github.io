---
title: "[Looker Studio] Quality control project monitoring"
excerpt: "Dashboard to follow project complete metrics<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_2_lookerStudio_QC.png' width = 300 height = 400>"
collection: portfolio
---

# Overview

The main goal of this project is to provide an overview of project completion for an environmental company, where most of the projects are related to bird or mammal survey site assessments. The aim is to ensure the installation of windmills poses no risk to the local fauna.

To achieve this, I created a Looker Studio dashboard that clearly displays the percentage of each project that has been completed and what remains to be done. This helps prioritize efforts on tasks that are delayed or urgent and effectively measure time.

At that time, the team responsible for tracking project completion was using Excel for this task, which required a manual weekly effort to compile the necessary information. This is why the primary goal was to automate this process and ensure the consistent use of the dashboard.


## Tools and Technologies  
To complete this project, I utilized the following tools:  

- **Python**: Developed the Python code in Google Colab. The `gspread` library was used to read data from a Google Spreadsheet, while `pandas` was employed to clean and structure the data.  
- **Looker Studio**: Designed and created a dashboard to visualize the processed data, making it easier to analyze and summarize key insights.  

## Dataset Description and Methodology  
### Source  
- **Google Sheets**: The data was sourced from a Google Sheet.  

### Size and Structure  
- Size: 8000+ rows
- The initial data structure presented a significant challenge. Instead of having a single structured sheet, the dataset was spread across 60 different sheets. The task involved consolidating all this information into a single comprehensive DataFrame, ensuring consistency and usability for further analysis.  


| **Field**               | **Description**                                                                 |
|--------------------------|---------------------------------------------------------------------------------|
| **Project Code**         | A unique identifier for the project.                                           |
| **Client**               | The name of the client the project is for.                                     |
| **Project**              | The specific project name or location.                                         |
| **PM/TL**                | The Project Manager or Team Lead responsible for the project.                  |
| **Type**                 | The type of survey or work conducted (e.g., Birds, Mammals, etc.).             |
| **All Data Received**    | Indicates whether all project data has been received (Y/N).                    |
| **Fully QC'd**           | Indicates if the data has been fully quality-checked (Y/N).                    |
| **Folder to Send Created** | Shows if the folder for sending data has been created (Y/N/NR).               |
| **Monthly Report Created** | Indicates whether the monthly report for the project has been created (Y/N/NR). |
| **Report Reviewed**      | Confirms if the report has been reviewed (Y/N/NR).                             |
| **Report Signed Off**    | Confirms if the report has been signed off by the client or team (Y/N/NR).     |
| **Shapefiles in the Folder** | Indicates whether shapefiles have been placed in the project folder (Y/N/NR). |
| **Issued to Client**     | Shows whether the project data has been issued to the client (Y/N/NR).         |
| **Date Issued**          | The date the project data was issued to the client.                            |
| **Notes**                | Any additional notes or comments about the project.                            |



### Preprocessing: Steps taken to clean, transform, or augment the data.

This section outlines the steps taken to clean and structure the data, with snippets of Python code for illustration.

### 1. Authenticate and Connect to Google Sheets
The first step is to authenticate the user and establish a connection to the required Google Sheets.

        ```python
        from google.colab import auth
        from google.auth import default
        import gspread

        auth.authenticate_user()
        creds, _ = default()
        gc = gspread.authorize(creds)
        sh_master = gc.open('2024_Breeding Season_QC List  - VH (5)')  # Read Google Sheet file
        sh_schedule = gc.open('Breeding Season 2024 Schedule')  # Read Google Sheet file  

### 2.  Handle Merged Cells
A custom function is used to handle merged cells in the first three columns, ensuring data integrity.

        def fill_merged_cells(data):
            for row_index, row in enumerate(data):
                for col_index in range(3):  # Limit to the first three columns
                    cell = row[col_index]
                    if cell == '':
                        # Find the closest non-empty cell above
                        for k in range(row_index - 1, -1, -1):
                            if data[k][col_index] != '':
                                data[row_index][col_index] = data[k][col_index]
                                break
            return data

### 3. Define Columns to Retain
Specify the columns of interest to filter out unnecessary data.

        columns_to_keep = [
            'Project Code',
            'Month',
            'Fieldwork',
            'Further Fieldwork Information',
            'Site Visit Completed By',
            'Scheduled',
            'Data QC\'d',
            'Data Entered in Master Excel',
            'Shapefile Produced (GIS)'
        ]

### 4. Read and Process Each Sheet
Iterate through the sheets, handle merged cells, and convert data into pandas DataFrames.

        df_list = []

        for sheet_index in range(7, 65):  # Sheets are 0-indexed
            worksheet = sh_master.get_worksheet(sheet_index)
            if worksheet is not None:
                data = worksheet.get_all_values()
                if data:
                    data = fill_merged_cells(data)
                    df = pd.DataFrame(data[2:], columns=data[1])  # Use the second row as the header
                    if ' Project Code' in df.columns:
                        df.rename(columns={' Project Code': 'Project Code'}, inplace=True)
                    df_list.append(df)


### 5. Consolidate Data
Combine all individual DataFrames into a single DataFrame for analysis.

        if df_list:
            df_qc_list = pd.concat(df_list, ignore_index=True)
            df_qc_list = df_qc_list.drop(['Date Scheduled', ' Staysafe / Whatsapp'], axis=1)
            df_qc_list['execution_date'] = datetime.now().strftime("%Y-%m-%d")

### 6. Append Cleaned Data to Google Sheets
        The cleaned and structured data is appended to an existing Google Sheet for further use.

                spreadsheet = gc.open('QC_list_summarize_v1')
                worksheet = spreadsheet.get_worksheet(0)
                existing_data = worksheet.get_all_values()
                next_row = len(existing_data) + 1

                data_to_append = df_qc_list.values.tolist()
                cell_range = f'A{next_row}:J{next_row + len(data_to_append) - 1}'

                cell_list = worksheet.range(cell_range)
                for cell, data in zip(cell_list, sum(data_to_append, [])):
                    cell.value = data

                worksheet.update_cells(cell_list, value_input_option='USER_ENTERED')


## Methodology  

### Data Visualization Workflow  
- The workflow integrated **Google Sheets**, **Google Colab**, and **Looker Studio**, leveraging the convenience and capabilities of Google Cloud Platform. The automation of the code was not necessary, as the client preferred to run the code on demand.  
- The visualization included:  
  - A header summarizing the main KPIs.  
  - A table detailing the progress and status of each project.  
  - A scatter plot to graphically represent the percentage of progress for each project.  
- Due to data privacy concerns, the dashboard shown uses dummy data.  

<img src="/images/porftolio_viz_2_qc_list.png" alt="Quality Control Manager, Project Monitoring">  

## Challenges and Solutions  

- **Challenge:** The main difficulty was not the technical skills required to write the Python code or create the visualization. Instead, the challenge was understanding the problem and ensuring clear communication with the client.  
- **Solution:** Establishing a strong understanding of the client's needs and maintaining effective communication was key to the project's success. This ensured the final product met expectations and provided the desired insights.  

# Impact  

The implementation of this solution significantly improved the customer’s workflow and efficiency:  

- **Time Savings:** The customer now spends considerably less time processing and consolidating data from multiple sources. Instead of manually compiling information from 60+ sheets, the process is streamlined with a single Python script that consolidates the data into one structured view.  
- **Reduced Frustration:** By eliminating the need for repetitive manual tasks, the solution has reduced the headaches associated with data processing and handling inconsistent formats.  
- **Faster Insights:** With the Looker Studio dashboard, the customer can quickly view project completion statuses, track KPIs, and identify areas needing attention. The visualization provides instant clarity, enabling informed decision-making without delays.  
- **Focus on Priorities:** The customer now spends more time analyzing project progress and prioritizing efforts on delayed or urgent tasks, rather than wrestling with data. This shift allows for better project management and resource allocation.  

This impactful shift has enhanced productivity and allowed the client to focus on what matters most: achieving project goals efficiently and effectively.  

# Code Repository  

The code for this project is available on GitHub. You can access it via the following link:  

[QC Dashboard - Code Repository](https://github.com/jvilchesf/portfolio.github.io/blob/main/_portfolio_scripts/qc_project_monitoring/QC_dashboard_qclist.ipynb)  

This repository contains the Python notebook used for data processing, cleaning, and structuring, as well as the logic behind the visualizations.  

# Visualization Link  

The interactive dashboard for this project is available via the following link:  

[QC Dashboard - Looker Studio Visualization](https://lookerstudio.google.com/u/0/reporting/c99bad04-bbd4-44e1-8769-0fe71caa2389/page/zjL3D)  

This dashboard provides an overview of project completion, including key KPIs, detailed project information, and a graphical representation of progress.  