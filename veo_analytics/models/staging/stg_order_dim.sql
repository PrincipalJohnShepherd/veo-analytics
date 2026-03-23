with source as (
    select * from {{ source('raw', 'order_dim') }}
),

cleaned as (
    select
        -- Strip BOM character that appears on the first column of this CSV
        replace(order_id, chr(65279), '')                                           as order_id,
        order_payment_type,
        case
            when order_subscription_length = 'N/A' then null
            else order_subscription_length
        end                                                                          as order_subscription_length,
        -- is_ecommerce_order has ~11% empty-string values; treat as NULL
        case
            when order_is_ecommerce_order = 'true'  then true
            when order_is_ecommerce_order = 'false' then false
            else null
        end                                                                          as order_is_ecommerce_order
    from source
)

select * from cleaned
