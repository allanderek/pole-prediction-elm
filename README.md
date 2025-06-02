# Development

To create the virtual environment run:
$ python3 -m venv venv
$ source venv/bin/activate.fish 
$ pip install -r requirements.txt

If already created you only need the middle line:
$ source venv/bin/activate.fish 


## TODOS:

- [ ] Am I vulnerable to SQL-injection? See for example getting the leaderboard we just pass in the season.
- [x] Fix the damn problem with devenv/direnv reloading
- [x] Make a watcher for the front-end at least, and possibly the backend.
- [ ] Decide what to do about non-participating entrants, either download them but deal with them on the front-end, or filter them out in the SQL query.
- [ ] Learn about workers and whether I need those to keep the data up to date.


- [ ] Consider a bit of a refactor of the database, we could have that the entrants all have ids 1-20, but the primary key of the entrant is a composite primary key consisting of session id with the entrant id. This would have some advantages. Such as creating all the entrants in the database at the start of the season. Changing one should really be changing either a driver for a replacement (e.g. Bearman for Sainz due to appendecitis), or swapping teams, e.g. Tsunoda for Lawson and vice versa. 


- [ ] You have authentication but no way to register at the moment.
- [ ] I may do 'event' leaderboard which is just get the leaderboard for the season but restrict it to sessions within a given event, and show it on the event page?
- [ ] Can I do something cool with testing, i.e. run elm test by actually using the database from python?
- [ ] Don't forget that before next year you will have to do season prediction input.
- [ ] There is some duplication in the constructor standings and the season leaderboard, precisely to calculate the constructor standings. I should be able to factor out some of this.
- [ ] In the season leaderboard it would be nice to have the *actual* constructor in the the correct place along side the user's prediction for each line.
- [ ] Not sure what happens when teams/drivers are on equal points? This is mostly for the constructor and driver standings.
- [ ] Setup ty a lsp for python: https://github.com/astral-sh/ty

- [ ] Can we prevent the user from re-ordering the predictions whilst they are being submitted?
- [ ] We may wish to allow entering results even if the session leaderboard fails to download
- [ ] We may not really need model.formulaOneSessionResultSubmitStatus since we can just use the leaderboard status since it returns that. This is similar to formulaE where we just use the leaderboard status, so we should probably do it the same way for both.  I think if 'Inflight' could have a 'Maybe currentValue', that might be useful, and would mean I could set the leaderboard status when I submit the result.
- [x] See if we can make 'SafetyCar' on formula e predictions a Maybe Bool, such that we can submit a result with no safety car such that the 'No' guessers do not get an early point, in particular a point between qualifying and the race.

- [ ] Check on user login/logout on multiple tabs, does that work? I doubt it, but it should, shelfnova does it well.

## Backend
- [x] Must prevent prediction entry after the sesion start time
- [x] Must not give back any predictions, other than the current user's *before* the session start time.

## Times
- [x] Put the times on the formula 1 session page.
- [x] Maybe make it clear on the formula E page that the start time is that for qualifying and end of entry.
- [x] Sort out the zone, in the usual manner (using the package to get the timezone info).
- [x] Put times on the events in the season pages for both formula 1 and formula e.
- [ ] Consider showing the timezone whenever we show a time, or at least in some places.
- [x] You need to have a tick otherwise it won't tick past a session's start time.
- [ ] You need to do a bit of a deepdive on the RFC3339 format in python, and just check if your function will work in that case.

## Formula One
- [ ] Do not forget that for entry/result input, you have to merge the current with the entrants that are available. That should be a very rare occurrence (normally we will just update one or more of the entrants), but still it should work.
- [x] The session page should either have a link back to the event page, or a list of the other sessions in the event or both.
- [ ] On the event page, consider smarter displaying of the session times, probably do not need to show the year, and only  show the month if it differs from the start time of the event.
- [ ] For prediction entry, consider  countdown,  but that risks someone attempting to do so at the last second and expecting it to work, so either have a bit of a delay on the backend, or maybe not.
- [ ] The events list marks events as finished if the date is after the date of the start time, but for Formula One, we do not want that, so we probably wish to have a secondary datetime on formula one events which is the start time of the last session.
- [x] Session leaderboards, when showing the expanded user's predictions, we don't need to show positions 10-20.

## Formula E
- [ ] Should be a link back to the season page

## Formula E input

- [x] Allow submitting a prediction/result and saving it to the database.
- [x] Allow downloading the current predictions/results from the database to pre-populate the form.
- [x] Validate the prediction, so that all things should be set, and, for example you cannot select the same entrant for 1st, 2nd, and 3rd.
- [x] Results however, can be partial, and we do not need to worry about validation because if that is really the result then that's the result.
- [x] Figure out how to input safety car.
- [x] Perhaps just use a native alert for confirmation/failure of submission.

## Getting data
- [x] I'd really like some uniform way for each route to just describe what data it needs and then for the effects to be automatically calculated from that. In particular it should also set the appropriate loading state, because that's not being done everywhere perfectly.
- [ ] Ideally as well we would record the time that we last got the data and it would decide whether it needed to 're-get' it. This will come up in particular for the results. Which would be nice if we could automatically re-get the results on a session page. Though of course we could have a button to do that, and also we want to worry about viewing a session from a long time ago.


## Database migration
You now allow partial formula e results entry, in particular safety-car can be ""
But you will need to update the production database:
```
-- Create new table with updated constraint
create table results_new (
    race integer primary key not null,
    pole integer not null,
    fam  integer not null,
    fl   integer not null,
    hgc  integer not null,
    first integer not null,
    second integer not null,
    third integer not null,
    fdnf integer not null,
    safety_car text check (safety_car in ("yes", "no", "")) not null,
    foreign key (race) references races(id),
    foreign key (pole) references entrants(id),
    foreign key (fam) references entrants(id),
    foreign key (fl) references entrants(id),
    foreign key (hgc) references entrants(id),
    foreign key (first) references entrants(id),
    foreign key (second) references entrants(id),
    foreign key (third) references entrants(id),
    foreign key (fdnf) references entrants(id)
);

-- Copy existing data
insert into results_new select * from results;

-- Drop old table and rename new one
drop table results;
alter table results_new rename to results;
```
