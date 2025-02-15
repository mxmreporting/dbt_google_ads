{{ config(enabled=var('ad_reporting__google_ads_enabled', True),
    unique_key = ['source_relation','ad_id','ad_group_id','date_day'],
   partition_by={
      "field": "date_day",
      "data_type": "date",
      "granularity": "day"
    }
    ) }}

with stats as (

    select *
    from {{ var('ad_stats') }}
), 

accounts as (

    select *
    from {{ var('account_history') }}
    where is_most_recent_record = True
), 

campaigns as (

    select *
    from {{ var('campaign_history') }}
    where is_most_recent_record = True
), 

ad_groups as (

    select *
    from {{ var('ad_group_history') }}
    where is_most_recent_record = True
),

ads as (

    select *
    from {{ var('ad_history') }}
    where is_most_recent_record = True
), 

fields as (

    select
        stats.source_relation,
        stats.date_day,
        accounts.account_name,
        accounts.account_id,
        accounts.currency_code,
        campaigns.campaign_name,
        campaigns.campaign_id,
        ad_groups.ad_group_name,
        stats.ad_group_id,
        stats.ad_id,
        ads.ad_name,
        ads.ad_status,
        ads.ad_type,
        ads.display_url,
        ads.source_final_urls,
        sum(stats.spend) as spend,
        sum(stats.clicks) as clicks,
        sum(stats.impressions) as impressions

        {{ fivetran_utils.persist_pass_through_columns(pass_through_variable='google_ads__ad_stats_passthrough_metrics', transform = 'sum') }}

    from stats
    left join ads
        on stats.ad_id = ads.ad_id
        and stats.source_relation = ads.source_relation
        and stats.ad_group_id = ads.ad_group_id
    left join ad_groups
        on ads.ad_group_id = ad_groups.ad_group_id
        and ads.source_relation = ad_groups.source_relation
    left join campaigns
        on ad_groups.campaign_id = campaigns.campaign_id
        and ad_groups.source_relation = campaigns.source_relation
    left join accounts
        on campaigns.account_id = accounts.account_id
        and campaigns.source_relation = accounts.source_relation
    {{ dbt_utils.group_by(15) }}
)

select *
from fields
