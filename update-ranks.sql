-- Update entrant ranks for all future sessions based on current WDC standings.
-- "Future" means sessions with no results entered yet.
-- Run via: make update-ranks

WITH
    current_season AS (
        SELECT MAX(year) AS year FROM formula_one_seasons
    ),
    completed_sessions AS (
        SELECT DISTINCT session
        FROM formula_one_prediction_lines
        WHERE user IS NULL OR user = ''
    ),
    results AS (
        SELECT pl.*
        FROM formula_one_prediction_lines pl
        INNER JOIN completed_sessions cs ON pl.session = cs.session
        WHERE pl.user IS NULL OR pl.user = ''
    ),
    scored_lines AS (
        SELECT
            CASE
                WHEN sessions.name = 'race' THEN
                    CASE
                        WHEN results.position = 1 THEN 25
                        WHEN results.position = 2 THEN 18
                        WHEN results.position = 3 THEN 15
                        WHEN results.position = 4 THEN 12
                        WHEN results.position = 5 THEN 10
                        WHEN results.position = 6 THEN 8
                        WHEN results.position = 7 THEN 6
                        WHEN results.position = 8 THEN 4
                        WHEN results.position = 9 THEN 2
                        WHEN results.position = 10 THEN 1
                        ELSE 0
                    END
                WHEN sessions.name = 'sprint' THEN
                    CASE
                        WHEN results.position = 1 THEN 8
                        WHEN results.position = 2 THEN 7
                        WHEN results.position = 3 THEN 6
                        WHEN results.position = 4 THEN 5
                        WHEN results.position = 5 THEN 4
                        WHEN results.position = 6 THEN 3
                        WHEN results.position = 7 THEN 2
                        WHEN results.position = 8 THEN 1
                        ELSE 0
                    END
                ELSE 0
            END
            + CASE WHEN results.fastest_lap = 'true' AND sessions.fastest_lap = 1 THEN 1 ELSE 0 END
            AS score,
            drivers.id AS driver_id
        FROM results
        INNER JOIN formula_one_sessions AS sessions ON results.session = sessions.id
        INNER JOIN formula_one_events AS events ON sessions.event = events.id
        INNER JOIN current_season ON events.season = current_season.year
        INNER JOIN formula_one_entrants AS entrants ON results.entrant = entrants.id
        INNER JOIN drivers ON entrants.driver = drivers.id
    ),
    standings AS (
        SELECT driver_id, SUM(score) AS total
        FROM scored_lines
        GROUP BY driver_id
    ),
    new_ranks AS (
        SELECT
            driver_id,
            (SELECT COUNT(*) FROM standings) + 1 - ROW_NUMBER() OVER (ORDER BY total DESC) AS new_rank
        FROM standings
    ),
    future_sessions AS (
        SELECT s.id
        FROM formula_one_sessions s
        INNER JOIN formula_one_events e ON e.id = s.event
        INNER JOIN current_season ON e.season = current_season.year
        WHERE s.id NOT IN (SELECT session FROM completed_sessions)
    )
UPDATE formula_one_entrants
SET rank = (SELECT new_rank FROM new_ranks WHERE new_ranks.driver_id = formula_one_entrants.driver)
WHERE session IN (SELECT id FROM future_sessions)
AND driver IN (SELECT driver_id FROM new_ranks);
