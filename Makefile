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

static/styles.min.css: static/styles.css
	@echo "Minifying styles..."
	lightningcss --minify $< -o $@

deploy: app.py $(ELMPRODAPP) static/styles.min.css
	@echo "Deploying application..."
	elm make src/Main.elm --optimize --output=$(ELMPRODAPP)
	python app.py config.prod.json
