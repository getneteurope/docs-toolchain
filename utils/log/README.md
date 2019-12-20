# Logging Utilities

## How to use

You can use the logger

- [Inside Bash scripts](#inside-a-bash-script)
- [In NodeJS via the `Utils` module](#inside-a-node-script)
- [Standalone](#standalone)

### Inside a Bash Script
```bash
source log.sh
log DEBUG 'only shown if DEBUG=true'
log 'some info message text'
log WARN 'this is a warning'
log ERROR 'uh oh'
```

### Inside a Node Script
Use the provided wrapper in `utils/js/modules/common.js`.
For details please refer to the JavaScript wrapper `Utils.log()` description.
```js
const log = require('../js/modules/common').log;
log('Some debug message', 'DEBUG');
log('Just some info here');
```

### Standalone
```bash
./log.sh --caller calling_script.js --line 123 LOGLEVEL Message Text Here
```

## Possible log levels
`LOGLEVEL` can be one of `DEBUG` `INFO` `WARN` `ERROR` and defaults to `INFO` if not provided.

*NOTE*: Messages with log level `DEBUG` will not be written to console unless `DEBUG=true` is set in env!

---

# log.sh Logging Util

Used as default logging utility.

## Usage
Can either be sourced by a [Bash script](#inside-a-bash-script), invoked [via Node module](#inside-a-node-script) or used [standalone](#standalone).

## Functionality
Writes output to console with a timestamp and logs messages in `messages.log.json` using [`log_append.js script`](#log_append.js).

NOTE: If you want to use the Bash log() function before having installed the necessary NodeJS dependencies, set `LOG_NOJSON=true` in your environment and you'll get only console output.
### Sample Output

#### Console Output
```
[13:25:43] INFO js_combine.js:25 Combining js files in docinfo.html
[13:25:44] WARN js_combine.js:29 combineJS(): Could not read docinfo.html
```

##### Explanation
- `[13:25:44]` - Timestamp
- `WARN` - One of the log levels
- `js_combine.js`- File that called the `log()` function
- `29` - Line number inside the script where `log()` was called
- `combineJS()` - Name of the function in which `log()` was called (available only via `Utils` module)
- `Could not read docinfo.html` - The actual log message text

#### File Output
Written to `messages.log.json`.
```json
{
  "messages": [
    {
      "timestamp": 1576840179,
      "errorlevel": "INFO",
      "caller": "js_combine.js",
      "line": 25,
      "message_text": "Combining js files in docinfo.html"
    },
    {
      "timestamp": 1576840179,
      "errorlevel": "WARN",
      "caller": "js_combine.js",
      "line": 29,
      "message_text": "combineJS(): Could not read docinfo.html"
    } ]
}
```

---

# log_append.js
Adds messages to a message log file `messages.log.json`.
Is used only by `log.sh` currently but _can_ be used as standalone script.
The log file can then be parsed at a later stage and used e.g. for notifications.

## Usage
Provide arguments `--timestamp`, `--errorlevel`, `--caller` and `--line` and pipe your message to `stdin`!
```bash
cat some_big_message | node log_append.js \
    --timestamp="UNIX_TIMESTAMP" \
    --errorlevel="LOGLEVEL" \
    --caller="CALLER_SCRIPT_NAME" \
    --line="LINE_NUMBER"
```

