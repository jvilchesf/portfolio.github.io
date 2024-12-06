---
title: "[Looker Studio] Sales Dashboard"
excerpt: "An interactive dashboard for tracking daily subscription sales<br/><img src='https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_3_lookerStudio_Uprofit.png' width=300 height=300>"
collection: portfolio
---

## Overview

This project involved integrating multiple technologies to create a unified solution for tracking and analyzing sales data. The client, a subscription-based company, transitioned from using Facebook Pixel and Google Analytics to leveraging **Google Cloud Platform (GCP)**, including **GA4** and **Google Tag Manager (GTM)**, for enhanced sales tracking.

## Problem Statement

While the existing setup tracked daily sales effectively, it lacked visibility into monthly subscription renewals. Additionally, new data sources from **Supabase** and **Google Sheets** introduced the challenge of consolidating diverse datasets into a single, comprehensive view. This required building a unified solution to track sales performance across multiple channels.

## Solution

The deliverable was an **interactive Looker Studio dashboard**, updated daily, consolidating data from:
- **GA4 (via GTM)**: For tracking daily sales and user interactions.
- **Supabase**: For subscription renewals.
- **Google Sheets**: For additional revenue streams.
- **Stripe**: For matching the numbers 

## Outcome

The dashboard provided the client with:
- **Centralized Insights**: A unified view of sales performance across all channels.
- **Enhanced Decision-Making**: Real-time monitoring of daily and monthly sales trends.
- **Campaign Effectiveness**: Insights into high-performing social media campaigns.



**Access the dashboard** [here](https://lookerstudio.google.com/u/0/reporting/cdc372da-515a-4510-9c68-ed8da67b1d63/page/p_13p464yedd).

<div style="text-align: center;">  
    <img src="https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_3_dashboard.png" alt="Sales Dashboard" width="600" height="600">
</div>

## Workflow Diagram

<div style="text-align: center;">
    <img src="https://raw.githubusercontent.com/jvilchesf/portfolio.github.io/refs/heads/main/images/portfolio_viz_3_workflow_.png" alt="Workflow Diagram" width="600" height="600">
</div>

---

## Tools and Technologies

The following tools and technologies were utilized to streamline data integration, processing, and visualization:

- **Python (Google Cloud Functions)**: For data extraction, cleaning, and loading from multiple sources (Supabase, Stripe, Google Sheets, GA4).
- **SQL (BigQuery)**: To structure, transform, and aggregate data from all sources into a single view.
- **Google Tag Manager (GTM)**: For tracking user interactions and automating analytics implementation.
- **Google Analytics 4 (GA4)**: For capturing customer behavior and tracking key metrics.
- **Looker Studio**: For creating dynamic dashboards with real-time updates.

---

## Dataset Description and Methodology

This project integrated data from four key sources:

### 1. Supabase Sales Data
- **Records**: 5,072,138
- **Fields**: `payment_id`, `payment_amount`, `payment_date`, `subscription_id`, `checkout_status`
- **Purpose**: Tracks payments, subscriptions, and user activity.

### 2. Stripe Sales Data
- **Records**: 279,895
- **Fields**: `id`, `amount`, `fee`, `customer_email`, `currency`
- **Purpose**: Captures Stripe transaction details, including fees and customer information.

### 3. Live Accounts Data (Google Sheets)
- **Records**: 38,573
- **Fields**: `FULL_NAME`, `BALANCE`, `COUNTRY`, `TX_STRIPE_ID`
- **Purpose**: Provides user account information, including demographics and financial data.

### 4. GA4 Event Data
- **Records**: 13,497,845
- **Fields**: `event_name`, `event_params`, `user_id`, `platform`
- **Purpose**: Tracks user interactions, app behavior, and traffic sources.

---

## Results and Insights

### Key Findings:
1. **Sales Trends**: The line graph highlighted daily sales patterns, showing peak periods and seasonal trends.
2. **Payment Insights**: The majority of payments were processed via **Stripe (80.4%)**, with additional insights into alternative payment methods.
3. **Revenue Distribution**: Country and product-type breakdowns revealed key revenue sources.
4. **Campaign Effectiveness**: Analysis of sales sources (e.g., direct traffic, organic search) enabled better resource allocation.

### Implications:
- Streamlined sales tracking across multiple channels.
- Data-driven decisions to optimize campaigns and revenue streams.
- Reduced manual effort by automating data integration and reporting.

---

## Impact

- **Efficiency Gains**: Automated data refresh reduced manual processing by **90%**.
- **Streamlined Tracking**: Centralized sales performance metrics saved time and improved responsiveness.

---

## Code Repository

Access the full repository [here](https://github.com/jvilchesf/portfolio.github.io/tree/main/_portfolio_scripts/sales_dashboard).

### Key Scripts:
- **Supabase**:
  - `get_data_supabase_db.sql`: Creates and refreshes sales data in Supabase.
  - `get_data_supabase.py`: Extracts data from Supabase into BigQuery.
- **Stripe**:
  - `get_data_stripe.py`: Pulls data from Stripe via API.
  - `transform_data_bq_stripe.sql`: Structures Stripe data in BigQuery.
- **Google Sheets**:
  - `get_data_csv_liveaccounts.py`: Pulls live account data into BigQuery.
- **GA4 Integration**:
  - `transform_data_bq_dashboard.sql`: Merges data from all sources every 15 minutes.

---

## Workflow Integration

### How the Scripts Work Together:
1. **Supabase**: Data is refreshed via SQL (`get_data_supabase_db.sql`) and pulled into BigQuery with Python (`get_data_supabase.py`).
2. **Stripe**: API data is pulled with Python (`get_data_stripe.py`) and structured in BigQuery (`transform_data_bq_stripe.sql`).
3. **Google Sheets**: Data is extracted and loaded into BigQuery (`get_data_csv_liveaccounts.py`).
4. **GA4**: Event data is merged with other sources using a BigQuery script (`transform_data_bq_dashboard.sql`).

The final merged table feeds directly into Looker Studio, providing real-time, actionable insights for stakeholders.
