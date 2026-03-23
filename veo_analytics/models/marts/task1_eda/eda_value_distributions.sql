/*
  Task 1 – EDA: Categorical value distributions.
  Shows the breakdown (count + %) for every key categorical column.
  Useful for understanding the data before building insights models.
*/

with fct as (select * from {{ ref('stg_order_fct') }}),
     ord as (select * from {{ ref('stg_order_dim') }})

-- product_category distribution
select
    'product_category'              as dimension,
    product_category                as value,
    count(*)                        as row_count,
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as pct
from fct
group by product_category

union all

-- order_action_type distribution
select
    'order_action_type',
    order_action_type,
    count(*),
    round(count(*) * 100.0 / sum(count(*)) over (), 2)
from fct
group by order_action_type

union all

-- payment_type distribution
select
    'order_payment_type',
    order_payment_type,
    count(*),
    round(count(*) * 100.0 / sum(count(*)) over (), 2)
from ord
group by order_payment_type

union all

-- subscription_length distribution
select
    'order_subscription_length',
    coalesce(order_subscription_length, 'NULL'),
    count(*),
    round(count(*) * 100.0 / sum(count(*)) over (), 2)
from ord
group by order_subscription_length

union all

-- is_ecommerce distribution
select
    'order_is_ecommerce_order',
    coalesce(cast(order_is_ecommerce_order as varchar), 'NULL'),
    count(*),
    round(count(*) * 100.0 / sum(count(*)) over (), 2)
from ord
group by order_is_ecommerce_order

order by dimension, row_count desc
