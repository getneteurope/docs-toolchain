const {getObjectFromFile, timestampToDate} = require('../js/modules/common');

function main() {
    const logfile = 'messages.log.json';
    var Log = getObjectFromFile(logfile);
    for (i in Log.messages) {
        var MsgObject = Log.messages[i];
        var dateArray = timestampToDate(MsgObject.timestamp);
        var timestampString = dateArray['HH'] + ':' + dateArray['mm'] + ':' + dateArray['ss'];
        console.log('[' + timestampString + '] ' + MsgObject.errorlevel + ' ' + MsgObject.caller + ':' + MsgObject.line + ' ' + MsgObject.message_text);
    }
    return 0;
}

const returnValue = main();
process.exit(returnValue);
