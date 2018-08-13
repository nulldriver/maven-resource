#!/bin/bash

set -eu
set -o pipefail

basedir="$(dirname "$0")"
. "$basedir/helpers.sh"

export MVN_REPO_URL=https://nexus.nulldriver.com/repository/maven-snapshots
export MVN_REPO_USERNAME=$(lpass show nexus.nulldriver.com/maven-resource-ci --username)
export MVN_REPO_PASSWORD=$(lpass show nexus.nulldriver.com/maven-resource-ci --password)

# 1.0.0-20170328.031519-19
readonly UNIQUE_SNAPSHOT_PATTERN="\-[0-9]{8}\.[0-9]{6}-[0-9]{1,}"

it_can_return_an_empty_list_if_no_versions_available() {

  json=$(get_a_snapshot_and_return_the_unique_version)
  assert_equals "[]" "$json"
}

it_can_put_a_resource_and_return_the_version() {

  json=$(put_a_snapshot_and_return_the_unique_version)
  assert_matches "$(echo $json | jq -r '.version.version')" "$UNIQUE_SNAPSHOT_PATTERN"
}

run it_can_return_an_empty_list_if_no_versions_available
run it_can_put_a_resource_and_return_the_version
