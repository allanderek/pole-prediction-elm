-- Update to the 'Formula One 2026 run-in' over/under competition, 4 October 2026.
--
-- Resolves question 4 and records our current view of the other seven, so that the
-- leaderboard shows a running score rather than everybody tied. Data rather than
-- schema, kept here for the same reason as the file that created the competition,
-- sql/formula-one-2026-run-in-over-under.sql.
--
-- current_probability is the probability, 0 to 100, that the question's outcome is
-- TRUE, which for these questions means OVER. The server withholds it until the
-- competition's deadline has passed, which for this one was 5 September, so these
-- are visible as soon as they are set.
--
-- THE STATE OF THE SEASON. Sixteen races run, rounds 1 to 3 and 6 to 18, rounds 4
-- and 5 having been cancelled. Seven races left, rounds 19 to 25, with a single
-- sprint at Singapore.
--
--     Drivers       Antonelli 320, Russell 236, Hamilton 214, Leclerc 191,
--                   Verstappen 188, Norris 188, Piastri 128, Hadjar 96
--     Constructors  Mercedes 556, Ferrari 405, McLaren 316, Red Bull 298,
--                   Racing Bulls 90, Alpine 68, Haas 27, Audi 17, Williams 12,
--                   Aston Martin 7, Cadillac 0
--
-- HOW THE NUMBERS WERE ARRIVED AT. A Plackett-Luce race simulation, 20,000 run-ins
-- of the remaining seven races and the sprint, with per-weekend team performance
-- noise shared by team-mates and an 8% chance of retirement. Driver strengths were
-- calibrated so that simulated mean race points reproduce each driver's form,
-- taken as an even blend of the whole season and the last six weekends.
--
-- The simulation is used for questions 1, 2, 3, 5 and 6. It is NOT used for 7 and 8,
-- where it gave 67% and 31%. Calibrating on mean points says nothing useful about
-- rare events, and the model needs a floor on the weakest cars because nobody is
-- literally incapable of scoring, which hands Cadillac far more than the evidence
-- supports. Sixteen races of evidence beat the model there, so those two are set
-- from the observed record instead.

BEGIN TRANSACTION;

-- Question 4, Verstappen's Grand Prix wins over/under 0.5. He won the Bahrain Grand
-- Prix from pole on 4 October, round 18, run at Sepang. That is his first win and
-- first pole of 2026 and it settles the question OVER; a win cannot be taken back.
--
-- current_probability is deliberately left null rather than set to 100. Once outcome
-- is set the scoring uses it and ignores current_probability, so setting both would
-- only create a second place for the same fact to be wrong in.
update over_under_questions
set outcome = 1,
    -- Approximately when the race finished, the session having started at 07:00Z.
    resolved_at = '2026-10-04T09:00:00Z'
where competition = (select id from over_under_competitions where name = 'Formula One 2026 run-in')
  and text like 'Verstappen''s Grand Prix wins%'
;

-- The remaining seven. Matching on the text rather than on the id keeps this
-- readable and keeps it correct whatever ids the competition happened to get.
update over_under_questions
set current_probability = case
    -- Needs 11 in total, so 3 more from 7. He has won 8 of 16, but only 2 of the
    -- last 6: Norris took two, and Russell, Hamilton, Leclerc and Verstappen one
    -- each. The simulation implies a 41% win rate from here, between his 50% across
    -- the season and 33% over the recent stretch, giving 62%.
    when text like 'Antonelli''s Grand Prix wins%' then 60

    -- He leads by 84 with 183 still available to a driver, and the simulation puts
    -- the median final margin at 126. Getting under the line needs a collapse rather
    -- than a dip. The one thing holding it back from higher is that second place is
    -- the best of five bunched drivers, which pulls the margin down.
    when text like 'Points margin between first and second%' then 95

    -- Hamilton is 22 behind and in the slower car, and the gap is growing: 53 race
    -- points to Russell's 74 over the last six weekends.
    when text like 'Hamilton''s final points total minus Russell''s%' then 8

    -- They need 219 more to clear 774.5, which is 31.3 a weekend. They are managing
    -- 33.0 over the last six against 34.8 across the season, so they are on course by
    -- a margin thinner than the spread of outcomes. Genuinely close to a coin flip,
    -- and the closest of the eight to its line.
    when text like 'Mercedes'' final constructors%' then 62

    -- 22 clear, and extending: 4.2 points a weekend against Alpine's 2.7 over the
    -- last six. Alpine overturning it needs a podium while Racing Bulls blank.
    when text like 'Racing Bulls'' final constructors%' then 95

    -- No points at all in 16 races. Their best finish is 11th, and that happened
    -- once in 32 driver-races; they have been inside the top 13 only twice and are
    -- usually 18th to 22nd. A point needs an attrition race to come to them, and
    -- seven races give several chances of that, which is the whole of the 25%.
    when text like 'Cadillac''s points in 2026%' then 25

    -- Needs two names that have not been there yet, and that is harder than it
    -- sounds: the eight so far are exactly the eight drivers of the top four teams,
    -- so every new name must come from outside Mercedes, Ferrari, McLaren and Red
    -- Bull. No such driver has finished better than 5th all season, done twice, and
    -- none has reached a podium in 16 races. Two of them in seven races is a long way
    -- out on the tail.
    when text like 'Different drivers on the podium%' then 6

    else current_probability
end
where competition = (select id from over_under_competitions where name = 'Formula One 2026 run-in')
  and text not like 'Verstappen''s Grand Prix wins%'
;

COMMIT;
