#from google.colab import auth
#auth.authenticate_user()
import pandas as pd
import numpy as np
import gspread
from google.auth import default
creds, _ = default()
import matplotlib.pyplot as plt
from datetime import datetime
from google.oauth2 import service_account
from google.cloud import storage

def download_service_account_file(bucket_name, blob_name, local_path):
    """Download a file from Google Cloud Storage."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(blob_name)
    blob.download_to_filename(local_path)


def main(data,context):
    # Define URI for service account file stored in Cloud Storage
    service_account_file_uri = "gs://gcf-v2-sources-343217741611-us-central1/uprofittrader-ga4-cc0d2d4ab2b3.json"

    # Download service account file from Google Cloud Storage
    download_service_account_file("gcf-v2-sources-343217741611-us-central1", "uprofittrader-ga4-d58bc69d0426.json", "/tmp/service_account.json")

    scopes = ['https://www.googleapis.com/auth/spreadsheets', 'https://www.googleapis.com/auth/drive']

    # Load service account credentials from downloaded file
    creds = service_account.Credentials.from_service_account_file("/tmp/service_account.json",scopes=scopes)

    # Authorize with Google Sheets API
    gc = gspread.authorize(creds)

    print(creds.service_account_email)
    sh = gc.open('1. Verificación / Preactivación CtasLive') #Read gsheet file

    #Selecet Workshit
    worksheet_2024 = sh.get_worksheet(0)
    worksheet_2023 = sh.get_worksheet(1)
    worksheet_2022 = sh.get_worksheet(2)

    data = worksheet_2022.get_all_values()
    # Convert data to DataFrame
    df = pd.DataFrame(data[1:], columns=data[0])

    #Create Data frames
    live_accounts_2024 = pd.DataFrame(worksheet_2024.get_all_records())
    live_accounts_2023 = pd.DataFrame(worksheet_2023.get_all_records())
    live_accounts_2022 = pd.DataFrame(worksheet_2022.get_all_records())

    #Drop useless columns
    live_accounts_2024 = live_accounts_2024.drop(['CERT','CONT','PAG','NOTES','EXPIRATION DATE'],axis = 1)
    live_accounts_2023 = live_accounts_2023.drop(['CERT','CONT','PAG','NOTES','EXPIRATION DATE'], axis = 1)
    live_accounts_2022 = live_accounts_2022.drop(['CERT','CONT','PAG','NOTES','EXPIRATION DATE','PAYMENT METHOD'], axis = 1)

    #Rename columns live_accounts_2022
    rename = {
        'funded date': 'Funded - YAIR',
        'ACCOUNT' : 'ACCOUNT NAME',
        'CONTRACT' : 'CYP'
    }
    live_accounts_2022 = live_accounts_2022.rename(columns = rename)

    live_accounts = pd.concat([live_accounts_2022,live_accounts_2023])
    live_accounts = pd.concat([live_accounts,live_accounts_2024])

    #Rename columns live_accounts
    rename = {
    'FULL NAME':'FULL_NAME',
    'ID':'LOCAL_ID',
    'ACCOUNT NAME':'ACCOUNT_NAME',
    'Funded - YAIR':'Funded_YAIR',
    'TX ID':'TX_STRIPE_ID',
    'Método': 'TX_METHOD',
    'AGENT V': 'AGENT_V',
    'AGENT C': 'AGENT_C'
    }
    live_accounts = live_accounts.rename(columns = rename)

    #Transform columns to date
    live_accounts = live_accounts[live_accounts['DATE'] != 'OSCARPASTORUPTN190563'] #Delete 2 rows with user name data in the DATE column
    live_accounts['DATE'] = pd.to_datetime(live_accounts['DATE'], errors='coerce') #Transform column date into Datetime
    live_accounts['CYP'] = pd.to_datetime(live_accounts['CYP'], errors='coerce') #Transform column CYP into Datetime
    live_accounts['Funded_YAIR'] = pd.to_datetime(live_accounts['Funded_YAIR'], errors='coerce') #Transform column Funded - YAIR into Datetime


    #Transform balance to float
    live_accounts['BALANCE'] = live_accounts['BALANCE'].str.extract(r'(\d+\.?\d*)', expand=False)
    live_accounts['BALANCE'] = live_accounts['BALANCE'].str.replace(',','').astype(float)
    # Remove non-numeric characters from the 'size' column
    #live_accounts['SIZE'] = live_accounts['SIZE'].str.replace(r'\D', '', regex=True)
    #live_accounts['SIZE'].replace(np.nan,0,inplace=True)
    #live_accounts[live_accounts['DATE'] >= '2024-04-01'].head()

    # total rows 35276
    #Looking for nulls values
    live_accounts.replace('', np.nan)
    live_accounts_nulls = live_accounts.isna().astype(int)


    #Transform column to string
    live_accounts['DAYS'] = live_accounts['DAYS'].astype(str)
    live_accounts['AGENT_V'] = live_accounts['AGENT_V'].astype(str)
    live_accounts['AGENT_C'] = live_accounts['AGENT_C'].astype(str)
    live_accounts['Funded_YAIR'] = live_accounts['Funded_YAIR'].astype(str)
    live_accounts['TX_STRIPE_ID'] = live_accounts['TX_STRIPE_ID'].astype(str)
    live_accounts['LOCAL_ID'] = live_accounts['LOCAL_ID'].str.strip() #Delete empty spaces in ID column
    live_accounts['LOCAL_ID'] = live_accounts['LOCAL_ID'].astype(str)
    live_accounts['SIZE'] = live_accounts['SIZE'].astype(str)
    live_accounts['Monto'] = pd.to_numeric(live_accounts['Monto'], errors='coerce').fillna(0)

    import pandas_gbq

    # Set up BigQuery credentials
    project_id = "uprofittrader-ga4"  # Replace with your project ID
    dataset_id = "analytics_417386444"  # Replace with your dataset ID
    table_id = f"{project_id}.{dataset_id}.live_accounts"  # Replace "your_table" with your table name

    #live_accounts.astype(str)
    # Upload DataFrame to BigQuery with specified schema
    #live_accounts = live_accounts.astype(str)
    pandas_gbq.to_gbq(live_accounts[['DATE','FULL_NAME','LOCAL_ID','GENDER','NATIONALITY','USERNAME','COUNTRY','ACCOUNT_NAME','EMAIL','SIZE','DAYS','BALANCE','AGENT_V','AGENT_C'
    ,'CYP','Funded_YAIR','TX_STRIPE_ID','Monto','TX_METHOD']], table_id, project_id=project_id, if_exists='replace')

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())     