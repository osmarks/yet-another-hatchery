PARCEL_ARGS=client/index.html --public-url "."

watch:
	parcel watch ${PARCEL_ARGS} & npx nodemon server/index.js

build:
	parcel build ${PARCEL_ARGS}