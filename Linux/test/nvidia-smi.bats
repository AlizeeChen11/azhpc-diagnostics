#!/bin/usr/env bats
# testing analysis of nvidia-smi outputs

function setup {
    load "test_helper/bats-support/load"
    load "test_helper/bats-assert/load"
    load ../src/gather_azhpc_vm_diagnostics.sh --no-update

    DIAG_DIR=$(mktemp -d)
    mkdir -p "$DIAG_DIR/Nvidia"
    cp "$BATS_TEST_DIRNAME/samples/nvidia-smi.txt" "$DIAG_DIR/Nvidia/nvidia-smi.txt"

    SAVED_DEVICES_PATH="$DEVICES_PATH"
    DEVICES_PATH=$(mktemp -d)
    for i in {1..4}; do
        mkdir -p "$DEVICES_PATH/00000000-0000-0000-0000-00000000000$i/pci000$i:00"
    done
}

function teardown {
    rm -rf "$DIAG_DIR" "$DEVICES_PATH"
    DEVICES_PATH="$SAVED_DEVICES_PATH"
}

@test "no dbe violations" {
    . "$BATS_TEST_DIRNAME/mocks.bash"

    run check_page_retirement

    assert_success
    refute_output
}

@test "no inforom corruption" {
    . "$BATS_TEST_DIRNAME/mocks.bash"
    
    run check_inforom

    assert_success
    refute_output
}

@test "report bad gpu" {
    . "$BATS_TEST_DIRNAME/mocks.bash"

    run report_bad_gpu 2 reason

    assert_success
    assert_equal "${#lines[@]}" 1

    assert_line --index 0 --partial 'reason'
    assert_line --index 0 --partial '00000000-0000-0000-0000-000000000003'
    assert_line --index 0 --partial '0000000000003'

    assert grep -q "$output" "$DIAG_DIR/transcript.log"
}

@test "detect dbe over threshold" {
    . "$BATS_TEST_DIRNAME/mocks.bash"

    MOCK_GPU_SBE_DBE_COUNTS=( "29, 30" "60, 0" "0, 60" "31, 31" )

    run check_page_retirement

    assert_success
    assert_equal "${#lines[@]}" 3

    assert_line --index 0 --partial 'DBE(60)'
    assert_line --index 0 --partial '00000000-0000-0000-0000-000000000002'
    assert_line --index 0 --partial '0000000000002'

    assert_line --index 1 --partial 'DBE(60)'
    assert_line --index 1 --partial '00000000-0000-0000-0000-000000000003'
    assert_line --index 1 --partial '0000000000003'

    assert_line --index 2 --partial 'DBE(62)'
    assert_line --index 2 --partial '00000000-0000-0000-0000-000000000004'
    assert_line --index 2 --partial '0000000000004'
}

@test 'detect inforom warnings' {
    . "$BATS_TEST_DIRNAME/mocks.bash"

    echo "WARNING: infoROM is corrupted at gpu 0001:00:00.0" >>"$DIAG_DIR/Nvidia/nvidia-smi.txt"
    echo "WARNING: infoROM is corrupted at gpu 0003:00:00.0" >>"$DIAG_DIR/Nvidia/nvidia-smi.txt"

    run check_inforom

    assert_success
    assert_equal "${#lines[@]}" 2

    assert_line --index 0 --partial 'infoROM Corrupted'
    assert_line --index 0 --partial '00000000-0000-0000-0000-000000000001'
    assert_line --index 0 --partial '0000000000001'

    assert_line --index 1 --partial 'infoROM Corrupted'
    assert_line --index 1 --partial '00000000-0000-0000-0000-000000000003'
    assert_line --index 1 --partial '0000000000003'
}
