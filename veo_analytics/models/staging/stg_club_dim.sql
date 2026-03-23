with source as (
    select * from {{ source('raw', 'club_dim') }}
),

cleaned as (
    select
        -- Strip BOM character that appears on the first column of this CSV
        replace(clubhouse_id, chr(65279), '')  as clubhouse_id,
        try_cast(clubhouse_created_at as timestamp)  as clubhouse_created_at,
        country_name
    from source
)

select * from cleaned
