const fs = require('fs');

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

function timestampToDate(timestamp) {
    const dateObject = new Date((timestamp.toString().length < 14) ? timestamp * 1000 : timestamp);
    var dateArray = [];
    dateArray['YYYY'] = dateObject.getFullYear();
    dateArray['MM'] = ('0' + (dateObject.getMonth() + 1)).slice(-2);
    dateArray['HH'] = ('0' + dateObject.getHours()).slice(-2);
    dateArray['DD'] = ('0' + dateObject.getDate()).slice(-2);
    dateArray['mm'] = ('0' + dateObject.getMinutes()).slice(-2);
    dateArray['ss'] = ('0' + dateObject.getSeconds()).slice(-2);
    return dateArray;
}

/**
 * dummy parser
 */
function main() {
    const logfile = 'messages.log.json';
    var Log = stfuGetJsonFromFile(logfile);
    for (i in Log.messages) {
        var MsgObject = log.messages[i];
        var dateArray = timestampToDate(MsgObject.timestamp);
        var timestampString = dateArray['HH'] + ':' + dateArray['mm'] + ':' + dateArray['ss'];
        console.err('[' + timestampString + '] ' + MsgObject.errorlevel + ' ' + MsgObject.caller + ':' + MsgObject.line + ' ' + MsgObject.message_text);
    }
    return 0;
}

const returnValue = main();
process.exit(returnValue);
