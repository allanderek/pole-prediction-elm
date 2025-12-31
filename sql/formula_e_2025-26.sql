insert into seasons (year) values ('2025-26');

INSERT INTO races (round, name, country, circuit, date, season, cancelled) VALUES
  (1,  'São Paulo ePrix',   'Brazil',        'São Paulo Street Circuit',          '2025-12-06T12:40:00Z', '2025-26', 0),
  (2,  'Mexico City ePrix','Mexico',        'Autódromo Hermanos Rodríguez',       '2026-01-10T00:00:00Z', '2025-26', 0),
  (3,  'Miami ePrix',      'United States', 'Miami International Autodrome',      '2026-01-31T00:00:00Z', '2025-26', 0),
  (4,  'Jeddah ePrix',     'Saudi Arabia',  'Jeddah Corniche Circuit',            '2026-02-13T00:00:00Z', '2025-26', 0),
  (5,  'Jeddah ePrix',     'Saudi Arabia',  'Jeddah Corniche Circuit',            '2026-02-14T00:00:00Z', '2025-26', 0),
  (6,  'Madrid ePrix',     'Spain',         'Circuito del Jarama',                '2026-03-21T00:00:00Z', '2025-26', 0),
  (7,  'Berlin ePrix',     'Germany',       'Tempelhof Airport Street Circuit',   '2026-05-02T00:00:00Z', '2025-26', 0),
  (8,  'Berlin ePrix',     'Germany',       'Tempelhof Airport Street Circuit',   '2026-05-03T00:00:00Z', '2025-26', 0),
  (9,  'Monaco ePrix',     'Monaco',        'Circuit de Monaco',                  '2026-05-16T00:00:00Z', '2025-26', 0),
  (10, 'Monaco ePrix',     'Monaco',        'Circuit de Monaco',                  '2026-05-17T00:00:00Z', '2025-26', 0),
  (11, 'Sanya ePrix',      'China',         'TBC',                                '2026-06-20T00:00:00Z', '2025-26', 0),
  (12, 'Shanghai ePrix',   'China',         'Shanghai International Circuit',     '2026-07-04T00:00:00Z', '2025-26', 0),
  (13, 'Shanghai ePrix',   'China',         'Shanghai International Circuit',     '2026-07-05T00:00:00Z', '2025-26', 0),
  (14, 'Tokyo ePrix',      'Japan',         'Tokyo Street Circuit',               '2026-07-25T00:00:00Z', '2025-26', 0),
  (15, 'Tokyo ePrix',      'Japan',         'Tokyo Street Circuit',               '2026-07-26T00:00:00Z', '2025-26', 0),
  (16, 'London ePrix',     'United Kingdom','ExCeL London Circuit',               '2026-08-15T00:00:00Z', '2025-26', 0),
  (17, 'London ePrix',     'United Kingdom','ExCeL London Circuit',               '2026-08-16T00:00:00Z', '2025-26', 0)
  ;

insert into drivers (name) values
    ('Pepe Martí')
    ;

insert into constructors (name) values
    ('Citroën')
    ;

insert into teams (season, constructor, fullname, shortname, color) values
    ('2025-26',11, 'Andretti Formula E', 'Andretti', '#ed3124'),
    ('2025-26',(select id from constructors where name = 'Citroën'), 'Citroën Racing', 'Citroën', '#eb002a'),
    ('2025-26',12, 'Cupra Kiro', 'Cupra Kiro', '#000000'),
    ('2025-26',1, 'DS Penske', 'DS Penske', '#cba65f'),
    ('2025-26',9, 'Envision Racing', 'Envision', '#00c900'),
    ('2025-26',7, 'Jaguar TCS Racing', 'Jaguar', '#000000'),
    ('2025-26',13, 'Lola Yamaha ABT Formula E Team', 'Lola', '#0033a0'),
    ('2025-26',6, 'Mahindra Racing', 'Mahindra', '#e31837'),
    ('2025-26',10, 'Nissan Formula E Team', 'Nissan', '#c3002f'),
    ('2025-26',8, 'Porcshe Formula E Team', 'Porsche', '#000000')
    ;

insert into entrants (number, driver, team, race)
select 
    driver_team.number,
    (select id from drivers where name = driver_team.driver_name),
    (select id from teams where season = '2025-26' and shortname = driver_team.team_shortname),
    races.id
from (
    select 1 as number, 'Oliver Rowland' as driver_name, 'Nissan' as team_shortname
    union all select 23, 'Norman Nato', 'Nissan'
    union all select 3, 'Pepe Martí', 'Cupra Kiro'
    union all select 33, 'Dan Ticktum', 'Cupra Kiro'
    union all select 7, 'Maximilian Günther', 'DS Penske'
    union all select 77, 'Taylor Barnard', 'DS Penske'
    union all select 9, 'Mitch Evans', 'Jaguar'
    union all select 13, 'António Félix da Costa', 'Jaguar'
    union all select 11, 'Lucas di Grassi', 'Lola'
    union all select 22, 'Zane Maloney', 'Lola'
    union all select 14, 'Joel Eriksson', 'Envision'
    union all select 16, 'Sébastien Buemi', 'Envision'
    union all select 21, 'Nyck de Vries', 'Mahindra'
    union all select 48, 'Edoardo Mortara', 'Mahindra'
    union all select 25, 'Jean-Éric Vergne', 'Citroën'
    union all select 37, 'Nick Cassidy', 'Citroën'
    union all select 27, 'Jake Dennis', 'Andretti'
    union all select 28, 'Felipe Drugovich', 'Andretti'
    union all select 51, 'Nico Müller', 'Porsche'
    union all select 94, 'Pascal Wehrlein', 'Porsche'
) as driver_team
cross join races
where races.season = '2025-26'
;

-- For predictions table
alter table predictions add column sam integer references entrants(id);
alter table predictions add column hst integer references teams(id);

-- For results table  
alter table results add column sam integer references entrants(id);
alter table results add column hst integer references teams(id);
