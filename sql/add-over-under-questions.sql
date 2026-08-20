-- Over/under questions.
--
-- A competition is a named set of binary questions with a single entry deadline.
-- The tables are deliberately sport-agnostic: the first competition will be the
-- English Premier League, but nothing here is football-specific.
--
-- 'Over/under' is just phrasing. Underneath, every question is a binary event, so
-- a question like 'Will Tottenham qualify for the UCL?' sits in the same table as
-- 'Will Haaland score over 24.5 goals?'. The numeric line, where there is one,
-- lives in the question text.
--
-- Answers are probabilities (0-100) that the outcome is 1, rather than a bare
-- over/under choice. If we decide against showing confidence in the UI, the
-- frontend can simply submit 0 or 100.
--
-- Unlike the Formula One and Formula E prediction tables, the actual answer is NOT
-- stored as a row with a null user. The outcome is boolean rather than a
-- probability, and questions resolve at different times, so the outcome and its
-- resolution time belong on the question itself.

BEGIN TRANSACTION;

create table over_under_competitions (
    id integer primary key autoincrement,
    -- e.g. 'English Premier League 2026-27'
    name text not null unique,
    -- Shown on the competition page.
    description text,
    prediction_deadline text
);

create table over_under_questions (
    id integer primary key autoincrement,
    competition integer not null,
    text text not null,
    -- The probability we currently consider correct, used to give users a running
    -- score before the question resolves. Null means no running score for this question.
    current_probability integer check (current_probability >= 0 and current_probability <= 100),
    -- Null until the question resolves; questions resolve at different times.
    outcome integer check (outcome in (0, 1)),
    resolved_at text,
    -- A voided question is excluded from scoring entirely, for the rare question
    -- that becomes unanswerable.
    voided integer not null default 0,
    foreign key (competition) references over_under_competitions (id)
);

-- One user's answer: their probability that the outcome is 1 (yes/over).
-- An unanswered question is an absent row, never a null probability.
create table over_under_answers (
    user integer not null,
    question integer not null,
    probability integer not null check (probability >= 0 and probability <= 100),
    foreign key (user) references users (id),
    foreign key (question) references over_under_questions (id),
    primary key (user, question)
);

-- The primary key covers lookups by user; scoring also groups by question.
create index idx_over_under_answers_question on over_under_answers (question);

COMMIT;

-- Scoring rule these tables imply:
--   skip the question if voided;
--   otherwise score against outcome if it is set;
--   otherwise score against current_probability if it is set;
--   otherwise the question does not contribute.
