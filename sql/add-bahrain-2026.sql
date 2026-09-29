-- Add the 2026 Bahrain Grand Prix, run at the Sepang International Circuit in Malaysia
-- on 3 and 4 October 2026.
--
-- Data rather than schema, kept here for the same reason as the setup-2026 files, so
-- that what went into the database is recorded and repeatable.
--
-- BEWARE: there are now TWO events named 'Bahrain Grand Prix' in the 2026 season. The
-- original was round 4 in April, cancelled because of the war in Iran, and it is left
-- exactly as it is. This race is essentially that one rescheduled, and keeps the name,
-- but it is a new event rather than a revival of the old row, so that the April
-- cancellation stays on the calendar. Every statement below that needs to find the new
-- event matches on season, round, name AND cancelled = 0 together. The April row is
-- round 4 with cancelled = 1, so it cannot match on any of three separate counts.
-- Nothing here updates or deletes anything belonging to it.
--
-- Start times are RFC3339, with the T and the Z, matching every other session.

BEGIN TRANSACTION;

-- The new race falls between Azerbaijan on 26 September and Singapore on 11 October,
-- so it takes round 18 and everything from Singapore onwards shifts up one. Round is
-- what the season list and the previous/next event navigation sort by, so appending it
-- as round 25 instead would have shown this weekend's race after Abu Dhabi.
--
-- This runs BEFORE the insert below, so round 18 is free by the time the new event
-- claims it and there is never a moment at which two events share a round.
update formula_one_events
set round = round + 1
where season = '2026'
  and round >= 18
;

insert into formula_one_events (round, name, season, cancelled) values (
    18,
    'Bahrain Grand Prix',
    '2026',
    0
);

-- fastest_lap is 0 on both sessions, as it is on every other 2026 session: the point
-- for the fastest lap is not part of the 2026 rules.
insert into formula_one_sessions (name, start_time, event, cancelled, half_points, fastest_lap)
select
    session.name,
    session.start_time,
    (
        select id from formula_one_events
        where season = '2026' and round = 18
          and name = 'Bahrain Grand Prix' and cancelled = 0
    ),
    0,
    0,
    0
from (
            select 'qualifying' as name, '2026-10-03T08:00:00Z' as start_time
    union all select 'race',             '2026-10-04T07:00:00Z'
) as session
;

-- The field is the same as the previous race, the Azerbaijan Grand Prix, whose race
-- session is 163. Copying from it rather than listing 22 drivers again keeps this in
-- step with whatever the line-up actually was, including Lindblad in the Racing Bulls
-- seat rather than Tsunoda.
--
-- rank only controls the order the entrant list is displayed in, and these ranks are
-- the ones that were current before the Azerbaijan result. `make update-ranks` will
-- recompute them from the standings, along with every other session yet to be run.
insert into formula_one_entrants (number, driver, team, session, participating, rank)
select
    source.number,
    source.driver,
    source.team,
    new_session.id,
    source.participating,
    source.rank
from formula_one_entrants as source
cross join (
    select s.id
    from formula_one_sessions s
    where s.event = (
        select id from formula_one_events
        where season = '2026' and round = 18
          and name = 'Bahrain Grand Prix' and cancelled = 0
    )
) as new_session
where source.session = 163
;

COMMIT;
