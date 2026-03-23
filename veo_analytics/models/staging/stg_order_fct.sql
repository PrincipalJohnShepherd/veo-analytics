with source as (
    select * from {{ source('raw', 'order_fct') }}
),

cleaned as (
    select
        order_id,
        clubhouse_id,
        product_category,
        try_cast(unit_price    as double)  as unit_price,
        try_cast(unit_quantity as double)  as unit_quantity,
        -- new_MRR is empty for Camera (hardware) orders — keep as NULL
        nullif(trim(new_MRR), '')::double  as new_mrr,
        try_cast(order_created_at as timestamp) as order_created_at,
        date_trunc('month', try_cast(order_created_at as timestamp)) as order_month,
        order_action_type
    from source
)

select * from cleaned
