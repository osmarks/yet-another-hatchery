# yet-another-hatchery
Open-source hatchery for https://dragcave.net. Automatically removes eggs when sick and views slightly faster than alternatives.

## Installation
Run `npm install` then `make build`.
In order to connect to the database, the program must be run with the environment variables `DB` (database to use), `DB_USER` (database user), `DB_PASS` (database password), and `DB_HOST` (database to use, defaults to localhost).
`UPDATE_RATE` may also be set - this is the delay, in milliseconds, between each updating-all-eggs cycle.
Environment variables can also be set in a file named `.env` in your working directory, containing pairs of `ENV_VAR=value`.
Be sure to actually have a database running - I recommend PostgreSQL.

Running `node server/index.js` should then start the server.
`PORT` can be set to configure the port used - otherwise this defaults to 3000.
It can be used directly on the port you set, though it is recommended that you use a reverse proxy in front of it for HTTPS.

If you are running an unofficial instance, please replace the images with your own versions, and possibly the colors.

## Development
Same as [the installation section](#installation), but you can use `make watch` to watch the Stylus, Elm and JS files for development.
