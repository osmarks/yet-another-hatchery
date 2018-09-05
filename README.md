# yet-another-hatchery
Open-source hatchery for https://dragcave.net. Automatically removes eggs when sick and views slightly faster than alternatives.

## Installation
Run `npm install` then `make build`.
In order to connect to the database, the program must be run with the environment variables
* `DB` - database to use.
* `DB_USER` - user to log into database as
* `DB_PASS` - password to use
* `DB_HOST` - host of database, defaults to localhost
Currently only PostgreSQL is supported, though if you really need anything else I can modify it for you.

Other configuration options:
* `PORT` - port to run on, defaults to 3000.
* `UPDATE_RATE` - interval between each run of fetching dragon data.

Running `node server/index.js` should then start the server.
It can be used directly on the port you set, though it is recommended that you use a reverse proxy in front of it for HTTPS.

If you are running an unofficial instance, please replace the images with your own versions, and possibly the colors.

## Development
Follow [the installation steps](#installation), but use `make watch` to watch the Stylus, Elm and JS files for development in place of `make build`.

Thanks [http.cat](https://http.cat) for the error images!
