/*
  Task 1 – EDA: Row counts, distinct primary keys, and null counts per table.
  Surfaces the grain mismatch between order_fct (86k) and order_dim (44k),
  confirming that orders can have multiple line items.
*/

with club_stats as (
    select
        'club_dim'                                  as table_name,
        count(*)                                    as total_rows,
        count(distinct clubhouse_id)               as distinct_pk,
        sum(case when clubhouse_id        is null then 1 else 0 end) as null_pk,
        sum(case when clubhouse_created_at is null then 1 else 0 end) as null_created_at,
        sum(case when country_name         is null then 1 else 0 end) as null_country,
        null::bigint                               as null_payment_type,
        null::bigint                               as null_sub_length,
        null::bigint                               as null_is_ecommerce,
        null::bigint                               as null_mrr,
        null::bigint                               as null_unit_price
    from {{ ref('stg_club_dim') }}
),

ord_stats as (
    select
        'order_dim'                                 as table_name,
        count(*)                                    as total_rows,
        count(distinct order_id)                   as distinct_pk,
        sum(case when order_id                 is null then 1 else 0 end) as null_pk,
        null::bigint                               as null_created_at,
        null::bigint                               as null_country,
        sum(case when order_payment_type       is null then 1 else 0 end) as null_payment_type,
        sum(case when order_subscription_length is null then 1 else 0 end) as null_sub_length,
        sum(case when order_is_ecommerce_order is null then 1 else 0 end) as null_is_ecommerce,
        null::bigint                               as null_mrr,
        null::bigint                               as null_unit_price
    from {{ ref('stg_order_dim') }}
),

fct_stats as (
    select
        'order_fct'                                 as table_name,
        count(*)                                    as total_rows,
        count(distinct order_id)                   as distinct_pk,
        sum(case when order_id     is null then 1 else 0 end) as null_pk,
        sum(case when order_created_at is null then 1 else 0 end) as null_created_at,
        null::bigint                               as null_country,
        null::bigint                               as null_payment_type,
        null::bigint                               as null_sub_length,
        null::bigint                               as null_is_ecommerce,
        sum(case when new_mrr      is null then 1 else 0 end) as null_mrr,
        sum(case when unit_price   is null then 1 else 0 end) as null_unit_price
    from {{ ref('stg_order_fct') }}
)

select * from club_stats
union all
select * from ord_stats
union all
select * from fct_stats
