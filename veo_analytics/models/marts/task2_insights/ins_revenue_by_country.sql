/*
  Task 2 – Insight: Revenue by country.

  Why it matters: Identifying top markets by MRR helps the product/monetisation
  team prioritise localisation, pricing strategy, and self-serve feature rollout
  by geography.

  Limitation: club_dim has country_name but no sub-region. Country alone may
  mask regional variation within large markets.
*/

select
    coalesce(country_name, 'Unknown')           as country_name,
    count(distinct order_id)                    as total_orders,
    count(distinct clubhouse_id)               as total_clubs,
    round(sum(new_mrr), 2)                     as total_new_mrr,
    round(avg(new_mrr), 2)                     as avg_mrr_per_line_item,
    round(sum(unit_price * unit_quantity), 2)  as total_gross_order_value,
    sum(case when is_hardware then 1 else 0 end) as camera_line_items,
    sum(case when not is_hardware and new_mrr is not null then 1 else 0 end) as software_line_items
from {{ ref('int_orders_enriched') }}
group by country_name
order by total_new_mrr desc nulls last
