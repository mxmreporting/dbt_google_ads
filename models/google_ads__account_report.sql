{{ config(enabled=var('ad_reporting__google_ads_enabled', True),
    unique_key = ['source_relation','account_id','date_day'],
    partition_by={
      "field": "date_day",
      "data_type": "date",
      "granularity": "day"
    }
    ) }}

with stats as (

    select *
    from {{ var('account_stats') }}
), 

accounts as (

    select *
    from {{ var('account_history') }}
    where is_most_recent_record = True
), 

fields as (

    select
        stats.source_relation,
        stats.date_day,
        accounts.account_name,
        stats.account_id,
        accounts.currency_code,
        accounts.auto_tagging_enabled,
        accounts.time_zone,
        sum(stats.spend) as spend,
        sum(stats.clicks) as clicks,
        sum(stats.impressions) as impressions

        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='google_ads__account_stats_passthrough_metrics', transform = 'sum') }}

    from stats
    left join accounts
        on stats.account_id = accounts.account_id
        and stats.source_relation = accounts.source_relation
    {{ dbt_utils.group_by(7) }}
)

select *
from fields
