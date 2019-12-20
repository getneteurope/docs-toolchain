const execSync = require('child_process').execSync;
const fs = require('fs');

/**
 * To be used by log()
 * Gets information about the script and function which called log()
 * @return {Object} containing caller filename and line number
 */
function getCallerInfo() {
    const stackLine = (new Error()).stack.split("at ")[3];
    const stackRegex = /(.*) \((\/.+\/)([^:]+):([0-9]+):([0-9]+)/;
    const stackMatches = stackLine.match(stackRegex);
    const callerFunction = stackMatches[1];
    const caller = stackMatches[3];
    const lineNumber = stackMatches[4];

    return {
        'line': lineNumber,
        'caller_function': callerFunction, 
        'caller': caller
    }
}

function escapeShell(cmd) {
    // escape for use in shell, except spaces
    return '"'+cmd.replace(/(["\s'$`\\[^\ ]])/g,'\\$1')+'"';
};

Utils = {}
// if TOOLCHAIN_PATH is already set, use it. if not, check if toolchain folder exists. if not assume you're in toolchain repo dir
Utils.TOOLCHAIN_PATH = process.env.TOOLCHAIN_PATH ? process.env.TOOLCHAIN_PATH
                     : fs.existsSync('toolchain') ? 'toolchain/'
                     : '';
process.env.TOOLCHAIN_PATH=Utils.TOOLCHAIN_PATH;
Utils.CONTENT_PATH = process.env.GITHUB_WORKSPACE || 'content/';
Utils.log = function (message, errorLevel = 'INFO') {
    const CallerInfo = getCallerInfo();
    if(errorLevel != 'INFO') { // add caller function to message if not plain INFO
        message = CallerInfo.caller_function + '(): ' + message; // must escape for shell
    }
    // TODO rewrite for piping message!
    execSync('bash ' + Utils.TOOLCHAIN_PATH + 'utils/log/log.sh'
        + ' --caller ' + CallerInfo.caller
        + ' --line ' + CallerInfo.line
        + ' ' + errorLevel
        + ' ' + escapeShell(message));
};

Utils.timestampToDate = function (timestamp) {
    const dateObject = new Date((timestamp.toString().length < 14) ? timestamp * 1000 : timestamp);
    var dateArray = [];
    dateArray['YYYY'] = dateObject.getFullYear();
    dateArray['MM'] = ('0' + (dateObject.getMonth() + 1)).slice(-2);
    dateArray['HH'] = ('0' + dateObject.getHours()).slice(-2);
    dateArray['DD'] = ('0' + dateObject.getDate()).slice(-2);
    dateArray['mm'] = ('0' + dateObject.getMinutes()).slice(-2);
    dateArray['ss'] = ('0' + dateObject.getSeconds()).slice(-2);
    return dateArray;
};

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
Utils.getObjectFromFile = function (file, strict = false) {
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
};

module.exports = Utils;
