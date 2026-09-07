-- The third over/under competition: the 2026-27 Champions League league phase.
--
-- Data rather than schema, kept here for the same reason as premier-league-2026-27-over-under.sql,
-- so that what went into the database is recorded and repeatable.
--
-- The deadline must be RFC3339, with the T and the Z, as in 2026-09-08T16:45:00Z.
-- SQLite's own '2026-09-08 16:45:00' format is not parsed by the front end, and a
-- deadline it cannot read fails the whole page rather than just that one field.
--
-- Scope is the league phase only, so every question resolves together after matchday 8
-- on 27 January 2027. The knockout phase gets its own competition rather than leaving
-- this one hanging until the final in late May.
--
-- Format: 36 clubs, eight single-leg matches each, one table. The top eight go straight
-- to the round of 16, ninth to 24th go to a two-legged play-off, and 25th to 36th are
-- out of Europe altogether.
--
-- Every line ends in .5, so no question can be hit exactly and none can need voiding.
--
-- The two previous seasons under this format are the base rates throughout:
--
--                          2024-25   2025-26
--     Goals in 144 matches      470       440
--     Points, 8th                16        16
--     Points, 24th               11         9
--     Points, 1st                21        24
--
-- The draw was made in Monaco on 27 August 2026. Pot 1 was Paris, Bayern, Real Madrid,
-- Liverpool, Inter, Man City, Arsenal, Barcelona, Atleti; pot 2 was Dortmund, Roma,
-- Sporting CP, Aston Villa, Porto, Man Utd, Club Brugge, Real Betis, PSV. So three of
-- the five English clubs are pot 1 and two are pot 2, though pot 1 guarantees nothing:
-- in 2024-25 its nine clubs finished 1st, 2nd, 4th, 10th, 11th, 12th, 15th, 22nd and
-- 36th, Leipzig having lost all eight.

BEGIN TRANSACTION;

insert into over_under_competitions (name, description, prediction_deadline) values (
    'Champions League 2026-27 league phase',
    'Ten over/under questions on the league phase of the 2026-27 Champions League. All ten resolve after the final matchday on 27 January 2027. Answer each one over or under before the first match kicks off.',
    -- Matchday 1 runs from 8 to 10 September 2026. This is UEFA's earlier kick-off slot
    -- on the Tuesday, 18:45 CEST, which is UTC+2 in September. If the first match is
    -- actually in the later slot then entry closes early, which is the safe direction.
    '2026-09-08T16:45:00Z'
);

-- The ordinal is not stored, it only fixes the insertion order. Rows come back from
-- a union all in no guaranteed order, and here the order decides the ids, which decide
-- the Q1..Q10 labels and the leaderboard columns, so it must not be left to chance.
insert into over_under_questions (competition, text)
select
    (select id from over_under_competitions where name = 'Champions League 2026-27 league phase'),
    text
from (
    -- Questions 1 to 5 are the five English clubs, one line each, ordered by their line
    -- rather than by club. Positions run 1 to 36, so under is the good end. The lines are
    -- set from pot seeding, the last two league phases, and the opening three Premier
    -- League weekends of 2026-27.
    --
    -- Arsenal topped the league phase last season with a perfect eight, lost the final
    -- on penalties, and have started this season with nine points from nine.
    select 1 as ordinal, 'Arsenal''s league-phase finishing position — over/under 4.5' as text
    -- The volatile one: 8th last season, 22nd the season before, but nine from nine now.
    union all select 2, 'Manchester City''s league-phase finishing position — over/under 8.5'
    -- 1st in 2024-25 and 3rd in 2025-26, but only five points from nine so far and
    -- visibly still adjusting. A place adrift of City rather than level with them.
    union all select 3, 'Liverpool''s league-phase finishing position — over/under 9.5'
    -- Back after an absence. Four points from nine, and nothing convincing in them yet.
    union all select 4, 'Manchester United''s league-phase finishing position — over/under 16.5'
    -- 8th in 2024-25, but one point from nine this season and five of the Europa League
    -- final starting eleven sold over the summer. Pot 2 by seeding, weaker than that now.
    union all select 5, 'Aston Villa''s league-phase finishing position — over/under 20.5'
    -- The automatic-qualification cut, 16 points in both previous seasons.
    union all select 6, 'Points of the team finishing eighth — over/under 15.5'
    -- The survival cut: 11 points in 2024-25, 9 in 2025-26.
    union all select 7, 'Points of the team finishing 24th — over/under 9.5'
    -- 470 goals then 440, so the line sits exactly between the only two data points.
    union all select 8, 'Total goals in the 144 league-phase matches — over/under 454.5'
    -- Nine of the 36 have won the Champions League since 2000, and resolution should be
    -- against exactly this list: Paris (2025, 2026), Real Madrid (2000, 2002, 2014,
    -- 2016, 2017, 2018, 2022, 2024), Barcelona (2006, 2009, 2011, 2015), Bayern (2001,
    -- 2013, 2020), Liverpool (2005, 2019), Inter (2010), Man City (2023), Man Utd (2008)
    -- and Porto (2004). Note that Dortmund (1997), Aston Villa (1982), PSV (1988) and
    -- Feyenoord (1970) won the European Cup but not this century, and do not count. The
    -- list survives the pedantic reading in which the century began in 2001, because
    -- Real Madrid won seven more after 2000. The top eight held three such clubs in
    -- 2024-25 and five in 2025-26.
    union all select 9, 'Clubs in the top eight that have won the Champions League this century — over/under 4.5'
    -- Six in 2024-25 (PSV, Benfica, Feyenoord, Celtic, Sporting, Club Brugge) and seven
    -- in 2025-26 (Sporting, Olympiacos, Club Brugge, Galatasaray, Qarabağ, Bodø/Glimt,
    -- Benfica). Fifteen of the 36 are from outside the big five this season, up from
    -- about thirteen, but the top of that group is thinner: of last season's seven only
    -- Sporting, Club Brugge, Galatasaray and Bodø/Glimt return, with Benfica absent
    -- having made the top 24 in both seasons. Porto, PSV and Feyenoord come the other
    -- way. That leaves roughly eight credible candidates and seven long shots, so the
    -- line is one below the base rate rather than one above it.
    union all select 10, 'Clubs from outside the big-five leagues (England, France, Germany, Italy, Spain) finishing in the top 24 — over/under 5.5'
) as questions
order by ordinal
;

COMMIT;
