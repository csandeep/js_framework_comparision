js_server: 
		cd server && node server

elm: 
	cd elm_app && elm-make --output cards.js src/Cards.elm

setup:
	cd server && npm install && cd ../elm_app && npm install -g elm && elm-package install -y && cd ../react_app && npm install

apps: elm react

react:
	cd react_app && npm run build && ./node_modules/.bin/serve -C -s  ./build/

.PHONY: setup
