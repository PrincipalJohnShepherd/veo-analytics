/*
  One row per order line item (same grain as stg_order_fct).
  Joins dimension tables to give a single wide table for all mart models.
  LEFT JOINs preserve every fact row even if dim data is missing (data quality
  issues are surfaced in eda_data_quality).
*/

with fct as (
    select * from {{ ref('stg_order_fct') }}
),

ord as (
    select * from {{ ref('stg_order_dim') }}
),

club as (
    select * from {{ ref('stg_club_dim') }}
)

select
    -- Fact keys
    fct.order_id,
    fct.clubhouse_id,

    -- Order dimension attributes
    ord.order_payment_type,
    ord.order_subscription_length,
    ord.order_is_ecommerce_order,

    -- Club dimension attributes
    club.country_name,
    club.clubhouse_created_at,

    -- Fact measures
    fct.product_category,
    fct.unit_price,
    fct.unit_quantity,
    fct.unit_price * fct.unit_quantity                   as gross_order_value,
    fct.new_mrr,
    fct.order_created_at,
    fct.order_month,
    fct.order_action_type,

    -- Convenience flags
    fct.product_category = 'Camera'                      as is_hardware,
    fct.new_mrr is not null                              as has_mrr,
    ord.order_id is null                                  as is_orphaned_order_dim,
    club.clubhouse_id is null                             as is_orphaned_club_dim

from fct
left join ord   using (order_id)
left join club  using (clubhouse_id)
