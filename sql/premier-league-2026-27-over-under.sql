-- The first over/under competition: the 2026-27 Premier League season.
--
-- Data rather than schema, kept here for the same reason as formula_e_2025-26.sql,
-- so that what went into the database is recorded and repeatable.
--
-- The deadline must be RFC3339, with the T and the Z, as in 2026-08-14T18:00:00Z.
-- SQLite's own '2026-08-14 18:00:00' format is not parsed by the front end, and a
-- deadline it cannot read fails the whole page rather than just that one field.
--
-- Question 12's line is a round number, so unlike the others it can be hit exactly.
-- If net spend comes in at precisely £400m the question has no true answer, and it
-- should be voided rather than resolved:
--     update over_under_questions set voided = 1 where id = <id>;
-- A voided question is left out of scoring altogether and loses its leaderboard
-- column, so nobody's total is affected.

BEGIN TRANSACTION;

insert into over_under_competitions (name, description, prediction_deadline) values (
    'Premier League 2026-27',
    'Twelve over/under questions on the 2026-27 Premier League season. Answer each one over or under before the season starts.',
    -- The first match of the season, 8pm on 21 August 2026. That is BST, which is
    -- UTC+1 in August, so 19:00 UTC.
    '2026-08-21T19:00:00Z'
);

-- The ordinal is not stored, it only fixes the insertion order. Rows come back from
-- a union all in no guaranteed order, and here the order decides the ids, which decide
-- the Q1..Q12 labels and the leaderboard columns, so it must not be left to chance.
insert into over_under_questions (competition, text)
select
    (select id from over_under_competitions where name = 'Premier League 2026-27'),
    text
from (
    select 1 as ordinal, 'Promoted teams relegated — over/under 0.5' as text
    union all select 2, 'Greedy six in the top six — over/under 4.5'
    union all select 3, 'Highest relegated points total — over/under 33.5'
    union all select 4, 'Champions'' final points total — over/under 84.5'
    union all select 5, 'Total goals in the 380 matches — over/under 1,090.5'
    union all select 6, 'Golden Boot winner''s goals — over/under 26.5'
    union all select 7, 'Points of the team finishing 4th — over/under 70.5'
    union all select 8, 'Permanent managerial departures during the season — over/under 8.5'
    union all select 9, 'Days from the opening match to the first permanent manager leaving — over/under 52.5'
    union all select 10, 'Golden Glove winner''s clean sheets — over/under 14.5'
    union all select 11, 'Combined points of the three promoted clubs — over/under 88.5'
    union all select 12, 'Net spend across the January window — over/under £400m'
) as questions
order by ordinal
;

COMMIT;
