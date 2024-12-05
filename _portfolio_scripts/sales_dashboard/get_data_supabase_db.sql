
select cron.schedule (
    'dashboard_sales_supabase', -- name of the cron job
    '0 * * * *', -- Saturday at 3:30am (GMT)
'drop table dashboard_subscriptions;
CREATE  TABLE dashboard_subscriptions as
select payment_id,payment_type,payment_amount,payment_method,payment_date,payment_datetime,payment_status,a.subscription_id,subscription_period_end,subscription_status,subscription_user_id,checkout_id,checkout_date,checkout_status,check_out_purchase_tracked,checkout_datetime,checkout_product_id, product.rithmic_id, u.email, ra.rithmic_account_name,
ru.rithmic_user_name, 
null as ra_active, 
null as ru_active,
u.locale
from (
select
  p.id as payment_id,
  p.type as payment_type,
  p.amount payment_amount,
  p.method payment_method,
  p.created_at payment_date,
  date(p.created_at) payment_datetime,
  p.status payment_status,
  s.id as subscription_id,
  s.period_end_date subscription_period_end,
  s.status as subscription_status,
  s.user_id subscription_user_id,
  case when c.id is null then c2.id else c.id end as checkout_id,
  case when c.created_at is null then c2.created_at else c.created_at end as checkout_date,
  case when c.status is null then c2.status else c.status end as checkout_status,
  --NULL check_out_purchase_tracked,
  case when c.purchase_tracked is null then c2.purchase_tracked else c.purchase_tracked end as check_out_purchase_tracked,
  case when date(c.created_at) is null then date(c2.created_at) else date(c.created_at) end as checkout_datetime,
  case when c.product_id is null then c2.product_id else c.product_id end as checkout_product_id
  from
  payments p
  left join subscriptions as s on p.subscription_id = s.id
  left join checkouts as c on s.checkout_id = c.id 
  left join checkouts as c2 on s.id = c2.account_reset_subscription_id
  group by p.id ,p.type,p.amount, p.method ,p.created_at,date(p.created_at),p.status,s.id ,s.period_end_date,s.status,s.user_id,case when c.id is null then c2.id else c.id end,case when c.created_at is null then c2.created_at else c.created_at end,
  case when c.status is null then c2.status else c.status end,
  case when c.purchase_tracked is null then c2.purchase_tracked else c.purchase_tracked end,
  case when date(c.created_at) is null then date(c2.created_at) else date(c.created_at) end,case when c.product_id is null then c2.product_id else c.product_id end
  ) a
  LEFT JOIN products as product ON a.checkout_product_id = product.sanity_id
  LEFT JOIN users u ON a.subscription_user_id = u.id
  LEFT JOIN rithmic_accounts ra ON a.subscription_id = ra.subscription_id --AND ra.active = true 
   LEFT JOIN rithmic_users ru ON ru.id = ra.rithmic_user_id 
   where checkout_date > ''2023-01-01 00:00:00''-- (select max(checkout_date) from dashboard_subscriptions)
   --and check_out_purchase_tracked = true
group by payment_id,payment_type,payment_amount,payment_method,payment_date,payment_datetime,payment_status
,a.subscription_id,subscription_period_end,subscription_status,subscription_user_id,checkout_id	,checkout_date	
,checkout_status,check_out_purchase_tracked,checkout_datetime,checkout_product_id,rithmic_id,email,rithmic_account_name
,rithmic_user_name,ra_active,ru_active,locale')
