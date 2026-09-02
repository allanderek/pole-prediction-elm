-- The second over/under competition: the closing stretch of the 2026 Formula One season.
--
-- Data rather than schema, kept here for the same reason as premier-league-2026-27-over-under.sql,
-- so that what went into the database is recorded and repeatable.
--
-- The deadline must be RFC3339, with the T and the Z, as in 2026-09-05T14:00:00Z.
-- SQLite's own '2026-09-05 14:00:00' format is not parsed by the front end, and a
-- deadline it cannot read fails the whole page rather than just that one field.
--
-- Every line ends in .5, so no question can be hit exactly and none can need voiding.
-- The lines were set from the twelve races run before the deadline:
--
--     Drivers      Antonelli 242 (6 wins, 10 podiums, 6 poles), Russell 183 (2 wins),
--                  Hamilton 183 (1 win), Norris 159 (2 wins), Leclerc 155 (1 win),
--                  Verstappen 112 (no wins), Piastri 104
--     Constructors Mercedes 425, Ferrari 338, McLaren 263, Red Bull 186,
--                  Racing Bulls 66, Alpine 63, Haas 21, Audi 16, Williams 11,
--                  Aston Martin 3, Cadillac 0
--
-- Ten races remain, rounds 15 to 24, with a single sprint at Singapore. Rounds 4 and
-- 5 were cancelled, so 258 points are still available to a driver rather than 258 from
-- a full twelve-round run-in.

BEGIN TRANSACTION;

insert into over_under_competitions (name, description, prediction_deadline) values (
    'Formula One 2026 run-in',
    'Eight over/under questions on the closing stretch of the 2026 Formula One season. Ten races remain, starting at Monza. Answer each one over or under before qualifying begins.',
    -- Monza qualifying, 3pm on 5 September 2026. That is CEST, which is UTC+2 in
    -- September, so 14:00 UTC. It matches the start_time already on that session.
    '2026-09-05T14:00:00Z'
);

-- The ordinal is not stored, it only fixes the insertion order. Rows come back from
-- a union all in no guaranteed order, and here the order decides the ids, which decide
-- the Q1..Q8 labels and the leaderboard columns, so it must not be left to chance.
insert into over_under_questions (competition, text)
select
    (select id from over_under_competitions where name = 'Formula One 2026 run-in'),
    text
from (
    -- Six wins from twelve is exactly a 50% strike rate, so 10.5 asks whether he can
    -- hold it: five of the last ten go over, four go under.
    select 1 as ordinal, 'Antonelli''s Grand Prix wins in 2026 — over/under 10.5' as text
    -- The margin, not Antonelli's margin, so the question still resolves if somebody
    -- else wins the title. It stands at 59 with ten races to run.
    union all select 2, 'Points margin between first and second in the final drivers'' championship — over/under 59.5'
    -- Level on 183 apiece. Phrased as a difference rather than as who finishes above
    -- whom, which makes it a number the results settle on their own. Note that the
    -- difference is an integer, so 0.5 can never be hit, and that a dead tie is under
    -- rather than going to countback.
    union all select 3, 'Hamilton''s final points total minus Russell''s — over/under 0.5'
    -- Winless from twelve but with four podiums. His first winless season since 2019
    -- if it stays that way.
    union all select 4, 'Verstappen''s Grand Prix wins in 2026 — over/under 0.5'
    -- 425 from twelve weekends is 35.4 a weekend, which over ten more projects to 779.
    union all select 5, 'Mercedes'' final constructors'' championship points — over/under 774.5'
    -- Three points apart, and a difference for the same reason as question 3.
    union all select 6, 'Racing Bulls'' final constructors'' points minus Alpine''s — over/under 0.5'
    -- Perez and Bottas have yet to score for the new team.
    union all select 7, 'Cadillac''s points in 2026 — over/under 0.5'
    -- Eight so far: Antonelli, Russell, Hamilton, Norris, Leclerc, Verstappen, Piastri
    -- and Gasly. Over needs two names that have not been there yet.
    union all select 8, 'Different drivers on the podium in 2026 — over/under 9.5'
) as questions
order by ordinal
;

COMMIT;
