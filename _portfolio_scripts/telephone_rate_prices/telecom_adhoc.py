from datetime import datetime, timedelta
from google.cloud import bigquery
from google.oauth2 import service_account
import pyarrow
import os
from tqdm import tqdm
import pandas as pd
import mysql.connector

######################################################## DEFINE BIG QUERY CLIENT ####################################################

# Define the path to the service account key file
key_path = '/input/path/for/json/file/telecom_rates/source/cdr-data-4580dcd3b67a.json'

# Create credentials using the service account key file
credentials = service_account.Credentials.from_service_account_file(key_path)

# Initialize a BigQuery client
client = bigquery.Client(credentials=credentials, project=credentials.project_id)

######################################################  GET DATA FROM SQL ####################################################

# Calculate 1 week ago from today with time set to 00:00:00 and convert to string
set_days = 10 ##Here is where wayne should change the days in case he wants to change the query timeframe

one_week_ago_midnight_str = (datetime.now() - timedelta(days = set_days)).replace(hour=0, minute=0, second=0, microsecond=0).strftime("%Y-%m-%d %H:%M:%S")

#Connect to SQL database and get data base on max datetime of the bigquery table
try:
    # Establish a new connection to the database
    connection = mysql.connector.connect(
        host="", 
        port = 11556,
        user= '',
        password= '',
        database=''
    )

    if connection.is_connected():
        cursor = connection.cursor(dictionary=True)

        # List of SQL queries and corresponding dataframe names
        queries = [
            ("SELECT * FROM cdr.description", "df_description"),
            ("SELECT * FROM cdr.carrier", "df_carrier"),
            ("SELECT * FROM cdr.customer", "df_customer"),
            ("SELECT * FROM cdr.customer_name", "df_customer_name"),
            (f"SELECT * FROM data_type1  WHERE datetime >= '{one_week_ago_midnight_str}'", "df_data_type")
            #("SELECT * FROM cdr.data_type1 WHERE Datetime >= '2024-08-01 00:00:00", "df_data_type")

        ]

        # Create dataframes from each table with a progress bar
        for query, df_name in tqdm(queries, desc="Creating DataFrames"):
            globals()[df_name] = pd.read_sql(query, connection)

        print("Dataframes created successfully")

except mysql.connector.Error as err:
    print(f"Error: {err}")
finally:
    if connection.is_connected():
        cursor.close()
        connection.close()
        print("Database connection closed")

################################################## TRANSFORM DATA ##################################################        

# Rename columns in each dataframe to avoid conflicts
df_description.rename(columns={'id': 'description_id', 'Name': 'description_name'}, inplace=True)
df_carrier.rename(columns={'id': 'carrier_id', 'Name': 'carrier_name'}, inplace=True)
df_customer.rename(columns={'id': 'customer_id', 'Name': 'acc_num'}, inplace=True)
df_customer_name.rename(columns={'id': 'customer_name_id', 'Name': 'customername'}, inplace=True)

# Merge df_data_type with df_cust_name on the appropriate key
main_table = df_data_type.merge(df_customer_name, how='left', left_on='CustomerName', right_on='customer_name_id')

# Merge the result with df_cust
main_table = main_table.merge(df_customer, how='left', left_on='Customer', right_on='customer_id')

# Merge the result with df_desc
main_table = main_table.merge(df_description, how='left', left_on='Description', right_on='description_id')

# Merge the result with df_carr
main_table = main_table.merge(df_carrier, how='left', left_on='Carrier', right_on='carrier_id')


#Remove useless columns
columns_to_delete = [
    'CustomerName', 'Customer',
    'customer_name_id', 'customer_id',
    'description_id', 'carrier_id', 'User', 'Carrier', 'AccNum',"Description"
]

# Drop the specified columns from main_table
main_table.drop(columns=columns_to_delete, inplace=True)

# Convert 'Datetime' column to datetime format
main_table['DateTime'] = pd.to_datetime(main_table['DateTime'], errors='coerce')

# Divide 'Cost', 'Profit', and 'Sell' columns by 100000
main_table['Cost'] = main_table['Cost'] / 10000
main_table['Profit'] = main_table['Profit'] / 100000
main_table['Sell'] = main_table['Sell'] / 10000

# Add a new column 'minutes' that is 'second' divided by 60
main_table['minutes'] = main_table['Seconds'] / 60

###################################################### Create table BIG QUERY ################################################

# Define project, dataset, and table
project = 'cdr-data'
dataset_id = 'telecom_rates'
table_id = 'telecom_calls_adhoc'

# Define the full table ID
table_ref = f"{project}.{dataset_id}.{table_id}"

# Configure the load job
job_config = bigquery.LoadJobConfig(
write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE, # Overwrite the table if it exists
autodetect=True # Automatically detect the schema
)

# Load the DataFrame (e.g., main_table) to BigQuery
# Ensure main_table is defined as a DataFrame before running this part
job = client.load_table_from_dataframe(main_table, table_ref, job_config=job_config)

# Wait for the load job to complete
job.result()

print(f"Loaded {job.output_rows} rows into {dataset_id}:{table_id}.")
