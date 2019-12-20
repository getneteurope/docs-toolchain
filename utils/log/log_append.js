const path = require('path');
const fs = require('fs');
const argv = require('minimist')(process.argv.slice(2));
const { getObjectFromFile } = require('../js/modules/common');

/**
 * Check if all required arguments have been provided
 * @return {boolean} true if all checks successful, false otherwise
 */
function sanityChecks() {
    const requiredArguments = ['timestamp', 'errorlevel', 'caller', 'line'];
    var success = true;
    for (var i in requiredArguments) {
        var arg = requiredArguments[i];
        if (argv[arg] === undefined) {
            success = false;
            console.error("Missing argument: --" + arg);
        }
    }

    // see if a message is being piped to script
    if (process.stdin.isTTY) {
        success = false;
        console.error("Missing message text: you must pipe text into this script.");
    }
    return success;
}

function main() {
    const logfile = 'messages.log.json';
    if (sanityChecks() === false) {
        console.error(path.basename(__filename) + ": sanity checks failed!");
        return 1;
    }
    var Log = getObjectFromFile(logfile);
    Log.messages = Log.messages || [];
    var MessageObject = {};
    MessageObject.timestamp = argv['timestamp'];
    MessageObject.errorlevel = argv['errorlevel'];
    MessageObject.caller = argv['caller'];
    MessageObject.line = argv['line'];
    MessageObject.message_text = fs.readFileSync(0).toString().trim(); // fd0 == stdin
    Log.messages.push(MessageObject);
    try {
        var jsonFileContent = JSON.stringify(Log, null, 2);
        fs.writeFileSync(logfile, jsonFileContent);
    }
    catch (err) {
        throw err;
    }
    return 0;
}

const returnValue = main();
process.exit(returnValue);
