/*
  Task 1 – EDA: Data quality checks.

  Key findings this model surfaces:
  1. Orphaned order_fct rows (no matching order in order_dim)
  2. Orphaned order_fct rows (no matching club in club_dim)
  3. MRR null rate by product_category (Camera = hardware, null MRR expected)
  4. Ecommerce flag null rate
  5. Orders with multiple line items (confirms multi-product order structure)
*/

with fct as (select * from {{ ref('stg_order_fct') }}),
     ord as (select * from {{ ref('stg_order_dim') }}),
     club as (select * from {{ ref('stg_club_dim') }})

select 'orphaned_fct_no_order_dim' as check_name,
       count(*) as affected_rows,
       round(count(*) * 100.0 / (select count(*) from fct), 2) as pct_of_fct
from fct
where order_id not in (select order_id from ord)

union all

select 'orphaned_fct_no_club_dim',
       count(*),
       round(count(*) * 100.0 / (select count(*) from fct), 2)
from fct
where clubhouse_id not in (select clubhouse_id from club)

union all

select 'null_mrr_camera_rows',
       count(*),
       round(count(*) * 100.0 / (select count(*) from fct where product_category = 'Camera'), 2)
from fct
where product_category = 'Camera' and new_mrr is null

union all

select 'null_mrr_base_rows',
       count(*),
       round(count(*) * 100.0 / (select count(*) from fct where product_category = 'Base'), 2)
from fct
where product_category = 'Base' and new_mrr is null

union all

select 'null_mrr_addon_rows',
       count(*),
       round(count(*) * 100.0 / (select count(*) from fct where product_category = 'Add-on'), 2)
from fct
where product_category = 'Add-on' and new_mrr is null

union all

select 'null_is_ecommerce_order',
       count(*),
       round(count(*) * 100.0 / (select count(*) from ord), 2)
from ord
where order_is_ecommerce_order is null

union all

-- Orders with >1 line item in order_fct
select 'orders_with_multiple_line_items',
       count(*),
       round(count(*) * 100.0 / (select count(distinct order_id) from fct), 2)
from (
    select order_id
    from fct
    group by order_id
    having count(*) > 1
) multi
