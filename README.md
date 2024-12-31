# **3 SQL Queries Asked in Interview for Business Analyst**


This document introduces and solves three key SQL problems often posed during Business Analyst interviews. Each query addresses real-world scenarios to demonstrate a strong understanding of SQL capabilities such as data transformation, aggregation, and ranking.

---

## 1. Election Query

### Problem
Analyze election results to determine the number of seats won by each political party. The data includes:
- `candidates`: Details about candidates, including their associated parties.
- `results`: Voting outcomes, including votes received by candidates across constituencies.

### Target
Identify which party won the most seats by calculating the number of constituencies each party secured.

### Solution
- **Join Data**: Combine `results` and `candidates` tables to associate votes with parties.
- **Rank Votes**: Use the `ROW_NUMBER()` function to rank candidates in each constituency by votes.
- **Aggregate Results**: Count the number of seats won by each party using `SUM` with a conditional case.

```sql
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
```
## 2. Advertising System Deviations Report

### Problem
Identify campaigns with the highest success and failure counts for each customer. The data includes:
- `customers`: Information about customers.
- `campaigns`: Campaign details linked to customers.
- `events`: Events associated with campaigns, categorized by status (e.g., success, failure).

### Target
Generate a report showing:
- Campaign names and their outcomes for each customer.
- The campaigns with the most successes and failures.

### Solution
- **Count Events by Status**: Aggregate `events` to determine the number of successes and failures for each campaign.
  ```sql
  select
      c.customer_id,
      e.[status],
      count(e.[status]) as [count]
  from campaigns c
  join events e on c.id = e.campaign_id
  group by c.customer_id, e.[status];
  ```
- **Summarize by Customer:** Use conditional aggregation to calculate the total success and failure counts for each customer.

    ```sql
    select
        customer_id,
        sum(case when [status] = 'success' then [count] else 0 end) as success_count,
        sum(case when [status] = 'failure' then [count] else 0 end) as failure_count
    from cte_count
    group by customer_id;
    ```
- **Highlight Extremes:** Identify campaigns with the maximum success and failure counts for reporting. This focuses on key deviations.
    ```sql
    select
        customer_name,
        campaign,
        success_count,
        failure_count
    from cte_category
    where success_count = (select max(success_count) from cte_category)
    or failure_count = (select max(failure_count) from cte_category);
    ```
By emphasizing these core steps, the report highlights customers and campaigns with notable success or failure rates, aiding in identifying patterns and potential improvements.

## 3. Election Exit Poll by State Report

### Problem  
The query attempts to generate a report on election exit polls by state, showing the ranking of candidates in each state. It includes information on the candidate name, their rank per state, and the number of candidates per state. The data includes:  
- `results`: Constituency-level vote counts.  
- `candidates`: Candidate details, including their party.  
- `states`: Information about states and constituencies.  

### Target  
 
- To generate an election exit poll report by state, displaying the candidate names along with their ranking for each state (1st, 2nd, 3rd).
- Ensure that no data is missing when there is no state rank for a particular candidate (handling the cases where candidates do not have 1st, 2nd, or 3rd places).

### Solution  

1. **Aggregate Votes**: Calculate the total votes received by each candidate within each state.  
2. **Rank Candidates**: Use `DENSE_RANK()` to assign ranks to candidates based on the total votes they received in each state. The rank will determine the positions (1st, 2nd, 3rd, etc.) of candidates within each state.  
3. **Extract Candidate Rankings:** Filter the data to extract the top three ranked candidates in each state.

---

```sql
-- Step 1: Aggregate votes by state and party
with cte_grouped as (   
    select 
        distinct
        concat(first_name, ' ', last_name) as candidate_name,
        rt.*,
        COUNT(state) over (partition by candidate_id, state) as total_candidates
    from candidates_tab ct 
    join results_tab rt on ct.id = rt.candidate_id
),

-- Step 2: Rank parties by total votes in each state
cte_ranked as (
    select
        candidate_name,
        total_candidates,
        CONCAT(state, ' (', total_candidates, ')') as state_with_count,
        dense_rank() over (partition by candidate_id order by total_candidates desc) as rank
    from cte_grouped
)

-- Step 3: Extract the candidate names along with their ranking for each state (1st, 2nd, 3rd)
select
    candidate_name,
    STRING_AGG(case when rank = 1 then state_with_count end, ', ') as '1st_place',
    STRING_AGG(case when rank = 2 then state_with_count end, ', ') as '2nd_place',
    STRING_AGG(case when rank = 3 then state_with_count end, ', ') as '3rd_place'
from cte_ranked
group by candidate_name;
```
## Conclusion
In conclusion, the three SQL queries demonstrate important skills for Business Analysts, including data aggregation, ranking, and transformation. These techniques are essential for analyzing and deriving insights from complex datasets. Mastery of such SQL operations helps business analysts efficiently solve real-world problems and support data-driven decisions.