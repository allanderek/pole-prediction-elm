-- The original position constraint capped at 10, but with 11 teams in 2026 that is too restrictive.
-- Remove the upper bound so the constraint is just position >= 1.
--
-- Note: We cannot use ALTER TABLE ... RENAME TO here because SQLite re-parses the entire schema
-- on rename, and another table ('predictions') uses double-quoted string literals in its check
-- constraint which confuses the re-parser. Instead we use a copy-drop-create-copy pattern.
BEGIN TRANSACTION;

CREATE TABLE formula_one_season_prediction_lines_new (
    user integer not null,
    season text not null,
    position integer check (position >= 1),
    team integer not null,
    foreign key (user) references users (id),
    foreign key (season) references formula_one_seasons (year),
    foreign key (team) references formula_one_teams (id),
    unique(user, season, position)
);

INSERT INTO formula_one_season_prediction_lines_new
    SELECT * FROM formula_one_season_prediction_lines;

DROP TABLE formula_one_season_prediction_lines;

CREATE TABLE formula_one_season_prediction_lines (
    user integer not null,
    season text not null,
    position integer check (position >= 1),
    team integer not null,
    foreign key (user) references users (id),
    foreign key (season) references formula_one_seasons (year),
    foreign key (team) references formula_one_teams (id),
    unique(user, season, position)
);

INSERT INTO formula_one_season_prediction_lines
    SELECT * FROM formula_one_season_prediction_lines_new;

DROP TABLE formula_one_season_prediction_lines_new;

COMMIT;
