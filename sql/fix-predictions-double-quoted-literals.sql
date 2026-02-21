-- The 'predictions' table has double-quoted string literals in its check constraint:
--     safety_car text check (safety_car in ("yes", "no")) not null
-- In SQL, double quotes are for identifiers, not strings. Single quotes should be used.
-- SQLite accepts double-quoted strings as a non-standard fallback, but the schema
-- stored on disk contains the double-quoted form. When any ALTER TABLE ... RENAME TO
-- is executed elsewhere, SQLite re-parses all stored schema SQL and chokes on these.
-- This migration recreates the table with correct single-quoted string literals.
--
-- Note: We cannot use ALTER TABLE ... RENAME TO in this migration either (same problem),
-- so we use the copy-drop-create-copy pattern.
BEGIN TRANSACTION;

CREATE TABLE predictions_new (
    user integer not null,
    race integer not null,
    pole integer not null,
    fam  integer not null,
    fl   integer not null,
    hgc  integer not null,
    first integer not null,
    second integer not null,
    third integer not null,
    fdnf integer not null,
    safety_car text check (safety_car in ('yes', 'no', '')) not null,
    sam integer references entrants(id),
    hst integer references teams(id),
    foreign key (user) references users(id),
    foreign key (race) references races(id),
    foreign key (pole) references entrants(id),
    foreign key (fam) references entrants(id),
    foreign key (fl) references entrants(id),
    foreign key (hgc) references entrants(id),
    foreign key (first) references entrants(id),
    foreign key (second) references entrants(id),
    foreign key (third) references entrants(id),
    foreign key (fdnf) references entrants(id),
    primary key (user, race)
);

INSERT INTO predictions_new SELECT * FROM predictions;

DROP TABLE predictions;

CREATE TABLE predictions (
    user integer not null,
    race integer not null,
    pole integer not null,
    fam  integer not null,
    fl   integer not null,
    hgc  integer not null,
    first integer not null,
    second integer not null,
    third integer not null,
    fdnf integer not null,
    safety_car text check (safety_car in ('yes', 'no', '')) not null,
    sam integer references entrants(id),
    hst integer references teams(id),
    foreign key (user) references users(id),
    foreign key (race) references races(id),
    foreign key (pole) references entrants(id),
    foreign key (fam) references entrants(id),
    foreign key (fl) references entrants(id),
    foreign key (hgc) references entrants(id),
    foreign key (first) references entrants(id),
    foreign key (second) references entrants(id),
    foreign key (third) references entrants(id),
    foreign key (fdnf) references entrants(id),
    primary key (user, race)
);

INSERT INTO predictions SELECT * FROM predictions_new;

DROP TABLE predictions_new;

COMMIT;
