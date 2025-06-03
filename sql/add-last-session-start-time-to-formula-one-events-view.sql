drop view if exists formula_one_events_view;
create view formula_one_events_view as
    select
        id,
        round,
        name,
        season,
        case
            when exists (
                select 1
                from formula_one_sessions s
                where s.event = formula_one_events.id and s.name = "sprint"
            ) then 1
            else 0
        end as isSprint,
        cast ((select min(start_time) from formula_one_sessions s where s.event = formula_one_events.id) as text) as start_time,
        cast ((select max(start_time) from formula_one_sessions s where s.event = formula_one_events.id) as text) as last_session_start_time
    from formula_one_events
;


