const fetch = require("node-fetch");
const { JSDOM } = require("jsdom");

function getCapture(text, regex, def) {
    const result = text.match(regex);
    if (result === null || result === undefined) { 
        if (def === undefined) {
            throw new Error("Text did not match regex.");
        } else {
            return def;
        }
    }
    else { return result[1]; }
}

// Parses a numeric counter somewhere in the text (like "Overall views: 123,456,789")
function parseCounter(text, label) {
    const re = new RegExp(label + ": *([0-9,]+)");
    return parseInt(getCapture(text, re).replace(",", ""));
}

/*
This is quite bad. I would prefer to not do this if possible. But DC has left me no option other than to parse HTML via these regexes.
- The HTML it produces doesn't have any useful classes etc in it
- I don't have API access
*/
function infoFromHtml(html) {
    // First, just strip all the actual HTML & get text
    const text = JSDOM.fragment(html).textContent;

    if (/will die if it doesn/.exec(text) === null) { return { type: "not growing" }; }
    
    let sick = false;
    // Check for text indicating sickness.
    if (/shell of the egg seems soft,/.exec(text) !== null) { sick = true }
    if (/hatchling seems sick/.exec(text) !== null) { sick = true }

    // Parse all view-y counters
    const views = parseCounter(text, "Overall views");
    const uniqueViews = parseCounter(text, "Unique views");
    const clicks = parseCounter(text, "Clicks");
    
    // Try and parse remaining-time bits
    const days = parseInt(getCapture(text, /in: (\d+) day/, 0));
    const hours = parseInt(getCapture(text, /and (\d+) hour/, 0));
    const type = getCapture(text, /Viewing (Hatchling|Egg)/)

    if (isNaN(days) || isNaN(hours)) { throw new Error("Either days or hours are now invalid; has DC's format changed?"); }

    return {
        views,
        uniqueViews,
        clicks,
        type: type == "Hatchling" ? "hatchling" : "egg",
        hoursRemaining: days * 24 + hours,
        sick
    }
}

function dragonInfo(code) {
    return fetch("https://dragcave.net/view/" + code)
        .then(res => res.ok ? res.text().then(infoFromHtml) : null);
}

/*
From EATW:
<!-- SECRET BONUS 
Views, unique views and clicks are weighted according to the following formula when performing the calculations: Score = Views + Unique views * 6 + Clicks * 12.
This formula is quite close to what Dragcave uses internally. 
An egg at the 4 day mark requires a score of ~3000-6000, depending on the breed and whether it is incubated or not. 
Shimmerscale, Tinsel and GoN require even more, somewhere about 7000-8000, although they get sick at 6500-7000 already. 
EATW considers a score of 5000 to be optimal as this won't cause sickness for incubated eggs, but is still sufficient to make (almost) all breeds to hatch at the 4 day mark if not incubated. 
Gendering occurs at a score of ~4000-8000, growing at the 4 day mark requires a score of 5000-10000. 
EATW considers the upper limit to be safe for all dragons since sickness won't occur at these numbers for hatchlings. 
Want it? Here you can get the source: http://eatw.net/stuff.php. (this is now unavailable)
The more hatcheries switch to that system, the safer it gets.
UPDATE: 
It appears like TJ09 silently raised the numbers required for ultra-rare metallic hatchlings even further. 
EATW will now push all hatchlings towards a score of 15,000 at the 4 day mark. This should be sufficient... 
SECRET BONUS -->
*/

function getScore(dragon) {
    return dragon.views + (dragon.uniqueViews * 6) + (dragon.clicks * 12);
}

const nextStageAge = 72;
const maxTime = 168;

function getOptimalScore(dragon) {
    const time = dragon.hoursRemaining;
    const age = maxTime - time;
    if (dragon.type == "hatchling") {
        return 5000 + (10000 * (age / nextStageAge));
    } else {
        return 5000 * (age / nextStageAge);
    }
}

function getScoreRatio(dragon) {
    return getScore(dragon) / getOptimalScore(dragon);
}

function isSafe(dragon) {
    return getScoreRatio(dragon) < 1.5;
}

module.exports = {
    info: dragonInfo,
    getOptimalScore,
    getScore,
    isSafe,
    getScoreRatio
};