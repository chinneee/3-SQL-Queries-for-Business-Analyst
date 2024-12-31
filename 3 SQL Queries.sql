-- =====================
-- ELECTION QUERY
-- =====================

with cte_grouped as (
    select 
        r.*,
        c.party
    from results r 
    join candidates c on r.candidate_id = c.id),
cte_ranked as (
    select 
        constituency_id,
        party,
        votes,
        row_number() over (partition by constituency_id order by votes desc) as rank
    from cte_grouped
)
select
    party,
    sum(case when rank = 1 then 1 else 0 end) as seats_won
from cte_ranked
group by party;

-- ====================================
-- ADVERTISING SYSTEM DEVIATIONS REPORT
-- ====================================

with cte_count as (    
    select
        c.customer_id,
        c.name,
        e.[status],
        count(e.[status]) as [count]
    from campaigns c 
    join events e on c.id = e.campaign_id
    group by c.customer_id, c.name, e.[status]
),
cte_category as (
    select
        c.customer_id,
        STRING_AGG(c.name, ', ') as campaign,
        status,
        sum(case when [status] = 'success' then [count] else 0 end) as success_count,
        sum(case when [status] = 'failure' then [count] else 0 end) as failure_count
    from cte_count c
    group by c.customer_id, status
),
max_values as (
    select 
        max(success_count) as max_success_count,
        max(failure_count) as max_failure_count
    from cte_category
)
select
    cate.status,
    CONCAT(cust.first_name, ' ', cust.last_name) as customer_name,
    cate.campaign,
    cate.success_count,
    cate.failure_count
from cte_category cate 
join customers cust on cate.customer_id = cust.id
join max_values mv on cate.success_count = mv.max_success_count 
    or cate.failure_count = mv.max_failure_count
order by cate.status desc

-- ====================================
-- ELECTION EXIT POLL BY STATE REPORT
-- ====================================

with cte_grouped as (   
    select 
        distinct
        concat(first_name, ' ', last_name) as candidate_name,
        rt.*,
        COUNT(state) over (partition by candidate_id, state) as total_candidates
    from candidates_tab ct 
    join results_tab rt on ct.id = rt.candidate_id
),
cte_ranked as (
    select
        candidate_name,
        total_candidates,
        CONCAT(state, ' (', total_candidates, ')') as state_with_count,
        dense_rank() over (partition by candidate_id order by total_candidates desc) as rank
    from cte_grouped
)
select
    candidate_name,
    STRING_AGG(case when rank = 1 then state_with_count end, ', ') as '1st_place',
    STRING_AGG(case when rank = 2 then state_with_count end, ', ') as '2nd_place',
    STRING_AGG(case when rank = 3 then state_with_count end, ', ') as '3rd_place'
from cte_ranked
group by candidate_name;

