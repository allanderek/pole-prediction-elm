with
    results as (
        select * from formula_one_prediction_lines where (user is null or user = "") and session in (
            select id from formula_one_sessions where event in (
                select id from formula_one_events where season = "2025"
            )
        )
    ),
    scored_lines as (
        select 
            sessions.name as session_name,
            case 
                when sessions.name = 'race' then
                    case 
                        when results.position = 1 then 25
                        when results.position = 2 then 18
                        when results.position = 3 then 15
                        when results.position = 4 then 12
                        when results.position = 5 then 10
                        when results.position = 6 then 8
                        when results.position = 7 then 6
                        when results.position = 8 then 4
                        when results.position = 9 then 2
                        when results.position = 10 then 1
                    else 0
                    end 
                when sessions.name = 'sprint' then
                    case 
                        when results.position = 1 then 8
                        when results.position = 2 then 7
                        when results.position = 3 then 6
                        when results.position = 4 then 5
                        when results.position = 5 then 4
                        when results.position = 6 then 3
                        when results.position = 7 then 2
                        when results.position = 8 then 1
                    else 0
                    end 
            end
            +
            case when results.fastest_lap = 'true' and sessions.fastest_lap = 1 then 1 else 0 end
                as score,
            drivers.name as driver_name,
            drivers.id as driver_id
        from results
        inner join formula_one_sessions as sessions on results.session = sessions.id
        inner join formula_one_events as events on sessions.event = events.id and events.season = "2025"
        inner join formula_one_entrants as entrants on results.entrant = entrants.id
        inner join drivers on entrants.driver = drivers.id
        where (select count(*) from results) > 0  -- Only include if results exist
    )

select 
    driver_name,
    driver_id,
    sum(score) as total
from scored_lines
group by driver_id
order by total desc
;
