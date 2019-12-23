#!/usr/bin/env bats

###############################################################
# DOES NOT WORK - SKIP
###############################################################

@test "Node: logging from CLI (log_append.js) [pipe]" {
    skip
    local logfile="/tmp/logs/messages.log.json"
    MSG_TEXT="Test TEST pipe"
    run bash -c "echo ${MSG_TEXT} | node ${TOOLCHAIN_PATH}/utils/log/log_append.js --timestamp='123456' --errorlevel='INFO' --caller='<unit-test>' --line='XXX'"
    [ "$status" -eq 0 ]
    grep "INFO" "$logfile"
    grep "<unit-test>" "$logfile"
    grep "$MSG_TEXT"
}

@test "Node: logging from CLI (log_append.js) [argument]" {
    skip
    local logfile="./test.log.json"
    MSG_TEXT="Test TEST argument"
    run node ${TOOLCHAIN_PATH}/utils/log/log_append.js \
        --timestamp="$(date +%s)" --errorlevel="INFO" --caller="<unit-test>" --line="XXX" \
        --message="{MSG_TEXT}" --file="$logfile"
    [ "$status" -eq 0 ]
    grep "INFO" "$logfile"
    grep "<unit-test>" "$logfile"
    grep "$MSG_TEXT"
}