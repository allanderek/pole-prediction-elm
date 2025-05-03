ELMAPP=static/main.js

.PHONY: review

elm: $(ELMAPP) 
$(ELMAPP): $(shell fd . -e elm src/)
	elm make src/Main.elm --debug --output=$(ELMAPP) 

review:
	elm-review
