require("dotenv").config();
const express = require("express");
const compression = require("compression");

const db = require("./db")(process.env.DB, process.env.DB_USER, process.env.DB_PASS, process.env.DB_HOST);
const dragcave = require("./dragcave");

const staticDir = __dirname + "/../dist" // relative to this file

const app = express();

const api = express.Router();
api.use(express.json());

api.post("/hatchery/:code", (req, res, next) => {
    const code = req.params.code;
    db.addOrUpdateDragon(code)
    .then(result => {
        if (result === "not found") { res.status(404).send(`Dragon ${code} not found.`); }
        else if (result === "not growing") { res.status(400).send(`Dragon ${code} is not growing.`); }
        else { res.json(result); }
    })
    .catch(next);
});

api.delete("/hatchery/:code", (req, res, next) => {
    db.removeDragon(code).then(qtyDeleted => {
        if (qtyDeleted == 0) {
            res.status(404).send(`Dragon ${req.params.code} not found.`);
        } else {
            res.status(204).end();
        }
    }).catch(next);
});

api.get("/hatchery", (req, res) => {
    db.getEligibleDragons().then(dragons => {
        res.json(dragons);
    });
});

app.use("/api/", api);

const staticFiles = express.Router();
staticFiles.use(express.static(staticDir));
const sendFile = f => (req, res) => res.sendFile(f, { root: staticDir });
staticFiles.use("*.js", sendFile("elm.js"));
staticFiles.use("*.css", sendFile("style.css"));
staticFiles.use("*", sendFile("index.html"));
staticFiles.use(compression());

app.use(staticFiles);

setInterval(db.updateAll, parseInt(process.env.UPDATE_RATE) || 120000);

app.listen(parseInt(process.env.PORT) || 3000, () => console.log("Listening on port 3000!"));