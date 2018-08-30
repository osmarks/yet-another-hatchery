const Sequelize = require('sequelize');

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
        hoursRemaining: { type: Sequelize.INTEGER, allowNull: false }
    })

    seq.sync();

    function addOrUpdateDragon(code) {
        return dragcave.info(code).then(info => {
            if (info !== null) {
                if (info.type === "not growing") {
                    return "not growing";
                } else {
                    info.code = code;
                    db.dragons.upsert(info);
                    return info;
                }
            } else {
                return "not found";
            }
        })
    }

    return {
        dragons,
        sequelize: seq,
        addOrUpdateDragon
    };
}