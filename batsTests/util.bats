#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

# util.sh calls 'doguctl random' twice while it is sourced (ADMINUSER and ADMINPW), so the calls
# made by the function under test start at index 3.
SOURCE_CALLS=2

setup() {
  export NEXUS_WORKDIR=/workspace

  doguctl="$(mock_create)"
  export doguctl
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"

  export PATH="${BATS_TMPDIR}:${PATH}"
}

teardown() {
  unset NEXUS_WORKDIR
  rm "${BATS_TMPDIR}/doguctl"
}

@test "encryptSecretEncryptionKey should do nothing if the key is already encrypted" {
  source /workspace/resources/util.sh

  mock_set_output "${doguctl}" "encrypted-value" $((SOURCE_CALLS + 1))
  # reading it with -e succeeds, so it is already encrypted
  mock_set_status "${doguctl}" 0 $((SOURCE_CALLS + 2))

  run encryptSecretEncryptionKey

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "$((SOURCE_CALLS + 2))")" "config -e secret_encryption/key"
  assert_equal "$(mock_get_call_num "${doguctl}")" "$((SOURCE_CALLS + 2))"
}

@test "encryptSecretEncryptionKey should re-encrypt a plain text key with its value unchanged" {
  source /workspace/resources/util.sh

  mock_set_output "${doguctl}" "plain-text-value" $((SOURCE_CALLS + 1))
  # reading it with -e fails, so the stored value is still plain text
  mock_set_status "${doguctl}" 1 $((SOURCE_CALLS + 2))
  mock_set_status "${doguctl}" 0 $((SOURCE_CALLS + 3))

  run encryptSecretEncryptionKey

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "$((SOURCE_CALLS + 3))")" "config -e secret_encryption/key plain-text-value"
  assert_line " - secret_encryption/key is now stored encrypted"
}