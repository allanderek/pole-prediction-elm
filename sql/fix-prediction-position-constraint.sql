-- Fix position check constraint to allow up to 22 positions (F1 2025+ has 22 drivers with Cadillac)
BEGIN TRANSACTION;

CREATE TABLE formula_one_prediction_lines_new (
    -- The user can be null, which represents a result
    user integer,
    session integer not null,
    fastest_lap integer,
    position integer check (position >= 1 and position <= 22),
    entrant integer not null,
    foreign key (entrant) references formula_one_entrants (id),
    foreign key (session) references formula_one_sessions (id),
    unique(user, session, position)
);

INSERT INTO formula_one_prediction_lines_new
    SELECT user, session, fastest_lap, position, entrant
    FROM formula_one_prediction_lines;

DROP TABLE formula_one_prediction_lines;

CREATE TABLE formula_one_prediction_lines (
    -- The user can be null, which represents a result
    user integer,
    session integer not null,
    fastest_lap integer,
    position integer check (position >= 1 and position <= 22),
    entrant integer not null,
    foreign key (entrant) references formula_one_entrants (id),
    foreign key (session) references formula_one_sessions (id),
    unique(user, session, position)
);

INSERT INTO formula_one_prediction_lines
    SELECT user, session, fastest_lap, position, entrant
    FROM formula_one_prediction_lines_new;

DROP TABLE formula_one_prediction_lines_new;

COMMIT;
