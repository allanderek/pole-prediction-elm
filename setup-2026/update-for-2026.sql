-- Add the 2026 season
INSERT INTO formula_one_seasons (year) VALUES ('2026');

-- Rename constructor: Citroën -> Cadillac
UPDATE constructors SET name = 'Cadillac' WHERE id = 11;

-- New driver not previously in the database
INSERT INTO drivers (name) VALUES ('Arvid Lindblad');

-- 2026 teams
INSERT INTO formula_one_teams (fullname, shortname, constructor, season, color, secondary_color)
VALUES
    ('Oracle Red Bull Racing',           'Red Bull',     1,  '2026', '#3671c6', '#1b3963'),
    ('Alpine Racing Limited',            'Alpine',       2,  '2026', '#ff69b4', '#0055a4'),
    ('AMR GP Limited',                   'Aston Martin', 3,  '2026', '#006c66', '#dfff00'),
    ('Ferrari S.p.A.',                   'Ferrari',      4,  '2026', '#dc0000', '#dc0000'),
    ('Haas Formula LLC',                 'Haas',         5,  '2026', '#000000', '#e10600'),
    ('Sauber Motorsport AG',             'Audi',         6,  '2026', '#86807d', '#9b1c00'),
    ('McLaren Racing Limited',           'McLaren',      7,  '2026', '#ff8700', '#0055ff'),
    ('Mercedes-Benz Grand Prix Limited', 'Mercedes',     8,  '2026', '#000000', '#27f4d2'),
    ('Racing Bulls S.p.A.',              'Racing Bulls', 9,  '2026', '#285cda', '#ff0000'),
    ('Atlassian Williams Racing',        'Williams',     10, '2026', '#041e42', '#00a3e0'),
    ('TWG Cadillac Formula 1 Team LLC',  'Cadillac',     11, '2026', '#030e28', '#6d6d70')
;
