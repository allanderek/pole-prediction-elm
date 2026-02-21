insert into formula_one_entrants (number, driver, team, session, rank)
select
    d.number,
    d.driver_id,
    d.team_id,
    s.id as session_id,
    d.rank
from (
    -- Ferrari (22, 21)
    select 16 as number, (select id from drivers where name = 'Charles Leclerc')        as driver_id, (select id from formula_one_teams where shortname = 'Ferrari'       and season = '2026') as team_id, 22 as rank union all
    select 44,           (select id from drivers where name = 'Lewis Hamilton'),         (select id from formula_one_teams where shortname = 'Ferrari'       and season = '2026'), 21 union all
    -- McLaren (20, 19)
    select  1,           (select id from drivers where name = 'Lando Norris'),           (select id from formula_one_teams where shortname = 'McLaren'       and season = '2026'), 20 union all
    select 81,           (select id from drivers where name = 'Oscar Piastri'),          (select id from formula_one_teams where shortname = 'McLaren'       and season = '2026'), 19 union all
    -- Red Bull (18, 17)
    select  3,           (select id from drivers where name = 'Max Verstappen'),         (select id from formula_one_teams where shortname = 'Red Bull'      and season = '2026'), 18 union all
    select  6,           (select id from drivers where name = 'Isack Hadjar'),           (select id from formula_one_teams where shortname = 'Red Bull'      and season = '2026'), 17 union all
    -- Mercedes (16, 15)
    select 63,           (select id from drivers where name = 'George Russell'),         (select id from formula_one_teams where shortname = 'Mercedes'      and season = '2026'), 16 union all
    select 12,           (select id from drivers where name = 'Andrea Kimi Antonelli'),  (select id from formula_one_teams where shortname = 'Mercedes'      and season = '2026'), 15 union all
    -- Alpine (14, 13)
    select 10,           (select id from drivers where name = 'Pierre Gasly'),           (select id from formula_one_teams where shortname = 'Alpine'        and season = '2026'), 14 union all
    select 43,           (select id from drivers where name = 'Franco Colapinto'),       (select id from formula_one_teams where shortname = 'Alpine'        and season = '2026'), 13 union all
    -- Haas (12, 11)
    select 31,           (select id from drivers where name = 'Esteban Ocon'),           (select id from formula_one_teams where shortname = 'Haas'          and season = '2026'), 12 union all
    select 87,           (select id from drivers where name = 'Oliver Bearman'),         (select id from formula_one_teams where shortname = 'Haas'          and season = '2026'), 11 union all
    -- Audi (10, 9)
    select 27,           (select id from drivers where name = 'Nico Hülkenberg'),        (select id from formula_one_teams where shortname = 'Audi'          and season = '2026'), 10 union all
    select  5,           (select id from drivers where name = 'Gabriel Bortoleto'),      (select id from formula_one_teams where shortname = 'Audi'          and season = '2026'),  9 union all
    -- Racing Bulls (8, 7)
    select 30,           (select id from drivers where name = 'Liam Lawson'),            (select id from formula_one_teams where shortname = 'Racing Bulls'  and season = '2026'),  8 union all
    select 41,           (select id from drivers where name = 'Arvid Lindblad'),         (select id from formula_one_teams where shortname = 'Racing Bulls'  and season = '2026'),  7 union all
    -- Williams (6, 5)
    select 23,           (select id from drivers where name = 'Alexander Albon'),        (select id from formula_one_teams where shortname = 'Williams'      and season = '2026'),  6 union all
    select 55,           (select id from drivers where name = 'Carlos Sainz Jr.'),       (select id from formula_one_teams where shortname = 'Williams'      and season = '2026'),  5 union all
    -- Cadillac (4, 3)
    select 11,           (select id from drivers where name = 'Sergio Pérez'),           (select id from formula_one_teams where shortname = 'Cadillac'      and season = '2026'),  4 union all
    select 77,           (select id from drivers where name = 'Valtteri Bottas'),        (select id from formula_one_teams where shortname = 'Cadillac'      and season = '2026'),  3 union all
    -- Aston Martin (2, 1)
    select 14,           (select id from drivers where name = 'Fernando Alonso'),        (select id from formula_one_teams where shortname = 'Aston Martin'  and season = '2026'),  2 union all
    select 18,           (select id from drivers where name = 'Lance Stroll'),           (select id from formula_one_teams where shortname = 'Aston Martin'  and season = '2026'),  1
) d
cross join formula_one_sessions s
where s.event in (
    select id from formula_one_events where season = '2026'
);
