ELMAPP=static/main.js


elm: $(ELMAPP) 
$(ELMAPP): $(shell fd . -e elm src/)
	elm make src/Main.elm --debug --output=$(ELMAPP) 


