ELM_MAKE=npx elm make client/Main.elm --output=dist/elm.js
STYLUS_FILE=client/style.styl
STYLUS_OUTFILE=dist/style.css
STYLUS_ARGS=-o ${STYLUS_OUTFILE}

watch:
	npx chokidar **/*.elm -c '${ELM_MAKE}' --initial & npx nodemon -w server server/index.js & npx stylus -w ${STYLUS_FILE} ${STYLUS_ARGS}

stylus:
	npx stylus ${STYLUS_ARGS} < ${STYLUS_FILE} > ${STYLUS_OUTFILE}

elm:
	${ELM_MAKE} --optimize
	npx uglifyjs dist/elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | npx uglifyjs --mangle --output=dist/elm.js

build: stylus elm