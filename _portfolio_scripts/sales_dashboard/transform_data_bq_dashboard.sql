
#DECLARE FISRT DATE MONTH DATETIME AND TIMESTAMP FOR AUTOMATIZATE PROCESS
DECLARE FIRST_DATE_MONTH TIMESTAMP;
DECLARE FIRST_DATE_MONTH_DATETIME DATETIME;
DECLARE FIRST_RUNNING TIMESTAMP;

SET FIRST_DATE_MONTH = (SELECT TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MONTH));
SET FIRST_DATE_MONTH_DATETIME = (SELECT DATE_TRUNC(CURRENT_DATE(), MONTH));

-- SET VARIABLE FOR FIRST RUNNING
--SET FIRST_RUNNING = '2023-01-01 00:00:00';
--SET FIRST_DATE_MONTH = FIRST_RUNNING;
--SET FIRST_DATE_MONTH_DATETIME = '2023-01-01';

--DELETE ROWS FINAL TABLE BEFORE FIRST RUNNING
delete from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_tidy` where date_purchase >= FIRST_DATE_MONTH_DATETIME;

#CREATE TEMP TABLE WITH STRIPE LEFT JOIN SUPABASE, IT'LL HAVE JUST STRIPE PAYMENT
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_payments`
AS
SELECT  
      a.id stripe_id_trx,
      b.payment_id supabase_payment_id,
      rithmic_account_name,
      FORMAT_DATETIME('%Y-%m-%d',TIMESTAMP_ADD(a.created_date, INTERVAL -5  HOUR)) Date_purchase,
      TIMESTAMP_ADD(b.payment_date,INTERVAL -5 HOUR) supabase_timestamp,
      a.created_date stripe_timestamp, 
      case when a.customer_email is null then b.email 
          when b.email is null then a.customer_email
          when b.email is not null and a.customer_email is not null then a.customer_email 
      end email,  
      case  
          when b.rithmic_id is null and a.amount_charge = 100.0 then 'Live 9k' 
          when b.rithmic_id is null and a.amount_charge = 150.0 then 'Live 30k - 50k'
          when b.rithmic_id is null and a.amount_charge = 250.0 then 'Live 100k - 150k'
          when b.rithmic_id is null and a.amount_charge = 380.0 then 'Live 200k'
          when b.rithmic_id is null and a.id is null then 'Ambos origenes null'          
          when b.payment_type = 'reset' then concat('account-reset- ',b.rithmic_id)
          when b.rithmic_id is not null and a.id is not null then b.rithmic_id
          else 'No info' 
      end product_type,    
      case  when a.amount_charge is not null and b.payment_amount is null then a.amount_charge
            when a.amount_charge is null and b.payment_amount is not null then b.payment_amount
            else a.amount_charge 
      end payment_amount,
      a.fee stripe_fee,
      case when a.id is not null and b.payment_method is not null then b.payment_method
            when a.id is not null and b.payment_method is null then 'stripe'
          else 'Other' 
      end payment_method,
      case when b.rithmic_id is null and a.id is not null then 'successful'
          else b.payment_status 
      end payment_status,
      case  when b.rithmic_id is null and (a.amount_charge = 150.0 or a.amount_charge = 100.0 or a.amount_charge = 380.0 or a.amount_charge = 250.0) then 'Live account'  
            when b.subscription_status is null then 'Stripe data status missed' 
            else b.subscription_status 
      end subscription_status,
      case  when b.rithmic_id is null and (a.amount_charge = 150.0 or a.amount_charge = 100.0 or a.amount_charge = 380.0 or a.amount_charge = 250.0) then 'Live account' 
            when b.payment_type is null then 'Stripe payment type missed'
            else b.payment_type 
      end payment_type, 
      a.payment_method_country country,
    	case    when a.id is not null and b.payment_id is null then 'Stripe'  
              when a.id is not null and b.payment_id is not null  then 'Stripe (Complemented with Supabase)'
              else  'Others' 
      end  Origin_data,
      checkout_coupon_id          
FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe` a
left join `uprofittrader-ga4.analytics_417386444.Dashboard_sales_supabase` b on b.email = a.customer_Email and TIMESTAMP_DIFF(TIMESTAMP_ADD(b.payment_date,INTERVAL -5 HOUR),a.created_date,second) between -10 and 10 and a.amount = b.payment_amount
WHERE TIMESTAMP_ADD(a.created_date, INTERVAL -5  HOUR) >= FIRST_DATE_MONTH
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17;

#CREATE TEMP TABLE WITH SUPABASE DATA, CONSIDERING ALL KIND OF PAYMENT BUT NOT STRIPE, IT'LL HAVE JUST STRIPE PAYMENT
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_coin_paypal_payments`
AS
SELECT  
      '' stripe_id_trx,
      payment_id supabase_payment_id,
      rithmic_account_name,
      FORMAT_DATETIME('%Y-%m-%d',TIMESTAMP_ADD(a.payment_date, INTERVAL -5  HOUR)) Date_purchase,
      TIMESTAMP_ADD(payment_date,INTERVAL -5 HOUR) supabase_timestamp,
      CURRENT_TIMESTAMP() stripe_timestamp, 
      a.email email,  
      case when payment_type = 'reset' then concat('account-reset- ',rithmic_id) else rithmic_id end product_type,    
      a.payment_amount payment_amount,
      null stripe_fee,
      a.payment_method payment_method,
      a.payment_status payment_status,
      a.subscription_status subscription_status,
      a.payment_type payment_type, 
      locale country,
      'Supabase' Origin_data,
      checkout_coupon_id         
    FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_supabase` a
    where TIMESTAMP_ADD(payment_date,INTERVAL -5 HOUR) >= FIRST_DATE_MONTH
    and  a.payment_method != 'stripe'
    group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17;


#UNION STRIPE PAYMENTS VS REST PAYMENTS
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_payments` 
AS
SELECT * FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_payments`
UNION ALL
SELECT * FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_coin_paypal_payments`;

#CROSS GA4 INFORMATION WITH HISTORIC TABLE
-- CREATE MAIN GA4 DATA TABLE
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source` 
AS
SELECT 
user_pseudo_id user_id,
MAX(CASE WHEN key = 'cookie client id' THEN value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as cookie_user_id,
parse_date('%Y%m%d', event_date) as event_date,
TIMESTAMP_MICROS(event_timestamp) as event_ts,
events.event_name,
MAX(CASE WHEN params.key = 'rithmic_account_name' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as rithmic_account_name,
MAX(CASE WHEN params.key = 'page_title' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as page_title,
MAX(CASE WHEN params.key = 'page_location' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as page_location,
MAX(CASE WHEN params.key = 'item_id' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as item_id,
MAX(CASE WHEN params.key = 'item_name' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as item_name,
MAX(CASE WHEN params.key = 'payment_type' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as payment_type,
MAX(CASE WHEN params.key = 'discount' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as discount,
MAX(CASE WHEN params.key = 'cupon' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as cupon,
MAX(CASE WHEN params.key = 'affiliateId' THEN params.value.string_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as affiliateId,
MAX(CASE WHEN params.key = 'value' THEN params.value.int_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as value,
MAX(CASE WHEN params.key = 'price' THEN params.value.int_value ELSE NULL END) OVER (PARTITION BY event_timestamp, user_pseudo_id) as price,
traffic_source.name as utm_channel,
case when traffic_source.medium is null then traffic_source.source
    when traffic_source.source is null then traffic_source.medium 
    else CONCAT(traffic_source.source, '/', traffic_source.medium) end as source_medium,
CASE 
        WHEN traffic_source.source = "(direct)" AND traffic_source.medium IN ("(not set)", "(none)") THEN "Direct"
        WHEN traffic_source.source IN ('google', 'yahoo', 'bing', 'yandex') AND REGEXP_CONTAINS(traffic_source.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN "Paid Search"
        WHEN traffic_source.source IN ('facebook', 'instagram', 'linkedin', 'twitter', 'pinterest', 'quora', 'reddit', 't.co') AND REGEXP_CONTAINS(traffic_source.medium, r'^(.*cp.*|ppc|retargeting|paid.*)$') THEN "Paid Social"
        WHEN traffic_source.source IN ('youtube', 'vimeo', 'dailymotion') AND REGEXP_CONTAINS(traffic_source.medium, r'(.*cp.*|ppc|retargeting|paid.*)$') THEN "Paid Video"
        WHEN traffic_source.medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN "Display"
        WHEN traffic_source.source IN ('google', 'yahoo', 'bing', 'yandex') AND REGEXP_CONTAINS(traffic_source.medium, r'(.*cp.*|ppc|retargeting|paid.*)$') THEN "Paid Other"
        WHEN traffic_source.source IN ('facebook', 'instagram', 'linkedin', 'twitter', 'pinterest', 'quora', 'reddit', 't.co') OR traffic_source.medium IN ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media') THEN "Organic Social"
        WHEN traffic_source.source IN ('youtube', 'vimeo', 'dailymotion') OR REGEXP_CONTAINS(traffic_source.medium, r'(.*video.*)$') THEN "Organic Video"
        WHEN traffic_source.source IN ('google', 'yahoo', 'bing', 'yandex') OR traffic_source.medium = 'organic' THEN "Organic Search"
        WHEN traffic_source.medium IN ('referral', 'app', 'link') THEN "Referral"
        WHEN (traffic_source.source IN ('email', 'e-mail', 'e_mail', 'e mail') OR traffic_source.medium IN ('email', 'e-mail', 'e_mail', 'e mail')) THEN "Email"
        WHEN traffic_source.medium = 'affiliate' THEN "Affiliates"
        WHEN traffic_source.medium = 'audio' THEN "Audio"
        WHEN traffic_source.source = 'sms' OR traffic_source.medium = 'sms' THEN "SMS"
        WHEN traffic_source.medium LIKE '%push' OR traffic_source.medium LIKE '%mobile%' OR traffic_source.medium LIKE '%notification%' OR traffic_source.source = 'firebase' THEN "Mobile Push Notifications"
        ELSE traffic_source.medium
    END AS group_source_medium,
geo.country as country,
geo.continent as continent,
device.operating_system as device_operating_system,
device.category as device_category
 FROM `uprofittrader-ga4.analytics_417386444.events*` events
 left join UNNEST(event_params) as params
where events.event_name = 'purchase'
and TIMESTAMP_MICROS(event_timestamp) > FIRST_DATE_MONTH;
--and TIMESTAMP_MICROS(event_timestamp) > '2024-05-01 00:00:00';

-- DELETE DUPLICATES
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source_1` 
AS
select a.*,
case when payment_type = 'coinPayments' then 'coinpayments' else payment_type end payment_type2
from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source` a
where page_location like '%payment-confirmation%'
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24;

#CROSS GA4 TABLE WITH HISTORIC PAYMENTS
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_ga4_histo`  
AS
select stripe_id_trx
,supabase_payment_id
,parse_datetime('%Y-%m-%d',Date_purchase) Date_purchase
,email
,case when b.item_id is not null then b.item_id 
      else product_type
      end product_type
,payment_amount
,stripe_fee
,trim(UPPER(payment_method)) payment_method
,payment_status
,subscription_status
,a.payment_type
,affiliateId ga4_affiliateId
,case when b.cupon is null then checkout_coupon_id else b.cupon end ga4_cupon
,case when b.source_medium is not null then b.source_medium else 'No Info' end ga4_source_medium
,case when b.group_source_medium is not null then b.group_source_medium else 'No info' end ga4_group_source_medium
,case when b.country is not null then b.country else a.country end country
,case when b.rithmic_account_name is null then origin_data
      when b.rithmic_account_name  is not null then concat(origin_data,' (Complemented with GA4)')
     else Origin_data end Origin_data
FROM `uprofittrader-ga4.analytics_417386444.Dashboard_sales_payments` a
left join `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source_1` b on a.rithmic_account_name = b.rithmic_account_name and TIMESTAMP_DIFF(a.supabase_timestamp,TIMESTAMP_ADD(b.event_ts, INTERVAL -5  HOUR), SECOND) between -10 and 10
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17
union all
SELECT 
  NULL AS stripe_id_trx,
  NULL AS supabase_payment_id,
  event_date Date_purchase, -- Adjust the date format if needed
  NULL AS email,
  item_id AS product_type,
  value AS payment_amount,
  NULL AS stripe_fee,
  trim(upper(payment_type2)) payment_method,
  NULL AS payment_status,
  NULL AS subscription_status,
  NULL AS payment_type,
  affiliateId AS ga4_affiliateId,
  cupon AS ga4_cupon,
  source_medium AS ga4_source_medium,
  group_source_medium AS ga4_group_source_medium,
  country AS country,
  'GA4' AS origin_data
FROM 
  `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source_1`
WHERE 
  payment_type2 != 'stripe';

#CREATE TABLE LIVE ACCOUNTS PAYMENTS
CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.Dashboard_sales_live_accounts`  
AS
SELECT 
TX_STRIPE_ID stripe_id_trx	
,null supabase_payment_id	
,PARSE_DATETIME('%Y-%m-%d',FORMAT_TIMESTAMP('%Y-%m-%d',DATE)) Date_purchase
,EMAIL email
,'Live account' product_type
--,case when MONTO = 'NaN' then 0  when MONTO = 'nan' then 0 else cast(Monto as float64) end payment_amount	
,Monto payment_amount
,0 stripe_fee	
,trim(upper(TX_METHOD)) payment_method
--,case when RESULT is not null then 'aprobado' else null end payment_status
,'aprobado' payment_status
,'Live account' subscription_status	
,'Live account' payment_type	
,'' ga4_affiliateId	
,'' ga4_cupon
,'Live account' ga4_source_medium	
,'Live account' ga4_group_source_medium
,COUNTRY country
,'Live account sheet' Origin_data
 FROM `uprofittrader-ga4.analytics_417386444.live_accounts`
WHERE CAST(DATE AS TIMESTAMP) >= FIRST_DATE_MONTH
group by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17;

 #INSERT DATA IN THE FINAL TABLE 
INSERT INTO `uprofittrader-ga4.analytics_417386444.Dashboard_sales_tidy`  
(stripe_id_trx
,supabase_payment_id	
,Date_purchase		
,email	
,product_type	
,payment_amount	
,stripe_fee	
,payment_method
,payment_status
,subscription_status	
,payment_type	
,ga4_affiliateId	
,ga4_cupon
,ga4_source_medium
,ga4_group_source_medium
,country
,Origin_data)
select * from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_ga4_histo`  
union all
select * from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_live_accounts`;

CREATE OR REPLACE TABLE `uprofittrader-ga4.analytics_417386444.duplicate_cases` AS
WITH ranked_table AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY stripe_id_trx
                           ORDER BY
                               CASE
                                   WHEN Origin_data = 'Stripe (Complemented with Supabase) (Complemented with GA4)' THEN 1
                                   ELSE 2
                               END) AS row_num
    FROM
        `uprofittrader-ga4.analytics_417386444.Dashboard_sales_tidy`
        where origin_data != 'Supabase'
        and stripe_id_trx != 'nan'
        order by stripe_id_trx desc
)
SELECT
    *
FROM
    ranked_table
WHERE
    row_num != 1;

delete from `uprofittrader-ga4.analytics_417386444.Dashboard_sales_tidy`  
where stripe_id_trx in (select stripe_id_trx from  `uprofittrader-ga4.analytics_417386444.duplicate_cases`)
and origin_data = 'Stripe (Complemented with Supabase)';

--DROP TEMP TABLES 
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_stripe_payments`;
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_coin_paypal_payments`;
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source`;
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_source_1`;
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_ga4_histo`;
drop table `uprofittrader-ga4.analytics_417386444.Dashboard_sales_live_accounts`;
drop table `uprofittrader-ga4.analytics_417386444.duplicate_cases`;
