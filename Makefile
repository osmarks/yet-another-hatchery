ELM_MAKE=npx elm make client/Main.elm --output=dist/elm.js

watch:
	npx chokidar **/*.elm -c '${ELM_MAKE}' --initial & npx nodemon -w server server/index.js

build:
	${ELM_MAKE} --optimize
	npx uglifyjs dist/elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | npx uglifyjs --mangle --output=dist/elm.js