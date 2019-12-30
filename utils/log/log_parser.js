const { getObjectFromFile, timestampToDate } = require('../js/modules/common');
const config = require('../../config/log.json');

function main() {
  const logfile = config.LOG_FILE;
  var Log = getObjectFromFile(logfile);
  for (var i in Log.messages) {
    var MsgObject = Log.messages[i];
    var dateArray = timestampToDate(MsgObject.timestamp);
    // jshint -W069
    var timestampString = dateArray['HH'] + ':' +
      dateArray['mm'] + ':' + dateArray['ss'];
    // jshint +W069
    console.log('[' + timestampString + '] ' + MsgObject.errorlevel +
      ' ' + MsgObject.caller + ':' + MsgObject.line + ' ' + MsgObject.message_text);
  }
  return 0;
}

const returnValue = main();
process.exit(returnValue);
