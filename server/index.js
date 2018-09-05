require("dotenv").config();
const express = require("express");
const compression = require("compression");

const db = require("./db")(process.env.DB, process.env.DB_USER, process.env.DB_PASS, process.env.DB_HOST);
const dragcave = require("./dragcave");

const staticDir = __dirname + "/../dist" // relative to this file

const app = express();

const api = express.Router();
api.use(express.json());

// Single-thing submit
// Takes code in URL
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

// Multi-thing submit
// Takes array of codes in body
api.post("/hatchery", async (req, res, next) => {
    const codes = req.body;
    if (Array.isArray(codes)) {
        const results = await Promise.all(codes.map(db.addOrUpdateDragon));
        for (let ix = 0; ix < results.length; ix++) { // can't use a forEach, we need early exit
            const result = results[ix];
            // TODO: make this code not be duplicated
            if (result === "not found") { res.status(404).send(`Dragon ${codes[ix]} not found.`); break; }
            else if (result === "not growing") { res.status(400).send(`Dragon ${code[ix]} is not growing.`); break; }
        }
        res.json(results);
    } else {
        res.status(400).send("Not an array.");
    }
});

// Single-thing delete
// Takes code in URL
api.delete("/hatchery/:code", (req, res, next) => {
    db.removeDragon(code).then(qtyDeleted => {
        if (qtyDeleted == 0) {
            res.status(404).send(`Dragon ${req.params.code} not found.`);
        } else {
            res.status(204).end();
        }
    }).catch(next);
});

// Multi-thing delete
// Takes array of codes in body
api.delete("/hatchery/", async (req, res, next) => {
    const codes = req.body;
    if (Array.isArray(codes)) {
        const results = await Promise.all(codes.map(db.removeDragon));
        for (let ix = 0; ix < results.length; ix++) {
            if (results[ix] == 0) { // if no rows deleted
                res.status(404).send(`Dragon ${codes[ix]} not found.`);
                break;
            }
        }
        res.status(204).end();
    } else {
        res.status(400).send("Not an array.");
    }
});

// Get all eligible dragons
api.get("/hatchery", (req, res) => {
    db.getEligibleDragons().then(dragons => {
        res.json(dragons);
    });
});

app.use("/api/", api);

const staticFiles = express.Router();
staticFiles.use(express.static(staticDir));
const sendFile = f => (req, res) => res.sendFile(f, { root: staticDir });
staticFiles.get("*.js", sendFile("elm.js"));
staticFiles.get("*.css", sendFile("style.css"));
staticFiles.get("*", sendFile("index.html"));
staticFiles.use(compression());

app.use(staticFiles);

setInterval(db.updateAll, parseInt(process.env.UPDATE_RATE) || 120000);

app.listen(parseInt(process.env.PORT) || 3000, () => console.log("Listening on port 3000!"));