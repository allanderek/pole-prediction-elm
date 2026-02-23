-- Add prediction_deadline to formula_one_seasons.
-- For past seasons (2024, 2025) we use the time of the first session.
-- For 2026 we use the hardcoded FP1 start time of the Australian GP.
ALTER TABLE formula_one_seasons ADD COLUMN prediction_deadline TEXT;

UPDATE formula_one_seasons
SET prediction_deadline = (
    SELECT MIN(s.start_time)
    FROM formula_one_sessions s
    JOIN formula_one_events e ON s.event = e.id
    WHERE e.season = formula_one_seasons.year
)
WHERE year IN ('2024', '2025');

UPDATE formula_one_seasons
SET prediction_deadline = '2026-03-06T01:30:00Z'
WHERE year = '2026';
