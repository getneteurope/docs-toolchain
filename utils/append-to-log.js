const path = require('path');
const fs = require('fs');
const argv = require('minimist')(process.argv.slice(2));

// TODO outsource stfuGetJsonFromFile to module
/**
 * Reads JSON file without complaining about empty files or invalid content
 *
 * If file doesn't exist returns empty Object.
 * If file content is invalid JSON it returns empty Object unless strict == true
 *
 * @param {string} file Path to .json file.
 * @param {boolean} strict Decides wether to throw or ignore invalid JSON
 * 
 * @return {Object} Object or {}.
 */
function stfuGetJsonFromFile(file, strict = false) {
    var fileContents;
    try {
        fileContents = fs.readFileSync(file);
    } catch (err) {
        if (err.code === 'ENOENT') fileContents = '{}';
        else throw err;
    }
    try {
        JsonObject = JSON.parse(fileContents);
    }
    catch (err) {
        if (strict) throw err;
        else JsonObject = {};
    }
    return JsonObject;
}
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
    if(process.stdin.isTTY) {
        success = false;
        console.error("Missing message text: you must pipe text into this script.");
    }
    return success;
}

function main() {
    const logfileErrors = 'errors.log.json';
    if (sanityChecks() === false) {
        console.error(path.basename(__filename) + ": sanity checks failed!");
        return 1;
    }
    var Log = stfuGetJsonFromFile(logfileErrors);
    Log.errors = Log.errors || [];
    var ErrorObject = {};
    ErrorObject.timestamp = argv['timestamp'];
    ErrorObject.errorlevel = argv['errorlevel'];
    ErrorObject.caller = argv['caller'];
    ErrorObject.line = argv['line'];
    ErrorObject.message = fs.readFileSync(0).toString().trim(); // == stdin
    Log.errors.push(ErrorObject);
    try {
        var jsonFileContent = JSON.stringify(Log, null, 2);
        fs.writeFileSync(logfileErrors, jsonFileContent);
        console.log(Log);
    }
    catch (err) {
        throw err;
    }
    return 0;
}

const returnValue = main();
process.exit(returnValue);
