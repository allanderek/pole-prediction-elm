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
- [ ] Decide what to do about non-participating entrants, either download them but deal with them on the front-end, filter them out in the SQL query.
- [ ] Learn about workers and whether I need those to keep the data up to date.


- [ ] Consider a bit of a refactor of the database, we could have that the entrants all have ids 1-20, but the primary key of the entrant is a composite primary key consisting of session id with the entrant id. This would have some advantages. Such as creating all the entrants in the database at the start of the season. Changing one should really be changing either a driver for a replacement (e.g. Bearman for Sainz due to appendecitis), or swapping teams, e.g. Tsunoda for Lawson and vice versa. 

- [ ] Get the predictions for a session, this depends on the time, you just get the logged-in user's predictions for the session if the start-time has not passed, otherwise you get all the predictions for the session, including any results. Also the predictions are all scored (which will be zero if there is no result yet).

- [ ] You have authentication but no way to register at the moment.
- [ ] I may do 'event' leaderboard which is just get the leaderboard for the season but restrict it to sessions within a given event, and show it on the event page?
- [ ] Can I do something cool with testing, i.e. run elm test by actually using the database from python?
- [ ] Don't forget that before next year you will have to do season prediction input.
- [ ] There is some duplication in the constructor standings and the season leaderboard, precisely to calculate the constructor standings. I should be able to factor out some of this.
- [ ] In the season leaderboard it would be nice to have the *actual* constructor in the the correct place along side the user's prediction for each line.
- [ ] Not sure what happens when teams/drivers are on equal points? This is mostly for the constructor and driver standings.
- [ ] Setup ty a lsp for python: https://github.com/astral-sh/ty

- [ ] Create an effect for sending predictions to the server
- [ ] On response, the entry in the formulaOneSessionEntries should be removed, and when there is no such entry, the 'submit' button can be disabled. Question, what to do if the user re-orders back to what we *think* is the same order? I suggest that it is still enabled so that the user can make certain they are changing it to what they want.
- [ ] Can we prevent the user from re-ordering the predictions whilst they are being submitted?
- [ ] Should we just get rid of the entire SQLItePlugin thing and just use the context manager? It seems more hassle than it's worth particularly if it's not going to work with require_auth.
- [ ] Next step is to allow updating with Results, a little tricky since it's difficult to get the current result from the leaderboard, unless we also download that at the same time.
- [ ] We may wish to allow entering results even if the session leaderboard fails to download
- [ ] We may not really need model.formulaOneSessionResultSubmitStatus since we can just use the  leaderboard status since it returns that.
- [ ] See if we can make 'SafetyCar' on formula e predictions a Maybe Bool, such that we can submit a result with no safety car such that the 'No' guessers do not get an early point, in particular a point between qualifying and the race.

- [ ] Check on user login/logout on multiple tabs, does that work? I doubt it, but it should, shelfnova does it well.

## Formula E input

- [x] Allow submitting a prediction/result and saving it to the database.
- [x] Allow downloading the current predictions/results from the database to pre-populate the form.
- [ ] Validate the prediction, so that all things should be set, and, for example you cannot select the same entrant for 1st, 2nd, and 3rd.
- [ ] Results however, can be partial, and we do not need to worry about validation because if that is really the result then that's the result.
- [x] Figure out how to input safety car.
- [ ] Perhaps just use a native alert for confirmation/failure of submission.
