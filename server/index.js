require("dotenv").config();
const express = require("express");

const db = require("./db")(process.env.DB, process.env.DB_USER, process.env.DB_PASS, process.env.DB_HOST);
const dragcave = require("./dragcave");

const app = express();
app.use(express.static("dist"));

const api = express.Router();
api.use(express.json());

api.post("/hatchery/:code", (req, res, next) => {
    const code = req.params.code;
    addOrUpdateDragon(code)
    .then(result => {
        if (result === "not found") { res.status(404).send(`Dragon ${code} not found.`); }
        else if (result === "not growing") { res.status(400).send(`Dragon ${code} is not growing.`); }
        else { res.json(result); }
    })
    .catch(next);
});

api.delete("/hatchery/:code", (req, res, next) => {
    db.dragons.destroy({
        where: {
            code: req.params.code
        }
    }).then(qtyDeleted => {
        if (qtyDeleted == 0) {
            res.status(404).send("Dragon not found.");
        } else {
            res.status(204).end();
        }
    }).catch(next);
});

api.get("/hatchery", (req, res) => {
    db.dragons.findAll().then(dragons => {
        res.json(dragons);
    });
});

app.use("/api/", api);
app.listen(3000, () => console.log("Listening on port 3000!"));