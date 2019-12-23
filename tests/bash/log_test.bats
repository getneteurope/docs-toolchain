#!/usr/bin/env bats

function setup() {
    source $(pwd)/utils/log/log.sh
    export LOG_NOJSON="1" 
}

@test "INFO" {
    MSG="test Test TEST"
    run log INFO "$MSG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"INFO"* ]]
    [[ "$output" == *"$MSG" ]]
}

@test "DEBUG" {
    MSG="test Test TEST"
    run log DEBUG "$MSG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DEBUG"* ]]
    [[ "$output" == *"$MSG" ]]
}

@test "ERROR" {
    MSG="test Test TEST"
    run log ERROR "$MSG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ERROR"* ]]
    [[ "$output" == *"$MSG" ]]
}

@test "implicit INFO" {
    MSG="test Test TEST"
    run log "$MSG"
    [ "$status" -eq 0 ]
    [[ "$output" == *"INFO"* ]]
    [[ "$output" == *"$MSG" ]]
}