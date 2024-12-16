---
title: "Langgraph + Langchain"
excerpt: "Getting bank transactions, formatting and augmented the data with an LLM<br/>

<img src='/images/portfolio_genAI_langgraph_graph_1.png' width= 300 height= 300> "
collection: portfolio
---

## Overview
This personal project demonstrates how to use **Langchain** and **Langgraph** to unify and analyze banking transactions from three different CSV files. The process involves standardizing multilingual transactions and enabling a natural language interface for SQL queries against these records. To run this process it is necessary to have langgraph studio.

You’ll find two main flows:
1. **Retriever Flow** – Responsible for reading and merging different transaction CSV files, standardizing them, augmenting their data (e.g., auto-adding new columns), and creating an SQLite database.
2. **SQL Agent Flow** – Takes natural language queries and converts them into SQL queries executed against the SQLite database created in the Retriever Flow.

<div style="display: flex;">
  <img src="/images/portfolio_genAI_langgraph_graph_1.png" style="margin-right: 10px;" width = 400 height = 500>
  <img src="/images/portfolio_genAI_langgraph_graph_2.png" width = 400 height = 500>
</div>

---

## Problem
Bank transactions often come in varied formats and languages. Some statements are in German with different delimiters and date formats, while others use English formatting. This inconsistent structure makes it challenging to analyze the data collectively or run aggregated queries.

**Key challenges include:**
1. Inconsistent CSV formats (delimiters, encoding).
2. Different languages (German vs. English).
3. Lack of a unified schema to store transactions from multiple sources.
4. Complex data augmentation (e.g., deriving extra columns like _Merchant Category_ or _Recurring_ from the text).
5. Natural language queries that need to be transformed accurately into SQL.

---

## Solution
1. **Merging & Standardizing Data:**  
   - Parse each CSV file regardless of its encoding or structure.  
   - Map columns to a standardized set of fields like `Date`, `Description`, `Merchant`, etc.  
   - **Langchain** is used to invoke an LLM that inspects CSV headers and maps them to a consistent schema.  
2. **Augmenting Data:**  
   - Automatically analyze transaction rows, add new columns such as `Transaction Type`, `Budget Category`, `Tags`, etc.  
   - Convert data into English as part of a uniform representation.  
3. **Creating a SQL Database:**  
   - Store the merged and augmented data in an SQLite database for easy querying.  
4. **SQL Agent:**  
   - Take a natural language question (e.g., *"What’s the total spending in November?"*).  
   - Parse the question for relevant columns, tables, and unique nouns.  
   - Convert the parsed question into a valid SQL query.  
   - Validate and fix the SQL query if needed.  
   - Execute the query against the SQLite database.  

**Langgraph** orchestrates these steps by defining computational flows (`StateGraph`) and chaining them neatly.

---


## Folder Structure

    images/
    src/
    ├─ agent_retriever/
    │   ├─ files/
    │   │   ├─ dummy1.csv
    │   │   ├─ dummy2.csv
    │   │   └─ dummy3.csv
    │   ├─ __init__.py
    │   ├─ agent_retriever.py
    │   ├─ augmented_functions.py
    │   ├─ configuration.py
    │   ├─ merged_csv.py
    │   ├─ prompt.py
    │   ├─ state.py
    │   └─ utils.py
    ├─ agent_sql/
    │   ├─ agent_sql.py
    │   ├─ configuration.py
    │   ├─ database.py
    │   ├─ database_utils.py
    │   ├─ llm_manager.py
    │   ├─ prompt.py
    │   └─ state.py
    ├─ .env
    ├─ langgraph.json
    ├─ pyproject.tml
    └─ README.md

---

# Agent retriever

## Files

- `__init__.py`: File created to trigger the entire process.
- `agent_retriever.py`: This is the main file of the process, where other important methods such as `standardize_csv`, `augmented_data`, and `create_sqlite` are called. The graph is also created here.
- `merged_csv.py`: This file defines the class responsible for merging the CSVs. Here is where the files are read, sent to the LLM to obtain standardized column names, and a first version of the data is sent to the next step in the flow in a DataFrame format. This class is called from `agent_retriever.py` in the `standardize_csv` function.
- `augmented_functions.py`: Here, a class is defined to take the already processed and standardized data and extract more valuable information based on it. The problem is that since these three files are different, when the columns are standardized, it is hard to infer new columns based on text. For example, a PayPal payment for a monthly Spotify subscription doesn’t straightforwardly reveal extra fields like marketplace, recurring payment, payment method, etc., unless you rely on a dictionary. Maintaining that dictionary can be time-consuming. This is where an LLM truly helps by accurately inferring new columns in a much simpler way.
- Function `create_sqlite` in `agent_retriever.py`: This is an important function to save the data in a .sql format to be queried later.
- `configuration.py`: This file defines process variables needed across multiple methods. Additionally, it contains an important function called `from_runnable_config`, which is used to retrieve these variables when needed.
- `prompt.py`: The prompt is very important; here, the queries and desired output from the LLM are defined. This is where the magic happens.
- `state.py`: States are structures of data that allow the saving of the answer of each step and communicate them to the next step. They are a very important part of the agents' workflows in langgraph.
- `utils.py`: File created to define an LLM function call.
high-level workflow describing how the project works in two major flows:

<p align="center">
  <img src="/images/portfolio_ai_genai_agent_retriever.png" width="500" height="400">
</p>


### Retriever Flow
1. **Read CSV Files**:  
   - Inspect their encodings (some are semicolon-delimited, one is in German).
2. **Map Columns via LLM**:  
   - Use an LLM prompt to map non-standard column headers to uniform standardized fields (`Date`, `Amount (EUR)`, etc.).
3. **Concatenate Data**:  
   - Merge all CSV files into one DataFrame, preserving only standardized fields.
4. **Augment Data**:  
   - Split the DataFrame into chunks and pass them through an LLM prompt that translates the data to English and adds extra columns (`Transaction Type`, `Merchant Category`, etc.).
5. **Create SQLite Database**:  
   - Save the final, augmented DataFrame to an SQLite file for further querying.

# Agent Sql

## Files

- `agent_sql.py` defines the Langgraph flow for parsing user questions, generating SQL, and validating it. The process includes parse_query, which checks if the question is relevant and identifies table/columns; get_unique_nouns, which fetches distinct values from relevant columns; generate_sql, which constructs an SQL query from the user question and discovered nouns; validate_and_fix_sql, which corrects table or column name errors; and execute_sql, which executes the final SQL query and returns results.
- `database.py` & `database_utils.py`:
    - `database.py`: Manages steps involved in SQL query generation and execution.
    - `database_utils.py`: Contains helper methods to retrieve the schema from the SQLite database and execute queries.
- `llm_manager.py`: Implements a manager class that interacts with the LLM (OpenAI Chat model). Used by both the Retriever flow and SQL flow for prompt engineering.
- `prompt.py` (within `agent_retriever`): Map CSV columns to standardized fields and Augment the data with new columns.
- `configuration.py`: Holds dataclasses that store configuration parameters, such as the database path or the model name. Each flow (retriever vs. SQL agent) has its own configuration class.

## SQL Agent Flow
1. **Parse Natural Language Query**:  
   - Break down the user’s question to identify relevant tables and columns.  
2. **Discover Unique Nouns**:  
   - Identify unique nouns or important values from the relevant columns (e.g., merchant names).
3. **Generate SQL**:  
   - Use the parsed question plus the discovered nouns to generate an SQL query string via an LLM prompt.
4. **Validate & Fix SQL**:  
   - Double-check the generated SQL against the known schema; fix any errors in table or column names.
5. **Execute SQL**:  
   - Run the validated SQL query against the SQLite database and return the results.

<p align="center">
<img src="/images/portfolio_ai_genai_agent_sql.png" width =600 height = 200>
</p>

# Agent working

In this section I'll try to explain how the workflow executions goes. I'll give a brief description of the data and output.

## Input

## Data Sources

### 1. `20241122-4572815-umsatz.csv`
- **Origin/Language**: This CSV is exported from a German banking system.  
- **Delimiters/Encoding**: Uses semicolons (`;`) as delimiters and German-style numeric formats (where decimals are represented by commas).  
- **Sample Columns**:  
  - **Buchungstag (Booking Date)**: `21.11.24`  
  - **Valutadatum (Value Date)**: `21.11.2024`  
  - **Buchungstext (Transaction Text)**: `FOLGELASTSCHRIFT`  
  - **Verwendungszweck (Purpose)**: `1038356944342/. MEDION AG, Ihr Einkauf bei MEDION AG`  
  - **Beguenstigter/Zahlungspflichtiger (Beneficiary/Payer)**: `PayPal Europe S.a.r.l. et Cie S.C.A`  
  - **Betrag (Amount)**: `-1,99` (EUR)  
- **Notable Features**:  
  - Columns are labeled in German.  
  - The CSV likely contains direct debits, credits, and references to transaction details (e.g., PayPal transactions).  
  - A “Kategorie” field is present but often empty in the sample.  

---

### 2. `account-statement_2023-11-01_2024-11-10_en_78d98f.csv`
- **Origin/Language**: Export from an online banking or fintech platform.  
- **Delimiters**: Uses commas (`,`) as the delimiter in a more standard CSV format.  
- **Sample Columns**:  
  - **Type**: `TOPUP`  
  - **Product**: `Current`  
  - **Started Date**: `2023-11-01 06:42:15`  
  - **Completed Date**: `2023-11-01 06:42:16`  
  - **Description**: `Payment from Vanessa Hofer`  
  - **Amount**: `150.00` (EUR)  
  - **Fee**: `0.00`  
- **Notable Features**:  
  - Uses standard decimal notation (`.`) for amounts.  
  - Includes timestamps for started/completed transactions.  
  - “State” field (`COMPLETED`) indicates transaction status; “Balance” column can track running account balances.  

---


## Process
The input data, as shown in the section above, has a different structure. In the first part of the process, I'll obtain and standardize a dataframe with the following columns:

	Data columns (total 6 columns):
	 #   Column           Non-Null Count  Dtype  
	---  ------           --------------  -----  
	 0   Date             9 non-null      object 
	 1   Description      9 non-null      object 
	 2   Merchant         9 non-null      object 
	 3   Product_service  9 non-null      object 
	 4   Amount (EUR)     9 non-null      float64
	 5   Currency         9 non-null      object 

In the second part of the workflow, when I request data augmentation from the LLM, I receive the following dataframe structure:

	  #   Column             Non-Null Count  Dtype 
	---  ------             --------------  ----- 
	 0   date               9 non-null      object
	 1   description        9 non-null      object
	 2   merchant           9 non-null      object
	 3   product_service    9 non-null      object
	 4   amount_(eur)       9 non-null      object
	 5   currency           9 non-null      object
	 6   transaction_type   9 non-null      object
	 7   merchant_name      8 non-null      object
	 8   merchant_category  9 non-null      object
	 9   payment_method     9 non-null      object
	 10  location           6 non-null      object
	 11  recurring          9 non-null      object
	 12  budget_category    9 non-null      object
	 13  tags               9 non-null      object
	 14  notes              9 non-null      object
	 15  payment_status     9 non-null      object

This data is saved in a SQL table to be queried in the next part of the flow.  


## Prompt used

An important part of this workflow are the prompts, I'll leave here for you to check the prompt structure

      # Standardized fields you want to map to
      standard_fields = [
         "Date",
         "Description",
         "Merchant",
         "Product_service",
         "Amount (EUR)",
         "Currency"
      ]

      # Example output format
      output_example = """
      {
         "Date": "ColumnNameInSample",
         "Description": "ColumnNameInSample",
         "Merchant",     
         "Product_service",
         "Amount (EUR)": "ColumnNameInSample",
         "Currency": "ColumnNameInSample"
      }
      """

      # Prompt template
      prompt = """
      I have a CSV file with the following headers:

      {headers}

      Based on these column headers, please map them to the following standardized fields:

      {standard_fields}

      **Instructions:**

      - Provide your answer **strictly** as a valid JSON object.
      - Each standardized field should be mapped to the corresponding column name from the CSV headers.
      - If a standardized field is not present in the sample, set its value to some value that might fit.
      - **Do not include any explanations, comments, or additional text before or after the JSON.**
      - Output **only** the JSON object.

      **Example output format:**

      {output_example}
      """