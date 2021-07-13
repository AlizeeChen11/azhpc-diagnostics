#!/bin/usr/env bats
# Tests for VM metadata (IMDS) collection

function setup {
    load "test_helper/bats-support/load"
    load "test_helper/bats-assert/load"
    load ../src/gather_azhpc_vm_diagnostics.sh --no-update

    DIAG_DIR=$(mktemp -d)
}

function teardown {
    rm -rf "$DIAG_DIR"
}

@test "Check that waagent.log is collected" {
    run run_vm_diags
    assert [ ! -s /var/log/waagent.log -o -s "$DIAG_DIR/VM/waagent.log" ]
}

@test "Check that lspci output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/lspci.txt" ]
}

@test "Check that ifconfig output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/ifconfig.txt" ]
}

@test "Check that sysctl output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/sysctl.txt" ]
}

@test "Check that uname output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/uname.txt" ]
}

@test "Check that dmidecode output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/dmidecode.txt" ]
}

@test "Check that dmesg output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/dmesg.log" ]
}

@test "Check that lsmod output is collected" {
    run run_vm_diags
    assert [ -f "$DIAG_DIR/VM/lsmod.txt" ]
}

@test "lsvmbus installed" {
    . "$BATS_TEST_DIRNAME/mocks.bash"

    run run_lsvmbus_resilient
    assert_success
    assert [ -s "$DIAG_DIR/VM/lsvmbus.log" ]
}

@test "lsvmbus installed at runtime" {
    . "$BATS_TEST_DIRNAME/mocks.bash"
    hide_command lsvmbus
    if ! PYTHON="$(get_python_command)"; then
        skip "no python installed" # TODO: figure out how to mock python
    fi

    run run_lsvmbus_resilient
    assert [ -s "$DIAG_DIR/VM/lsvmbus.log" ]
}

@test "lsvmbus not installed and no python" {
    . "$BATS_TEST_DIRNAME/mocks.bash"
    hide_command lsvmbus
    hide_command python
    hide_command python2
    hide_command python3

    run run_lsvmbus_resilient
    refute [ -s "$DIAG_DIR/VM/lsvmbus.log" ]
}

@test "lsvmbus offline but installed" {
    . "$BATS_TEST_DIRNAME/mocks.bash"
    OFFLINE=true

    run run_lsvmbus_resilient
    assert [ -s "$DIAG_DIR/VM/lsvmbus.log" ]
}

@test "lsvmbus offline and not installed" {
    . "$BATS_TEST_DIRNAME/mocks.bash"
    hide_command lsvmbus
    OFFLINE=true

    run run_lsvmbus_resilient
    refute [ -s "$DIAG_DIR/VM/lsvmbus.log" ]
}
