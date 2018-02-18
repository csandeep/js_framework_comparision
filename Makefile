js_server: 
		cd server && node server

elm: 
	cd elm_app && elm-make --output cards.js src/Cards.elm

setup:
	cd server && npm install && cd ../elm_app && npm install -g elm && elm-package install -y

apps: elm

.PHONY: setup
