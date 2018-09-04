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
    const days = parseInt(getCapture(text, /in: ([0-9]+) day/, 0));
    const hours = parseInt(getCapture(text, /and ([0-9]+) hour/, 0));
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

module.exports = {
    info: dragonInfo
};