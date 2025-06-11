#! /bin/bash
# Bind an unbound BATS variables that fail all tests when combined with 'set -o nounset'
export BATS_TEST_START_TIME="0"
export BATSLIB_FILE_PATH_REM=""
export BATSLIB_FILE_PATH_ADD=""

load '/workspace/target/bats_libs/bats-support/load.bash'
load '/workspace/target/bats_libs/bats-assert/load.bash'
load '/workspace/target/bats_libs/bats-mock/load.bash'
load '/workspace/target/bats_libs/bats-file/load.bash'

setup() {
  export DOGU_RESOURCE_DIR=/workspace/resources
  export WORKDIR=/workspace

  jq="$(mock_create)"
  export jq
  ln -s "${jq}" "${BATS_TMPDIR}/jq"

  doguctl="$(mock_create)"
  export doguctl
  ln -s "${doguctl}" "${BATS_TMPDIR}/doguctl"

  curl="$(mock_create)"
  export curl
  ln -s "${curl}" "${BATS_TMPDIR}/curl"

  export PATH="${BATS_TMPDIR}:${PATH}"
}

teardown() {
  unset DOGU_RESOURCE_DIR
  unset WORKDIR
  rm "${BATS_TMPDIR}/jq"
  rm "${BATS_TMPDIR}/doguctl"
  rm "${BATS_TMPDIR}/curl"
}

@test "deleteOldComponents should delete all components in local config" {
  source /workspace/resources/component-upload.sh
  local testUser="user" testPassword="password" apiURL="http://localhost:8082/nexus/service/rest/v1" idList

idList=$(cat <<-END
    1
    2
    3
END
)

  mock_set_output "${doguctl}" "${idList}" 1

  run deleteOldComponents "${testUser}" "${testPassword}"

  assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config --default default current_repository_component_ids"
  assert_equal "$(mock_get_call_num "${doguctl}")" "1"
  assert_line "Delete old uploaded component with ID: 1"
  assert_equal "$(mock_get_call_args "${curl}" "1")" "-s -u ${testUser}:${testPassword} -X DELETE ${apiURL}/components/1"
  assert_line "Delete old uploaded component with ID: 2"
  assert_equal "$(mock_get_call_args "${curl}" "2")" "-s -u ${testUser}:${testPassword} -X DELETE ${apiURL}/components/2"
  assert_line "Delete old uploaded component with ID: 3"
  assert_equal "$(mock_get_call_args "${curl}" "3")" "-s -u ${testUser}:${testPassword} -X DELETE ${apiURL}/components/3"
  assert_equal "$(mock_get_call_num "${curl}")" "3"
}

@test "deleteOldComponents should return if no ids are configured" {
  source /workspace/resources/component-upload.sh
  local testUser="user" testPassword="password"

  mock_set_output "${doguctl}" "default" 1

  run deleteOldComponents "${testUser}" "${testPassword}"

  assert_success
  assert_line "No old component ids available. Skip Deletion."
}

@test "createNewComponents should upload all configured components and save keys" {
  source /workspace/resources/component-upload.sh
  local testUser="user" testPassword="password" apiURL="http://localhost:8082/nexus/service/rest/v1" components entry entryWithoutRepo formEntries formEntriesList nexusIDs expectedNexusIDs

  components="[{\"repository\": \"core\",\"raw.directory\": \"dir\",\"raw.asset1\": \"@/app/data/repository_component_uploads/test.html\",\"raw.asset1.filename\": \"test.html\",\"raw.asset2\": \"@/app/data/repository_component_uploads/test1.html\",\"raw.asset2.filename\": \"test1.html\"}]"
  entry="{\"repository\":\"core\",\"raw.directory\":\"dir\",\"raw.asset1\":\"@/app/data/repository_component_uploads/test.html\",\"raw.asset1.filename\":\"test.html\",\"raw.asset2\":\"@/app/data/repository_component_uploads/test1.html\",\"raw.asset2.filename\":\"test1.html\"}"
  entryWithoutRepo="{\"raw.directory\": \"dir\",\"raw.asset1\": \"@/app/data/repository_component_uploads/test.html\",\"raw.asset1.filename\": \"test.html\",\"raw.asset2\": \"@/app/data/repository_component_uploads/test1.html\",\"raw.asset2.filename\": \"test1.html\"}"
  formEntries=$(cat <<-END
[
  {
    "key": "raw.directory",
    "value": "dir"
  },
  {
    "key": "raw.asset1",
    "value": "@/app/data/repository_component_uploads/test.html"
  },
  {
    "key": "raw.asset1.filename",
    "value": "test.html"
  },
  {
    "key": "raw.asset2",
    "value": "@/app/data/repository_component_uploads/test1.html"
  },
  {
    "key": "raw.asset2.filename",
    "value": "test1.html"
  }
]
END
)

formEntriesList=$(cat <<-END
{"key":"raw.directory","value":"dir"}
{"key":"raw.asset1","value":"@/app/data/repository_component_uploads/test.html"}
{"key":"raw.asset1.filename","value":"test.html"}
{"key":"raw.asset2","value":"@/app/data/repository_component_uploads/test1.html"}
{"key":"raw.asset2.filename","value":"test1.html"}
END
)

nexusIDs=$(cat <<-END
abc
xyz
END
)
expectedNexusIDs=$'\n'"${nexusIDs}"

  mock_set_output "${doguctl}" "${components}" 1
  mock_set_output "${jq}" "${entry}" 1
  mock_set_output "${jq}" "core" 2
  mock_set_output "${jq}" "core" 3
  mock_set_output "${jq}" "${entryWithoutRepo}" 4
  mock_set_output "${jq}" "${formEntries}" 5
  mock_set_output "${jq}" "${formEntriesList}" 6

  mock_set_output "${jq}" "raw.directory" 7
  mock_set_output "${jq}" "dir" 8
  mock_set_output "${jq}" "raw.asset1" 9
  mock_set_output "${jq}" "@/app/data/repository_component_uploads/test.html" 10
  mock_set_output "${jq}" "raw.asset1.filename" 11
  mock_set_output "${jq}" "test.html" 12
  mock_set_output "${jq}" "raw.asset2" 13
  mock_set_output "${jq}" "@/app/data/repository_component_uploads/test1.html" 14
  mock_set_output "${jq}" "raw.asset2.filename" 15
  mock_set_output "${jq}" "test1.html" 16

  mock_set_output "${jq}" "${nexusIDs}" 17

  run createNewComponents "${testUser}" "${testPassword}"

  #assert_success
  assert_equal "$(mock_get_call_args "${doguctl}" "1")" "config --default default repository_component_uploads"
  assert_equal "$(mock_get_call_args "${jq}" "1")" "-c .[]"
  assert_equal "$(mock_get_call_args "${jq}" "2")" "-r .repository"
  assert_equal "$(mock_get_call_args "${jq}" "3")" "-r .repository"
  assert_equal "$(mock_get_call_args "${jq}" "4")" "del(.repository)"
  assert_equal "$(mock_get_call_args "${jq}" "5")" "to_entries"
  assert_equal "$(mock_get_call_args "${jq}" "6")" "-c .[]"

  assert_equal "$(mock_get_call_args "${jq}" "7")" "-r .key"
  assert_equal "$(mock_get_call_args "${jq}" "8")" "-r .value"
  assert_equal "$(mock_get_call_args "${jq}" "9")" "-r .key"
  assert_equal "$(mock_get_call_args "${jq}" "10")" "-r .value"
  assert_equal "$(mock_get_call_args "${jq}" "11")" "-r .key"
  assert_equal "$(mock_get_call_args "${jq}" "12")" "-r .value"
  assert_equal "$(mock_get_call_args "${jq}" "13")" "-r .key"
  assert_equal "$(mock_get_call_args "${jq}" "14")" "-r .value"
  assert_equal "$(mock_get_call_args "${jq}" "15")" "-r .key"
  assert_equal "$(mock_get_call_args "${jq}" "16")" "-r .value"

  assert_line "Create component in repository core with params:"
  assert_line "[$entry]"
  assert_equal "$(mock_get_call_args "${curl}" "1")" "-s -u ${testUser}:${testPassword} -F raw.directory=dir -F raw.asset1=@/app/data/repository_component_uploads/test.html -F raw.asset1.filename=test.html -F raw.asset2=@/app/data/repository_component_uploads/test1.html -F raw.asset2.filename=test1.html -X POST ${apiURL}/components?repository=core"

  assert_line "Getting IDs for repository core"
  assert_equal "$(mock_get_call_args "${curl}" "2")" "-s -u ${testUser}:${testPassword} ${apiURL}/components?repository=core"
  assert_equal "$(mock_get_call_args "${jq}" "17")" "-r .items[] | select(.assets[]? | .uploader | contains(\"dogu-tool-admin\")) | .id"
  assert_equal "$(mock_get_call_args "${doguctl}" "2")" "config current_repository_component_ids ${expectedNexusIDs}"
}

@test "createNewComponents should return if no components are configured" {
  source /workspace/resources/component-upload.sh
  local testUser="user" testPassword="password"

  mock_set_output "${doguctl}" "default" 1

  run createNewComponents "${testUser}" "${testPassword}"

  assert_line "No repository component uploads defined. Skip upload."
}
