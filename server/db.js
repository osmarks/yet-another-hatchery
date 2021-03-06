const Sequelize = require('sequelize');

const dragcave = require("./dragcave");

module.exports = (db, username, pass, host) => {
    const seq = new Sequelize(db, username, pass, {
        host: host,
        dialect: "postgres",
        operatorsAliases: false
    });

    const dragons = seq.define("dragons", {
        code: { type: Sequelize.STRING, primaryKey: true },
        type: { type: Sequelize.ENUM("egg", "hatchling"), allowNull: false },
        clicks: { type: Sequelize.INTEGER, allowNull: false },
        uniqueViews: { type: Sequelize.INTEGER, allowNull: false },
        views: { type: Sequelize.INTEGER, allowNull: false },
        hoursRemaining: { type: Sequelize.INTEGER, allowNull: false },
        sick: { type : Sequelize.BOOLEAN, defaultValue: false, allowNull: false }
    })

    seq.sync();

    function removeDragon(code) {
        return dragons.destroy({
            where: {
                code
            }
        });
    }

    function addOrUpdateDragon(code) {
        return dragcave.info(code).then(info => {
            if (info !== null) {
                if (info.type === "not growing") {
                    removeDragon(code);
                    return "not growing";
                } else {
                    info.code = code;
                    dragons.upsert(info);
                    return info;
                }
            } else {
                removeDragon(code);
                return "not found";
            }
        })
    }

    async function updateAll() {
        const drags = await dragons.findAll();
        console.log("Updating", drags.length, "dragons.")
        return Promise.all(drags.map(d => addOrUpdateDragon(d.code)));
    }

    function getEligibleDragons() {
        return dragons.findAll({
            where: {
               sick: false 
            }
        }).then(dragons => dragons.filter(dragcave.isSafe));
    }

    return {
        dragons,
        sequelize: seq,
        addOrUpdateDragon,
        getEligibleDragons,
        updateAll,
        removeDragon
    };
}