import os
from google.cloud import bigquery
#from google.oauth2 import service_account
from supabase_py import create_client

bucket_name = 'uprofit-dashboard-subscription-bucket'
project_name = 'uprofittrader-ga4"'
database_name = 'analytics_417386444'
table_name = 'Dashboard_sales_supabase'
os.environ["GOOGLE_CLOUD_PROJECT"] = "uprofittrader-ga4"


# Get the current working directory
current_directory = os.getcwd()
# Specify the path to your service account key file
#credentials = service_account.Credentials.from_service_account_file(current_directory+"/uprofittrader-ga4-7374684cdac5.json")


# Initialize Supabase client
SUPABASE_URL = "https://zqrrxvrwcnjpitiinsjt.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxcnJ4dnJ3Y25qcGl0aWluc2p0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTY0ODU0MzY2NywiZXhwIjoxOTY0MTE5NjY3fQ.la6kxVD09q8-YdZaH5pjLn1vwqal7Xd1cEXvvbYGilo"
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


# Initialize BigQuery client
BQ_PROJECT_ID = "uprofittrader-ga4"
BQ_DATASET_ID = "analytics_417386444"
BQ_TABLE_ID = "Dashboard_sales_supabase"
#client = bigquery.Client(credentials=credentials)
client = bigquery.Client()


def fetch_supabase_data(max_checkout_date):
    # Fetch data from Supabase table
    table_name = "dashboard_subscriptions"
    if max_checkout_date is None:
        response = supabase.table(table_name).select("*").execute()
    else:
        response = supabase.table(table_name).select("*").gt('payment_date', max_checkout_date).execute()
            
    return response["data"]

def get_max_checkout_date():
    # Query BigQuery to get the maximum checkout_date
    query = f"""
    SELECT cast(MAX(checkout_date) as string) AS max_checkout_date
    FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_supabase`
    """
    query_job = client.query(query)
    result = query_job.result()

    # Iterate over the result to access the rows
    for row in result:
        max_checkout_date = row["max_checkout_date"]
        return max_checkout_date

def load_data_to_bigquery(data):
    dataset_ref = client.dataset(BQ_DATASET_ID)
    table_ref = dataset_ref.table(BQ_TABLE_ID)
    job_config = bigquery.LoadJobConfig(
       schema=[
             bigquery.SchemaField("payment_id", "INTEGER"),
             bigquery.SchemaField("payment_type", "STRING"),
             bigquery.SchemaField("payment_amount", "FLOAT"),
             bigquery.SchemaField("payment_method", "STRING"),
             bigquery.SchemaField("payment_date", "TIMESTAMP"),
             bigquery.SchemaField("payment_datetime", "DATE"),
             bigquery.SchemaField("payment_status", "STRING"),
             bigquery.SchemaField("subscription_id", "INTEGER"),
             bigquery.SchemaField("subscription_period_end", "TIMESTAMP"),
             bigquery.SchemaField("subscription_status", "STRING"),
             bigquery.SchemaField("subscription_user_id", "STRING"),
             bigquery.SchemaField("checkout_id", "INTEGER"),
             bigquery.SchemaField("checkout_date", "TIMESTAMP"),
             bigquery.SchemaField("checkout_status", "STRING"),
             bigquery.SchemaField("check_out_purchase_tracked", "BOOLEAN"),
             bigquery.SchemaField("checkout_datetime", "DATE"),
             bigquery.SchemaField("checkout_product_id", "STRING"),
             bigquery.SchemaField("checkout_coupon_id", "STRING"),
             bigquery.SchemaField("rithmic_id", "STRING"),                                       
             bigquery.SchemaField("email", "STRING"),  
             bigquery.SchemaField("rithmic_account_name", "STRING"),
             bigquery.SchemaField("rithmic_user_name", "STRING"),
             bigquery.SchemaField("ra_active", "BOOLEAN"),
             bigquery.SchemaField("ru_active", "BOOLEAN"),
             bigquery.SchemaField("locale", "STRING"),
            ]
    )
    job = client.load_table_from_json(data, table_ref, job_config=job_config)
    job.result()  # Waits for the job to complete.


def main(data,context):
    max_checkout_date = get_max_checkout_date()
    data = fetch_supabase_data(max_checkout_date)
    load_data_to_bigquery(data)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())