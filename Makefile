ELMDEBUGAPP=static/main-debug.js
ELMPRODAPP=static/main.js

.PHONY: review

elm: $(ELMDEBUGAPP) 
$(ELMDEBUGAPP): $(shell fd . -e elm src/)
	elm make src/Main.elm --debug --output=$(ELMDEBUGAPP) 

$(ELMPRODAPP): $(shell fd . -e elm src/)
	elm make src/Main.elm --optimize --output=$(ELMPRODAPP) 

review:
	elm-review

watch-frontend:
	@watchexec -w src -e elm "echo 'Elm file changed, rebuilding frontend...' && make elm" 

watch-backend:
	@watchexec -r -e py "echo 'Python file changed, rebuilding backend...' && python app.py config.dev.json"

.PHONY: check-css
check-css:
	@python check-css.py static/styles.css

# The brace check runs before minifying. A minifier closes any unclosed block at
# the end of the file rather than complaining, so it will happily produce output
# in which everything after the unclosed rule has become nested inside it.
static/styles.min.css: static/styles.css
	@python check-css.py $<
	@echo "Minifying styles..."
	lightningcss --minify $< -o $@


.PHONY: update-ranks
update-ranks:
	sqlite3 predictions.db < update-ranks.sql
	@echo "Ranks updated based on current WDC standings."

.PHONY: new_secret
new_secret:
	python -c "import secrets; print(secrets.token_urlsafe(32))"

deploy: app.py $(ELMPRODAPP) static/styles.min.css
	@echo "Deploying application..."
	elm make src/Main.elm --optimize --output=$(ELMPRODAPP)
	python app.py config.prod.json
