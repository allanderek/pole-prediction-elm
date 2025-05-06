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



