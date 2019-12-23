const path = require('path');
const fs = require('fs');
const argv = require('minimist')(process.argv.slice(2));
const { getObjectFromFile } = require('../js/modules/common');
const config = require('../../config/log.json');

/**
 * Check if all required arguments have been provided
 * @return {boolean} true if all checks successful, false otherwise
 */
function sanityChecks() {
    if(!process.stdin.isTTY) {
        argv['message'] = fs.readFileSync(0).toString().trim(); // fd0 == stdin
    }
    const requiredArguments = ['timestamp', 'errorlevel', 'caller', 'line', 'message'];
    var success = true;
    for (var i in requiredArguments) {
        var arg = requiredArguments[i];
        if (argv[arg] === undefined || argv[arg] === null) {
            console.error("Missing argument: --" + arg);
            if (arg === 'message')
                console.error("--message can be omitted and piped");
            return false;
        }
    }

    return success;
}

function main() {
    const logfile = argv['file'] || config.LOG_FILE;
    if (!sanityChecks()) {
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
    MessageObject.message_text = argv['message'];
    Log.messages.push(MessageObject);
    try {
        var jsonFileContent = JSON.stringify(Log, null, 2);
        fs.writeFileSync(logfile, jsonFileContent);
    }
    catch (err) {
        console.error("Could not save log file");
        return 2;
    }
    return 0;
}

const returnValue = main();
process.exit(returnValue);
