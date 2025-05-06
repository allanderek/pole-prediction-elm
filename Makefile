ELMAPP=static/main.js

.PHONY: review

elm: $(ELMAPP) 
$(ELMAPP): $(shell fd . -e elm src/)
	elm make src/Main.elm --debug --output=$(ELMAPP) 

review:
	elm-review

watch-frontend:
	@watchexec -w src -e elm "echo 'Elm file changed, rebuilding frontend...' && make elm" 

watch-backend:
	@watchexec -w . -e py "echo 'Python file changed, rebuilding backend...' && python app.py config.dev.json"
