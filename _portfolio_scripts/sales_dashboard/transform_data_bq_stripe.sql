  -- DECLARE VARIABLE TO USE AS PARAMETER AND HAVE A LIGHT QUERY
DECLARE MAX_DATE_STRIPE TIMESTAMP;

-- SET VARIABLE WITH THE LAST DATE IN EACH TABLE
SET MAX_DATE_STRIPE = (SELECT max(created_date) FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe` limit 1);

INSERT INTO `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe`
(id,
created_date,
amount,
description,
status,
type,
fee,
id_charge,
amount_charge,
balance_transaction,
customer_email,
customer_name,
customer_id,
product_description,
currency,
status_charge,
payment_method_brand,
payment_method_country)
select a.id,
TIMESTAMP_ADD(a.created_date, INTERVAL -5 HOUR) created_date,
a.amount,
a.description,
a.status,
a.type,
a.fee,
b.id id_charge,
b.amount amount_charge,
b.balance_transaction,
b.customer_email,
b.customer_name,
b.customer_id,
b.product_description,
b.currency,
b.status status_charge,
b.payment_method_brand,
  CASE 
    WHEN payment_method_country = 'ES' THEN 'Spain'
    WHEN payment_method_country = 'CO' THEN 'Colombia'
    WHEN payment_method_country = 'US' THEN 'United States'
    WHEN payment_method_country = 'AR' THEN 'Argentina'
    WHEN payment_method_country = 'MA' THEN 'Morocco'
    WHEN payment_method_country = 'MX' THEN 'Mexico'
    WHEN payment_method_country = 'CL' THEN 'Chile'
    WHEN payment_method_country = 'GT' THEN 'Guatemala'
    WHEN payment_method_country = 'BR' THEN 'Brazil'
    WHEN payment_method_country = 'IT' THEN 'Italy'
    WHEN payment_method_country = 'DE' THEN 'Germany'
    WHEN payment_method_country = 'PA' THEN 'Panama'
    WHEN payment_method_country = 'BE' THEN 'Belgium'
    WHEN payment_method_country = 'CA' THEN 'Canada'
    WHEN payment_method_country = 'PT' THEN 'Portugal'
    WHEN payment_method_country = 'FR' THEN 'France'
    WHEN payment_method_country = 'CI' THEN 'Ivory Coast'
    WHEN payment_method_country = 'DO' THEN 'Dominican Republic'
    WHEN payment_method_country = 'SV' THEN 'El Salvador'
    ELSE payment_method_country
  END AS payment_method_country
from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_transactions` a left join 
`uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_charges` b on a.id = b.balance_transaction
where b.customer_email is not null 
and TIMESTAMP_ADD(a.created_date, INTERVAL -5 HOUR) >= MAX_DATE_STRIPE;
