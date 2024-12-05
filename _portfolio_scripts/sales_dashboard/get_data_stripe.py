import stripe
import pandas as pd
from datetime import datetime
from google.cloud import bigquery
import os

# Set your Stripe API key
# Initialize BigQuery client
BQ_PROJECT_ID = "uprofittrader-ga4"
BQ_DATASET_ID = "analytics_417386444"
BQ_TABLE_ID_CHARGES = "Dashboard_sales_stripe_charges"
BQ_TABLE_ID_TRANSACTIONS = "Dashboard_sales_stripe_transactions"
client = bigquery.Client()


bucket_name = 'uprofit-dashboard-subscription-bucket'
project_name = 'uprofittrader-ga4"'
database_name = 'analytics_417386444'
table_name = 'Dashboard_sales_supabase_stripe'
os.environ["GOOGLE_CLOUD_PROJECT"] = "uprofittrader-ga4"


# Function to fetch the end date from BigQuery table
def fetch_start_date_from_bigquery():
    # Initialize BigQuery client
    
    # Construct BigQuery SQL query
    query_start_charge = """
        SELECT MAX(created_date) as max_date
        FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_charges`
    """

    query_start_trx = """
        SELECT MAX(created_date) as max_date
        FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_transactions`
    """
    
    # Execute the query
    query_job_charge = client.query(query_start_charge)
    query_job_trx = client.query(query_start_trx)
    result_charge = query_job_charge.result()
    result_trx = query_job_trx.result()
    
    
    # Extract the maximum date
    start_date_charge = None
    start_date_trx = None
    
    for row in result_charge:
         start_date_charge = row.max_date
         break
    
    for row in result_trx:
        start_date_trx = row.max_date
        break

    return start_date_charge,start_date_trx

# Function to fetch transactions and charges within a specified time period
def fetch_transactions_and_charges(start_date_charge_unix,start_date_trx_unix):
    transactions = stripe.BalanceTransaction.list(
        created={"gte": start_date_trx_unix},
        limit=100  # Adjust as needed
    )
    
    charges = stripe.Charge.list(
        created={"gte": start_date_charge_unix},
        limit=100  # Adjust as needed
    )
    
    return transactions, charges

# Function to transform transactions and charges into a pandas DataFrame
def transactions_and_charges_to_dataframe(transactions, charges):
    transaction_data = []
    for transaction in transactions.auto_paging_iter():
        transaction_data.append({
            "id": transaction.id,
            "created_date": pd.to_datetime(transaction.created, unit='s', utc=True),
            "amount": transaction.amount / 100,  # Stripe amounts are in cents
            #"Converted Amount": transaction.exchange_rate * transaction.amount / 100,
            "description": transaction.description,
            "status": transaction.status,
            "type": transaction.type,
            "fee": transaction.fee / 100  # Stripe fees are in cents
        })
    
    charge_data = []
    for charge in charges.auto_paging_iter():
        payment_method_brand = None
        payment_method_country = None

        if hasattr(charge.payment_method_details, 'card'):
            card_details = charge.payment_method_details.card
            if hasattr(card_details, 'brand'):
                payment_method_brand = card_details.brand
            if hasattr(card_details, 'country'):
                payment_method_country = card_details.country
        
    
        customer = stripe.Customer.retrieve(charge.customer)


        charge_data.append({
            "id": charge.id,
            "created_date": pd.to_datetime(charge.created, unit='s', utc=True),                        
            "amount": charge.amount / 100,  # Stripe amounts are in cents
            "balance_transaction": charge.balance_transaction if charge.balance_transaction != None else 'Empty',
            "customer_email": customer.email,
            "customer_name": customer.name,
            "customer_id": charge.customer,
            "product_description": charge.calculated_statement_descriptor,
            "currency": charge.currency,
            "description": charge.description,
            "status": charge.status,
            "failure_code": charge.failure_code,
            "failure_message": charge.failure_message,
            "payment_method_brand": payment_method_brand,
            "payment_method_country": payment_method_country
        })

    transactions_df = pd.DataFrame(transaction_data)
    charges_df = pd.DataFrame(charge_data)
    
    return transactions_df, charges_df



def load_data_to_bigquery(transactions_df,charges_df):
    
     # Define schema for Transactions table
    transactions_schema = [
        bigquery.SchemaField("id", "STRING"),
        bigquery.SchemaField("created_date", "TIMESTAMP"),
        bigquery.SchemaField("amount", "FLOAT"),
        bigquery.SchemaField("description", "STRING"),
        bigquery.SchemaField("status", "STRING"),
        bigquery.SchemaField("type", "STRING"),
        bigquery.SchemaField("fee", "FLOAT")
    ]

        # Create Transactions table
    transactions_table_id = f"{BQ_PROJECT_ID}.{BQ_DATASET_ID}.{BQ_TABLE_ID_TRANSACTIONS}"
    transactions_table = bigquery.Table(transactions_table_id, schema=transactions_schema)
 #   transactions_table = client.create_table(transactions_table)
    
    # Load data into Transactions table
    job_config = bigquery.LoadJobConfig()
    job_config.write_disposition = bigquery.WriteDisposition.WRITE_APPEND
    client.load_table_from_dataframe(transactions_df, transactions_table_id, job_config=job_config).result()
    print(f"Transactions table created and data loaded: {transactions_table_id}")
    
      # Define schema for Charge table
    charge_schema = [
        bigquery.SchemaField("id", "STRING"),
        bigquery.SchemaField("created_date", "TIMESTAMP"),
        bigquery.SchemaField("amount", "FLOAT"),
        bigquery.SchemaField("balance_transaction", "STRING"),
        bigquery.SchemaField("customer_email", "STRING"),
        bigquery.SchemaField("customer_name", "STRING"),
        bigquery.SchemaField("customer_id", "STRING"),
        bigquery.SchemaField("product_description", "STRING"),
        bigquery.SchemaField("currency", "STRING"),
        bigquery.SchemaField("description", "STRING"),
        bigquery.SchemaField("status", "STRING"),
        bigquery.SchemaField("failure_code", "STRING"),
        bigquery.SchemaField("failure_message", "STRING"),
        bigquery.SchemaField("payment_method_brand", "STRING"),
        bigquery.SchemaField("payment_method_country", "STRING")
    ]

    # Create Charge table
    
    # Define table IDs
    charge_table_id = f"{BQ_PROJECT_ID}.{BQ_DATASET_ID}.{BQ_TABLE_ID_CHARGES}"
    
    # Get the schema of the existing BigQuery table
    charges_table = client.get_table(charge_table_id)
    
   # Ensure DataFrame schema matches table schema
    # Ensure 'balance_transaction' column is present in charges_df
    charges_df = charges_df[[field.name for field in charges_table.schema]]

    # Load data into BigQuery tables
    job_config = bigquery.LoadJobConfig()

    #charge_table = bigquery.Table(charge_table_id, schema=charge_schema)
    #charge_table = client.create_table(charge_table)
    
    # Load data into Charge table
    client.load_table_from_dataframe(charges_df, charge_table_id, job_config=job_config).result()
    print(f"Charge table created and data loaded: {charge_table_id}")


def main(data,context):
	# Fetch the end date from BigQuery table
	start_date_charge, start_date_trx = fetch_start_date_from_bigquery()

	# Set the start date for transactions retrieval (e.g., one month before end_date)
	start_date_charge_unix = int(start_date_charge.timestamp())
	start_date_trx_unix = int(start_date_trx.timestamp())

	# Fetch transactions and charges within the specified time period
	transactions, charges = fetch_transactions_and_charges(start_date_charge_unix,start_date_trx_unix)

	# Transform transactions and charges into pandas DataFrames
	transactions_df, charges_df = transactions_and_charges_to_dataframe(transactions, charges)

	# Display the DataFrames
	print("Transactions:")
	print(transactions_df)
	print("\nCharges:")
	print(charges_df)

	load_data_to_bigquery(transactions_df,charges_df)


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())

