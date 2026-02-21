-- SQL Statements
insert into formula_one_events
            (round, name, season)
            values
            (1, 'Australian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-03-08T04:00:00Z', (select id from formula_one_events where name = 'Australian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-03-07T05:00:00Z', (select id from formula_one_events where name = 'Australian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (2, 'Chinese Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-03-15T07:00:00Z', (select id from formula_one_events where name = 'Chinese Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-03-14T07:00:00Z', (select id from formula_one_events where name = 'Chinese Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-03-14T03:00:00Z', (select id from formula_one_events where name = 'Chinese Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-03-13T07:30:00Z', (select id from formula_one_events where name = 'Chinese Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (3, 'Japanese Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-03-29T05:00:00Z', (select id from formula_one_events where name = 'Japanese Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-03-28T06:00:00Z', (select id from formula_one_events where name = 'Japanese Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (4, 'Bahrain Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-04-12T15:00:00Z', (select id from formula_one_events where name = 'Bahrain Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-04-11T16:00:00Z', (select id from formula_one_events where name = 'Bahrain Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (5, 'Saudi Arabian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-04-19T17:00:00Z', (select id from formula_one_events where name = 'Saudi Arabian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-04-18T17:00:00Z', (select id from formula_one_events where name = 'Saudi Arabian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (6, 'Miami Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-05-03T20:00:00Z', (select id from formula_one_events where name = 'Miami Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-05-02T20:00:00Z', (select id from formula_one_events where name = 'Miami Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-05-02T16:00:00Z', (select id from formula_one_events where name = 'Miami Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-05-01T20:30:00Z', (select id from formula_one_events where name = 'Miami Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (7, 'Canadian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-05-24T20:00:00Z', (select id from formula_one_events where name = 'Canadian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-05-23T20:00:00Z', (select id from formula_one_events where name = 'Canadian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-05-23T16:00:00Z', (select id from formula_one_events where name = 'Canadian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-05-22T20:30:00Z', (select id from formula_one_events where name = 'Canadian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (8, 'Monaco Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-06-07T13:00:00Z', (select id from formula_one_events where name = 'Monaco Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-06-06T14:00:00Z', (select id from formula_one_events where name = 'Monaco Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (9, 'Barcelona Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-06-14T13:00:00Z', (select id from formula_one_events where name = 'Barcelona Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-06-13T14:00:00Z', (select id from formula_one_events where name = 'Barcelona Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (10, 'Austrian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-06-28T13:00:00Z', (select id from formula_one_events where name = 'Austrian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-06-27T14:00:00Z', (select id from formula_one_events where name = 'Austrian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (11, 'British Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-07-05T14:00:00Z', (select id from formula_one_events where name = 'British Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-07-04T15:00:00Z', (select id from formula_one_events where name = 'British Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-07-04T11:00:00Z', (select id from formula_one_events where name = 'British Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-07-03T15:30:00Z', (select id from formula_one_events where name = 'British Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (12, 'Belgian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-07-19T13:00:00Z', (select id from formula_one_events where name = 'Belgian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-07-18T14:00:00Z', (select id from formula_one_events where name = 'Belgian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (13, 'Hungarian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-07-26T13:00:00Z', (select id from formula_one_events where name = 'Hungarian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-07-25T14:00:00Z', (select id from formula_one_events where name = 'Hungarian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (14, 'Dutch Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-08-23T13:00:00Z', (select id from formula_one_events where name = 'Dutch Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-08-22T14:00:00Z', (select id from formula_one_events where name = 'Dutch Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-08-22T10:00:00Z', (select id from formula_one_events where name = 'Dutch Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-08-21T14:30:00Z', (select id from formula_one_events where name = 'Dutch Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (15, 'Italian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-09-06T13:00:00Z', (select id from formula_one_events where name = 'Italian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-09-05T14:00:00Z', (select id from formula_one_events where name = 'Italian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (16, 'Spanish Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-09-13T13:00:00Z', (select id from formula_one_events where name = 'Spanish Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-09-12T14:00:00Z', (select id from formula_one_events where name = 'Spanish Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (17, 'Azerbaijan Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-09-26T11:00:00Z', (select id from formula_one_events where name = 'Azerbaijan Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-09-25T12:00:00Z', (select id from formula_one_events where name = 'Azerbaijan Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (18, 'Singapore Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-10-11T12:00:00Z', (select id from formula_one_events where name = 'Singapore Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-10-10T13:00:00Z', (select id from formula_one_events where name = 'Singapore Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint', '2026-10-10T09:00:00Z', (select id from formula_one_events where name = 'Singapore Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('sprint-shootout', '2026-10-09T12:30:00Z', (select id from formula_one_events where name = 'Singapore Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (19, 'United States Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-10-25T20:00:00Z', (select id from formula_one_events where name = 'United States Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-10-24T21:00:00Z', (select id from formula_one_events where name = 'United States Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (20, 'Mexico City Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-11-01T20:00:00Z', (select id from formula_one_events where name = 'Mexico City Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-10-31T21:00:00Z', (select id from formula_one_events where name = 'Mexico City Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (21, 'Brazilian Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-11-08T17:00:00Z', (select id from formula_one_events where name = 'Brazilian Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-11-07T18:00:00Z', (select id from formula_one_events where name = 'Brazilian Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (22, 'Las Vegas Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-11-22T04:00:00Z', (select id from formula_one_events where name = 'Las Vegas Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-11-21T04:00:00Z', (select id from formula_one_events where name = 'Las Vegas Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (23, 'Qatar Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-11-29T16:00:00Z', (select id from formula_one_events where name = 'Qatar Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-11-28T18:00:00Z', (select id from formula_one_events where name = 'Qatar Grand Prix' and season = '2026'));
insert into formula_one_events
            (round, name, season)
            values
            (24, 'Abu Dhabi Grand Prix', '2026');
insert into formula_one_sessions
            (name, start_time, event)
            values
            ('race', '2026-12-06T13:00:00Z', (select id from formula_one_events where name = 'Abu Dhabi Grand Prix' and season = '2026'));
insert into formula_one_sessions
                (name, start_time, event)
                values
                ('qualifying', '2026-12-05T14:00:00Z', (select id from formula_one_events where name = 'Abu Dhabi Grand Prix' and season = '2026'));
