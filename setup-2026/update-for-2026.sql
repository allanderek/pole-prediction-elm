-- Add the 2026 season
INSERT INTO formula_one_seasons (year) VALUES ('2026');

-- Rename constructor: Citroën -> Cadillac
UPDATE constructors SET name = 'Cadillac' WHERE id = 11;

-- New driver not previously in the database
INSERT INTO drivers (name) VALUES ('Arvid Lindblad');

-- 2026 teams
INSERT INTO formula_one_teams (fullname, shortname, constructor, season)
VALUES
    ('Oracle Red Bull Racing',           'Red Bull',     1,  '2026'),
    ('Alpine Racing Limited',            'Alpine',       2,  '2026'),
    ('AMR GP Limited',                   'Aston Martin', 3,  '2026'),
    ('Ferrari S.p.A.',                   'Ferrari',      4,  '2026'),
    ('Haas Formula LLC',                 'Haas',         5,  '2026'),
    ('Sauber Motorsport AG',             'Audi',         6,  '2026'),
    ('McLaren Racing Limited',           'McLaren',      7,  '2026'),
    ('Mercedes-Benz Grand Prix Limited', 'Mercedes',     8,  '2026'),
    ('Racing Bulls S.p.A.',              'Racing Bulls', 9,  '2026'),
    ('Atlassian Williams Racing',        'Williams',     10, '2026'),
    ('TWG Cadillac Formula 1 Team LLC',  'Cadillac',     11, '2026')
;
