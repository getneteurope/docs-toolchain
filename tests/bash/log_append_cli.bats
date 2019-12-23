#!/usr/bin/env bats

@@test "node logging cli" {
    MSG_TEXT="Test TEST"
    run echo "${MSG_TEXT}" | node ${TOOLCHAIN_PATH}/utils/log/log_append.js \
        --timestamp="$(date +%s)" --errorlevel="INFO" --caller="<unit-test>" --line="XXX"
    [ "$status" -eq 0 ]
    grep "INFO" /tmp/logs/messages.log.json
    grep "<unit-test>" /tmp/logs/messages.log.json
    grep "$MSG_TEXT"
}